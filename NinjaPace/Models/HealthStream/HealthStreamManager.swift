//
//  HealthStreamManager.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/6/26.
//

import Combine
import CoreMotion
import Foundation
import HealthKit
import WatchConnectivity

@MainActor
final class HealthStreamManager: NSObject, ObservableObject {

    // MARK: - Published State
    @Published var miles: Double = 0
    @Published var steps: Int = 0
    @Published var heartRateBpm: Int = 0
    @Published var elapsedString: String = "00:00:00"
    @Published var isWorkoutRunning: Bool = false
    @Published var isWorkoutPaused: Bool = false
    @Published var paceString: String = "—"
    @Published var elapsedSecondsFromWatch: Int = 0
    @Published var pausedDuration: TimeInterval = 0
    @Published var activeCalories: Double = 0
    @Published var totalCalories: Double = 0
    @Published var peakSpeedMPH: Double = 0
    @Published var goalMiles: Double = 3.11 {
        didSet {
            UserDefaults.standard.set(goalMiles, forKey: Self.goalMilesKey)
        }
    }
    @Published var useScheduleDefault: Bool = false
    @Published var watchReachable: Bool = false
    @Published var watchTelemetryActive: Bool = false
    @Published var lastWatchTelemetryAt: Date?
    @Published var pushClient = StatsPushClient(defaultBaseURL: "")
    @Published var userAlert: HealthStreamAlert?
    @Published var themeKey: String = "ninja"
    @Published var hudConfiguration: HUDConfiguration = .default
    private let pedometer = CMPedometer()
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var watchTelemetryMonitorTask: Task<Void, Never>?
    private let watchTelemetryTimeout: TimeInterval = 6
    private let hudConfigurationKey = "hudConfiguration"
    private static let goalMilesKey = "HealthStreamManager.goalMiles"
    var workoutStartDate: Date?
    var publicWorkoutStartDate: Date? { workoutStartDate }
    private var elapsedTimer: Timer?
    private var wcSession: WCSession?
    private let useWatchAsSourceOfTruth = true
    let scheduleStore = GoalScheduleStore()
    private let defaults = UserDefaults.standard
    private var lastWatchElapsedSeconds: Int = 0
    private var mirroredWorkoutSession: HKWorkoutSession?
    private var watchTelemetryOrder = WatchTelemetryOrder()
    private var settingsSyncTask: Task<Void, Never>?

    // MARK: - Workout History
    var workoutHistoryStore: WorkoutHistoryStore?
    private var hasPersistedCurrentWorkout = false
    private var peakHeartRateBpm = 0
    private var heartRateSum: Double = 0
    private var heartRateSampleCount: Int = 0
    private var watchAverageHeartRate: Double?
    private var watchPeakHeartRate: Double?

    // Monotonic smoothing reference
    private var smoothReferenceElapsedAtLastTick: Int = 0
    private var smoothReferenceWallClockAtLastTick: Date = .distantPast
    private var elapsedAnchorMilliseconds: Int = 0
    private var elapsedAnchorDate: Date = .distantPast
    private var smoothTask: Task<Void, Never>?

    var progress: Double {
        guard goalMiles > 0 else { return 0 }
        return min(1.0, max(0.0, miles / goalMiles))
    }

    // MARK: - Magic state

    var isManualOverrideToday: Bool {
        defaults.string(forKey: GoalMagicKeys.lastManualGoalDay, default: "") == GoalMagicKeys.dayKey()
    }

    private var lastAppliedScheduleDay: String {
        get { defaults.string(forKey: GoalMagicKeys.lastAppliedScheduleDay, default: "") }
        set { defaults.set(newValue, forKey: GoalMagicKeys.lastAppliedScheduleDay) }
    }

    private func clearManualOverride() {
        defaults.set("", forKey: GoalMagicKeys.lastManualGoalDay)
    }

    override convenience init() {
        self.init(startWatchServices: true)
    }

    init(startWatchServices: Bool) {
        super.init()
        if UserDefaults.standard.object(forKey: Self.goalMilesKey) != nil {
            goalMiles = UserDefaults.standard.double(forKey: Self.goalMilesKey)
        }
        loadHUDConfiguration()
        guard startWatchServices else { return }
        store.workoutSessionMirroringStartHandler = { [weak self] mirroredSession in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.mirroredWorkoutSession = mirroredSession
                mirroredSession.delegate = self
            }
        }
        setupWatchConnectivity()
        startWatchTelemetryMonitor()
    }

    // MARK: - Permissions

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            userAlert = .healthUnavailable
            return
        }
        let hr = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let dist = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let step = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let workoutType = HKObjectType.workoutType()
        do {
            try await store.requestAuthorization(toShare: [workoutType], read: [hr, dist, step])
        } catch {
            userAlert = .healthAuthorizationFailed
        }
    }

    // MARK: - HUD Configuration

    private func loadHUDConfiguration() {
        guard
            let data = defaults.data(forKey: hudConfigurationKey),
            let configuration = try? JSONDecoder().decode(
                HUDConfiguration.self,
                from: data
            )
        else {
            hudConfiguration = .default
            return
        }
        hudConfiguration = configuration
    }

    func saveHUDConfiguration() {
        guard let data = try? JSONEncoder().encode(hudConfiguration) else { return }
        defaults.set(data, forKey: hudConfigurationKey)
    }

    // MARK: - Workout lifecycle (button actions)

    func startWorkout() async {
        hasPersistedCurrentWorkout = false
        peakHeartRateBpm = 0
        heartRateSum = 0
        heartRateSampleCount = 0
        watchAverageHeartRate = nil
        watchPeakHeartRate = nil
        // Reset live telemetry
        miles = 0
        steps = 0
        heartRateBpm = 0
        activeCalories = 0
        totalCalories = 0
        peakSpeedMPH = 0
        paceString = "—"
        isWorkoutPaused = false
        elapsedSecondsFromWatch = 0
        pausedDuration = 0
        elapsedString = "00:00:00.00"
        smoothReferenceElapsedAtLastTick = 0
        smoothReferenceWallClockAtLastTick = Date()
        workoutStartDate = Date()
        isWorkoutRunning = true
        lastWatchElapsedSeconds = 0
        startSmoothElapsedTaskIfNeeded()
        if !useWatchAsSourceOfTruth {
            startElapsedTimer()
        }
        if useWatchAsSourceOfTruth {
            elapsedSecondsFromWatch = 0
            elapsedString = "00:00:00.00"
            smoothReferenceElapsedAtLastTick = 0
            smoothReferenceWallClockAtLastTick = .distantPast
            sendCommandToWatch([
                "cmd": "start"
            ])
            return
        }
        await startPhoneWorkout()
    }

    func stopWorkout() async {
        if useWatchAsSourceOfTruth {
            // The Watch owns the workout session and will send the
            // authoritative final telemetry packet with running = false.
            sendCommandToWatch(["cmd": "stop"])
            return
        }
        // Phone-only fallback owns its own session, so it may finish locally.
        isWorkoutRunning = false
        isWorkoutPaused = false
        stopSmoothElapsedTask()
        stopElapsedTimer()
        await stopPhoneWorkout()
        persistCompletedWorkoutIfNeeded(source: "iPhone")
    }

    func scheduleSettingsSyncToWatch() {
        settingsSyncTask?.cancel()
        settingsSyncTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(150))
            } catch {
                return
            }
            guard let self else { return }
            self.syncCurrentSettingsToWatch()
        }
    }

    private func currentMacPayload() -> StatsPushClient.Payload {
        StatsPushClient.Payload(
            theme: themeKey,
            miles: miles,
            steps: steps,
            hr: heartRateBpm,
            elapsed: elapsedString,
            elapsedSeconds: elapsedSecondsFromWatch,
            elapsedMilliseconds: renderedElapsedMilliseconds,
            pace: paceString,
            activeCalories: activeCalories,
            totalCalories: totalCalories,
            goalMiles: goalMiles,
            progress: progress,
            running: isWorkoutRunning,
            paused: isWorkoutPaused,
            hudConfiguration: hudConfiguration
        )
    }

    // MARK: - Elapsed timer

    private func startElapsedTimer() {
        stopElapsedTimer()
        let start = self.workoutStartDate
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let start else { return }
            let s = Int(Date().timeIntervalSince(start))
            Task { @MainActor in
                self.elapsedString = Self.formatHMS(s)
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    private static func formatHMS(_ seconds: Int) -> String {
        let hour = seconds / 3600
        let min = (seconds % 3600) / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d:%02d", hour, min, sec)
    }

    private static func formatHMSHundredths(_ totalMilliseconds: Int) -> String {
        let totalSeconds = totalMilliseconds / 1000
        let hundredths = (totalMilliseconds % 1000) / 10  // 0..99
        let hour = totalSeconds / 3600
        let min = (totalSeconds % 3600) / 60
        let sec = totalSeconds % 60
        return String(format: "%02d:%02d:%02d.%02d", hour, min, sec, hundredths)
    }
    private var smoothElapsedMilliseconds: Int {
        let baseSeconds = max(
            lastWatchElapsedSeconds,
            smoothReferenceElapsedAtLastTick
        )
        let baseMilliseconds = baseSeconds * 1_000
        // Paused or stopped: preserve the final displayed value.
        guard isWorkoutRunning, !isWorkoutPaused else {
            return max(baseMilliseconds, elapsedAnchorMilliseconds)
        }
        guard smoothReferenceWallClockAtLastTick != .distantPast else {
            return baseMilliseconds
        }
        let elapsedSinceAnchor = max(0, Int(Date().timeIntervalSince(smoothReferenceWallClockAtLastTick) * 1_000))
        return baseMilliseconds + elapsedSinceAnchor
    }

    private func startSmoothElapsedTaskIfNeeded() {
        guard smoothTask == nil else { return }
        smoothTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let ms = self.smoothElapsedMilliseconds
                self.elapsedSecondsFromWatch = ms / 1000
                self.elapsedString = Self.formatHMSHundredths(ms)
                try? await Task.sleep(nanoseconds: 16_666_667)
            }
        }
    }

    private func stopSmoothElapsedTask() {
        smoothTask?.cancel()
        smoothTask = nil
    }

    var renderedElapsedMilliseconds: Int {
        if !isWorkoutRunning || isWorkoutPaused {
            return elapsedAnchorMilliseconds
        }
        guard elapsedAnchorDate != .distantPast else {
            return elapsedSecondsFromWatch * 1_000
        }
        let deltaMilliseconds = max(
            0,
            Int(
                Date().timeIntervalSince(
                    elapsedAnchorDate
                ) * 1_000
            )
        )
        return elapsedAnchorMilliseconds + deltaMilliseconds
    }

    private func markWatchTelemetryReceived() {
        lastWatchTelemetryAt = Date()
        watchTelemetryActive = true
    }

    func syncCurrentSettingsToWatch() {
        guard let session = wcSession else {
            return
        }
        let payload: [String: Any] = [
            "theme": themeKey.lowercased(),
            "goalMiles": goalMiles,
            "settingsUpdatedAt": Date().timeIntervalSince1970,
        ]
        /*
         Settings are latest-state data.
         Application context keeps only the newest
         value, which is exactly what we want.
         */
        try? session.updateApplicationContext(payload)
        /*
         Opportunistically deliver immediately
         when the Watch is reachable.
         Do NOT transferUserInfo on failure.
         The application context above already
         contains the newest settings.
         */
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        }
    }

    private func persistCompletedWorkoutIfNeeded(source: String) {
        guard !hasPersistedCurrentWorkout else { return }
        guard let workoutHistoryStore else {
            userAlert = .workoutSaveFailed
            return
        }
        guard miles > 0.001 || steps > 0 || elapsedSecondsFromWatch > 0 else { return }
        let endedAt = Date()
        let activeDuration = TimeInterval(max(elapsedSecondsFromWatch, 0))
        let pauseDuration = max(pausedDuration, 0)
        let totalDuration = activeDuration + pauseDuration
        let startedAt = workoutStartDate ?? endedAt.addingTimeInterval(-totalDuration)
        let averagePace: Double?
        let averageSpeed: Double?
        if miles > 0.001, activeDuration > 0 {
            averagePace = activeDuration / miles
            averageSpeed = miles / (activeDuration / 3_600)
        } else {
            averagePace = nil
            averageSpeed = nil
        }
        let record =
            WorkoutRecord(
                startedAt: startedAt,
                endedAt: endedAt,
                goalMiles: goalMiles,
                completedMiles: miles,
                steps: steps,
                averageHeartRate: watchAverageHeartRate ?? averageHeartRateForCurrentWorkout,
                peakHeartRate: watchPeakHeartRate ?? (peakHeartRateBpm > 0 ? Double(peakHeartRateBpm) : nil),
                activeCalories: activeCalories > 0 ? activeCalories : nil,
                totalCalories: totalCalories > 0 ? totalCalories : nil,
                duration: totalDuration,
                pausedDuration: pauseDuration,
                wasScheduledRestDay: goalMiles <= 0.001,
                averagePaceSecondsPerMile: averagePace,
                averageSpeedMPH: averageSpeed,
                peakSpeedMPH: peakSpeedMPH > 0 ? peakSpeedMPH : nil,
                workoutTypeRawValue: "running",
                source: source
            )
        do {
            _ = try workoutHistoryStore.saveWorkout(record)
            hasPersistedCurrentWorkout = true
        } catch {
            userAlert = .workoutSaveFailed
        }
    }

    // MARK: - Watch Telemetry

    func applyWatchTelemetry(_ payload: [String: Any]) {
        // WatchConnectivity, mirroring and application context can deliver the same snapshot.
        // Apply it only once, including heart-rate aggregation and Mac forwarding.
        guard watchTelemetryOrder.accept(sentAt: Self.doubleValue(from: payload["sentAt"])) else { return }
        let wasRunning = isWorkoutRunning
        let incomingRunning = payload["running"] as? Bool
        let incomingPaused = payload["paused"] as? Bool
        let incomingFinalized = payload["finalized"] as? Bool ?? false
        let incomingElapsedSeconds = Self.intValue(from: payload["elapsedSeconds"])
        let incomingPausedDuration = max(0, Self.doubleValue(from: payload["pausedDuration"]) ?? 0)
        // Detect a workout started independently on Apple Watch.
        if !wasRunning, incomingRunning == true {
            beginObservedWatchWorkoutIfNeeded(
                initialElapsedSeconds: incomingElapsedSeconds ?? 0, initialPausedDuration: incomingPausedDuration)
        }
        // Stats
        if let miles = payload["miles"] as? Double {
            self.miles = miles
        }
        if let steps = payload["steps"] as? Int {
            self.steps = steps
        }
        if let heartRate = payload["hr"] as? Int {
            self.heartRateBpm = heartRate
            if heartRate > 0 {
                peakHeartRateBpm = max(peakHeartRateBpm, heartRate)
                heartRateSum += Double(heartRate)
                heartRateSampleCount += 1
            }
        }
        if let averageHeartRate = Self.doubleValue(from: payload["averageHeartRate"]), averageHeartRate > 0 {
            watchAverageHeartRate = averageHeartRate
        }
        if let peakHeartRate = Self.doubleValue(from: payload["peakHeartRate"]), peakHeartRate > 0 {
            watchPeakHeartRate = peakHeartRate
            peakHeartRateBpm = max(peakHeartRateBpm, Int(peakHeartRate.rounded()))
        }
        if let activeCalories = Self.doubleValue(from: payload["activeCalories"]) {
            self.activeCalories = activeCalories
        }
        if let totalCalories = Self.doubleValue(from: payload["totalCalories"]) {
            self.totalCalories = totalCalories
        }
        if let peakSpeed = Self.doubleValue(from: payload["peakSpeedMPH"]), peakSpeed > 0 {
            peakSpeedMPH = max(peakSpeedMPH, peakSpeed)
        }
        if let pace = payload["pace"] as? String {
            self.paceString = pace
        }
        if !wasRunning, incomingRunning == true, let goal = Self.doubleValue(from: payload["goalMiles"]), goal > 0,
            abs(goalMiles - goal) > 0.0001
        {
            goalMiles = goal
        }
        // Elapsed Time
        if let elapsedSeconds = incomingElapsedSeconds {
            let now = Date()
            lastWatchElapsedSeconds = elapsedSeconds
            elapsedSecondsFromWatch = elapsedSeconds
            smoothReferenceElapsedAtLastTick = elapsedSeconds
            smoothReferenceWallClockAtLastTick = now
            elapsedAnchorMilliseconds = elapsedSeconds * 1_000
            elapsedAnchorDate = now
            elapsedString = Self.formatHMSHundredths(elapsedAnchorMilliseconds)
            if incomingRunning ?? isWorkoutRunning {
                startSmoothElapsedTaskIfNeeded()
            }
        }
        // Apply paused state
        if let incomingPaused { isWorkoutPaused = incomingPaused }
        pausedDuration = max(pausedDuration, incomingPausedDuration)
        // Apply running state
        if let incomingRunning { isWorkoutRunning = incomingRunning }
        // Stopping the live presentation must not wait for final calorie/history queries.
        if incomingRunning == false || incomingFinalized {
            freezeWatchWorkout()
        }
        // Authoritative completion
        if incomingFinalized {
            persistCompletedWorkoutIfNeeded(source: "Apple Watch")
        }
        pushCurrentStateToMac()
    }

    private func beginObservedWatchWorkoutIfNeeded(initialElapsedSeconds: Int, initialPausedDuration: TimeInterval) {
        // Phone-started workouts are already initialized by startWorkout().
        // Reaching this method means the Watch independently started a new workout.
        let now = Date()
        hasPersistedCurrentWorkout = false
        miles = 0
        steps = 0
        heartRateBpm = 0
        paceString = "—"
        activeCalories = 0
        totalCalories = 0
        peakSpeedMPH = 0
        peakHeartRateBpm = 0
        heartRateSum = 0
        heartRateSampleCount = 0
        watchAverageHeartRate = nil
        watchPeakHeartRate = nil
        pausedDuration = max(0, initialPausedDuration)
        lastWatchElapsedSeconds = initialElapsedSeconds
        elapsedSecondsFromWatch = initialElapsedSeconds
        smoothReferenceElapsedAtLastTick = initialElapsedSeconds
        smoothReferenceWallClockAtLastTick = now
        elapsedAnchorMilliseconds = initialElapsedSeconds * 1_000
        elapsedAnchorDate = now
        elapsedString = Self.formatHMSHundredths(elapsedAnchorMilliseconds)
        let totalElapsed = TimeInterval(initialElapsedSeconds) + pausedDuration
        workoutStartDate = now.addingTimeInterval(-totalElapsed)
    }

    private func freezeWatchWorkout() {
        stopSmoothElapsedTask()
        stopElapsedTimer()
        isWorkoutRunning = false
        isWorkoutPaused = false
        watchTelemetryActive = false
        let finalMilliseconds = max(elapsedSecondsFromWatch, lastWatchElapsedSeconds) * 1_000
        elapsedAnchorMilliseconds = finalMilliseconds
        elapsedAnchorDate = Date()
        elapsedSecondsFromWatch = finalMilliseconds / 1_000
        elapsedString = Self.formatHMSHundredths(finalMilliseconds)
        smoothReferenceElapsedAtLastTick = elapsedSecondsFromWatch
        smoothReferenceWallClockAtLastTick = .distantPast
    }

    func applyMirroredWatchWorkoutEnd(at date: Date) {
        // The end event can arrive before the final telemetry. Reject older running
        // packets so a buffered tick cannot restart the timer or warrior animation.
        guard watchTelemetryOrder.accept(sentAt: date.timeIntervalSince1970) else { return }
        freezeWatchWorkout()
        pushCurrentStateToMac()
    }

    private var averageHeartRateForCurrentWorkout: Double? {
        guard heartRateSampleCount > 0 else { return nil }
        return heartRateSum / Double(heartRateSampleCount)
    }

    // MARK: - Helpers

    private static func doubleValue(from value: Any?) -> Double? {
        switch value {
        case let value as Double:
            return value
        case let value as NSNumber:
            return value.doubleValue
        case let value as String:
            return Double(value)
        default:
            return nil
        }
    }

    private static func intValue(from value: Any?) -> Int? {
        switch value {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }
}

// MARK: - WatchConnectivity (iPhone receives live stats)

extension HealthStreamManager: WCSessionDelegate {

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        self.wcSession = session
    }

    private func startWatchTelemetryMonitor() {
        watchTelemetryMonitorTask?.cancel()
        watchTelemetryMonitorTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                if let lastUpdate = self.lastWatchTelemetryAt {
                    let age = Date().timeIntervalSince(lastUpdate)
                    self.watchTelemetryActive = self.isWorkoutRunning && age < self.watchTelemetryTimeout
                } else {
                    self.watchTelemetryActive = false
                }
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }
        }
    }

    private func sendCommandToWatch(_ message: [String: Any]) {
        guard let session = wcSession else { return }
        // Deliver immediately when reachable; fall back to background delivery on failure.
        if session.isReachable {
                session.sendMessage(message, replyHandler: { [weak self] reply in
                        Task { @MainActor in
                            guard let self else { return }
                            self.markWatchTelemetryReceived()
                            self.applyWatchTelemetry(reply)
                        }
                    },
                    errorHandler: { error in
                        // Preserve queued fallback.
                        session.transferUserInfo(message)
                    }
                )
            } else {
                // Watch will handle this through didReceiveUserInfo.
                session.transferUserInfo(message)
            }
        }

    func requestCurrentWatchState() {
        sendCommandToWatch(["cmd": "snapshot"])
    }
    
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.watchReachable = session.isReachable
            if error != nil { self.userAlert = .watchConnectionFailed }
            if activationState == .activated {
                self.requestCurrentWatchState()
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.watchReachable = session.isReachable
            if session.isReachable { self.requestCurrentWatchState() }
        }
    }
    
    // Receive live stats from watch
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.markWatchTelemetryReceived()
            self.applyWatchTelemetry(message)
        }
    }
    
    // Acknowledge processing promptly. This confirms iPhone receipt, not Mac delivery.
    // Keep the no-reply overload above for older Watch builds.
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                             replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.markWatchTelemetryReceived()
            self.applyWatchTelemetry(message)
            replyHandler(["received": true])
        }
    }

    // Compatibility path for queued messages; live telemetry uses didReceiveMessage.
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            self.markWatchTelemetryReceived()
            self.applyWatchTelemetry(userInfo)
        }
    }
    
    // Required to conform to WCSessionDelegate on each platform
    #if os(iOS)
        nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
            // No-op on iOS
        }
        nonisolated func sessionDidDeactivate(_ session: WCSession) {
            // No-op on iOS
        }
    #elseif os(watchOS)
        nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
            // Handle transition between paired watches if needed
        }
        nonisolated func sessionDidDeactivate(_ session: WCSession) {
            // After deactivation, activate the new session
            WCSession.default.activate()
        }
    #endif
    
    // Keep reachability in sync when watch state changes
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.watchReachable = session.isReachable
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.markWatchTelemetryReceived()
            self.applyWatchTelemetry(applicationContext)
        }
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didReceiveDataFromRemoteWorkoutSession data: [Data]) {
        for packet in data {
            do {
                let object = try JSONSerialization.jsonObject(with: packet)
                guard let payload = object as? [String: Any] else {
                    continue
                }
                Task { @MainActor in
                    self.markWatchTelemetryReceived()
                    self.applyWatchTelemetry(payload)
                }
            } catch {
                continue
            }
        }
    }
}

// MARK: - Phone-only fallback

extension HealthStreamManager {

    func startPhoneWorkout() async {
        guard session == nil else { return }
        // Phone pedometer only works when the iPhone itself moves.
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .indoor
        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            session.delegate = self
            builder.delegate = self
            // Start pedometer for steps and distance when the iPhone moves.
            if let start = workoutStartDate {
                startPedometer(from: start)
            }
            session.startActivity(with: workoutStartDate ?? Date())
            try await builder.beginCollection(at: workoutStartDate ?? Date())
            // Initialize smoothing in phone-only mode.
            self.smoothReferenceElapsedAtLastTick = 0
            self.smoothReferenceWallClockAtLastTick = Date()
            self.startSmoothElapsedTaskIfNeeded()
            self.session = session
            self.builder = builder
        } catch {
            session = nil
            builder = nil
            isWorkoutRunning = false
            isWorkoutPaused = false
            stopSmoothElapsedTask()
            stopElapsedTimer()
            userAlert = .workoutStartFailed
        }
    }

    func stopPhoneWorkout() async {
        stopPedometer()
        guard let session, let builder else {
            self.session = nil
            self.builder = nil
            return
        }
        session.end()
        do {
            try await builder.endCollection(at: Date())
            _ = try await builder.finishWorkout()
        } catch {
            userAlert = .workoutStopFailed
        }
        self.session = nil
        self.builder = nil
        self.smoothReferenceElapsedAtLastTick = 0
        self.smoothReferenceWallClockAtLastTick = .distantPast
    }

    func startPedometer(from start: Date) {
        guard CMPedometer.isStepCountingAvailable() || CMPedometer.isDistanceAvailable() else { return }
        pedometer.startUpdates(from: start) { [weak self] data, error in
            guard let self else { return }
            if error != nil { return }
            guard let data else { return }
            Task { @MainActor in
                self.steps = data.numberOfSteps.intValue
                if let meters = data.distance?.doubleValue {
                    self.miles = meters / 1609.344
                }
            }
        }
    }

    func stopPedometer() {
        pedometer.stopUpdates()
    }

    func startPushingToMac(macBaseURL: String) {
        let address = macBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty else {
            pushClient.stopPushing()
            return
        }
        pushClient.macBaseURL = address
        pushClient.startPushing { [weak self] in
            guard let self else {
                return StatsPushClient.Payload(
                    theme: "ninja",
                    miles: 0,
                    steps: 0,
                    hr: 0,
                    elapsed: "00:00:00",
                    elapsedSeconds: 0,
                    elapsedMilliseconds: 0,
                    pace: "—",
                    activeCalories: 0,
                    totalCalories: 0,
                    goalMiles: 0,
                    progress: 0,
                    running: false,
                    paused: false,
                    hudConfiguration: nil
                )
            }
            return self.currentMacPayload()
        }
    }

    func stopPushingToMac() {
        pushClient.stopPushing()
    }

    func pushCurrentStateToMac() {
        guard pushClient.enabled else { return }
        let payload = currentMacPayload()
        Task {
            await pushClient.pushNow(payload)
        }
    }
}

// MARK: - HK delegates

extension HealthStreamManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        guard toState == .ended || toState == .stopped else { return }
        Task { @MainActor in
            guard workoutSession === self.mirroredWorkoutSession else { return }
            self.applyMirroredWatchWorkoutEnd(at: date)
        }
    }
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}

extension HealthStreamManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // Only relevant in phone-only mode.
        if let hrType = HKObjectType.quantityType(forIdentifier: .heartRate),
            collectedTypes.contains(hrType),
            let hr = workoutBuilder.statistics(for: hrType)?.mostRecentQuantity()
        {
            let bpm = hr.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            Task { @MainActor in
                let roundedBPM = Int(bpm.rounded())
                self.heartRateBpm = roundedBPM
                if roundedBPM > 0 {
                    self.peakHeartRateBpm = max(self.peakHeartRateBpm, roundedBPM)
                    self.heartRateSum += Double(roundedBPM)
                    self.heartRateSampleCount += 1
                }
            }
        }
    }
}

extension HealthStreamManager {

    func bootstrapGoalForTodayIfNeeded() {
        // Sync toggle from the schedule store.
        useScheduleDefault = scheduleStore.schedule.useScheduleDefaults
        guard useScheduleDefault else { return }
        let today = GoalMagicKeys.dayKey()
        // If user manually picked something today, respect it.
        if isManualOverrideToday {
            syncCurrentSettingsToWatch()
            return
        }
        // Apply the schedule once per day.
        if lastAppliedScheduleDay != today {
            applyScheduleDefaultForToday(markApplied: true)
        }
        syncCurrentSettingsToWatch()
    }

    func applyScheduleDefaultForToday(markApplied: Bool = false) {
        let weekday = Calendar.current.component(.weekday, from: Date())
        let miles = scheduleStore.schedule.miles(for: weekday)
        
        goalMiles = max(0, miles)
        
        if markApplied {
            lastAppliedScheduleDay = GoalMagicKeys.dayKey()
            clearManualOverride()
        }
        
        syncCurrentSettingsToWatch()
        pushCurrentStateToMac()
    }

    func setUseScheduleDefault(_ on: Bool) {
        useScheduleDefault = on
        scheduleStore.schedule.useScheduleDefaults = on
        if on {
            applyScheduleDefaultForToday(markApplied: true)
        }
        syncCurrentSettingsToWatch()
        pushCurrentStateToMac()
    }

    func userManuallySetGoalToday() {
        // Don’t treat schedule auto-apply as manual.
        defaults.set(GoalMagicKeys.dayKey(), forKey: GoalMagicKeys.lastManualGoalDay)
    }
}

extension HealthStreamManager {
    /// Builds the next reminder window from NinjaPace's existing goal rules.
    ///
    /// - Today always uses the already-resolved `goalMiles`, so a same-day
    ///   manual override is respected.
    /// - Future dates use the weekly schedule when schedule defaults are on.
    /// - Otherwise the current goal is used as the future daily target.
    /// - `0.00 mi` rest days are omitted entirely.
    func goalReminderPlans(
        horizonDays: Int = 14,
        from now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [GoalReminderDayPlan] {
        guard horizonDays > 0 else { return [] }

        let start = calendar.startOfDay(for: now)

        return (0..<horizonDays).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }

            let goal: Double

            if calendar.isDate(date, inSameDayAs: now) {
                // This includes today's schedule result or today's manual override.
                goal = max(0, goalMiles)
            } else if scheduleStore.schedule.useScheduleDefaults {
                let weekday = calendar.component(.weekday, from: date)
                goal = max(0, scheduleStore.schedule.miles(for: weekday))
            } else {
                goal = max(0, goalMiles)
            }

            guard goal > 0.001 else {
                // A zero-mile target is an intentional rest day.
                return nil
            }

            return GoalReminderDayPlan(date: date, goalMiles: goal)
        }
    }

    /// Refreshes pending reminders without ever prompting for authorization.
    /// Permission is requested only from GoalNudgesSettingsView when the user
    /// explicitly turns Goal Nudges on.
    func refreshGoalNudges() {
        let plans = goalReminderPlans()

        Task {
            await GoalReminderManager.shared.refreshSchedule(plans: plans)
        }
    }

    /// Call only after a WorkoutRecord has been successfully persisted.
    func handleGoalNudgeAfterSaving(_ record: WorkoutRecord) {
        guard record.wasGoalCompleted else { return }

        Task {
            await GoalReminderManager.shared.markGoalCompletedAndCancelReminder(
                for: record.startedAt
            )
        }
    }
}

#if DEBUG

@MainActor
extension HealthStreamManager {
    func configureUITestState(_ state: String) {
        pushClient.stopPushing()
        pushClient.macBaseURL = ""
        userAlert = nil
        themeKey = "ninja"
        hudConfiguration = .default
        useScheduleDefault = false
        watchReachable = false
        watchTelemetryActive = false
        lastWatchTelemetryAt = nil
        isWorkoutPaused = false
        pausedDuration = 0
        peakSpeedMPH = 0

        switch state {
        case "live":
            miles = 3.14
            steps = 6_240
            heartRateBpm = 142
            elapsedString = "00:28:10.00"
            elapsedSecondsFromWatch = 1_690
            activeCalories = 418
            totalCalories = 518
            paceString = "8:58"
            goalMiles = 5
            isWorkoutRunning = true
            watchReachable = true
            watchTelemetryActive = true

        default:
            miles = 0
            steps = 0
            heartRateBpm = 0
            elapsedString = "00:00:00.00"
            elapsedSecondsFromWatch = 0
            activeCalories = 0
            totalCalories = 0
            paceString = "—"
            goalMiles = 3.11
            isWorkoutRunning = false
        }
    }
}

#endif
