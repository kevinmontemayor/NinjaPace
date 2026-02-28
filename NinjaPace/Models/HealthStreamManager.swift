//
//  HealthStreamManager.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/6/26.
//

import Foundation
import HealthKit
import Combine
import CoreMotion
import SwiftUI
import WatchConnectivity

@MainActor
final class HealthStreamManager: NSObject, ObservableObject {

    // Published stats
    @Published var miles: Double = 0
    @Published var steps: Int = 0
    @Published var heartRateBpm: Int = 0
    @Published var elapsedString: String = "00:00:00"
    @Published var isWorkoutRunning: Bool = false
    @Published var isWorkoutPaused: Bool = false
    @Published var paceString: String = "—"
    @Published var elapsedSecondsFromWatch: Int = 0
    @Published var activeCalories: Double = 0
    @Published var totalCalories: Double = 0
    @Published var goalMiles: Double = 3.11
    @Published var useScheduleDefault: Bool = false
    @Published var watchReachable: Bool = false
    @Published var pushClient = StatsPushClient(defaultBaseURL: "")
    @Published var themeKey: String = "ninja"
    
    private let pedometer = CMPedometer()
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    private var workoutStartDate: Date?
    private var elapsedTimer: Timer?
    
    private var wcSession: WCSession? = nil
    private let useWatchAsSourceOfTruth = true
    let scheduleStore = GoalScheduleStore()
    private let defaults = UserDefaults.standard
    
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

    private func markManualOverrideToday() {
        defaults.set(GoalMagicKeys.dayKey(), forKey: GoalMagicKeys.lastManualGoalDay)
    }

    private func clearManualOverride() {
        defaults.set("", forKey: GoalMagicKeys.lastManualGoalDay)
    }
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }

    // MARK: - Permissions
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        // If you use watch as source, iPhone HK auth is mostly optional,
        // but keep it so you can expand later without rework.
        let hr = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let dist = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let step = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let workoutType = HKObjectType.workoutType()

        do {
            try await store.requestAuthorization(toShare: [workoutType], read: [hr, dist, step])
        } catch {
            print("HealthKit auth error:", error)
        }
    }

    // MARK: - Workout lifecycle (button actions)
    func startWorkout() async {
        // Reset displayed stats
        miles = 0
        steps = 0
        heartRateBpm = 0
        isWorkoutPaused = false

        workoutStartDate = Date()
        isWorkoutRunning = true
        startElapsedTimer()

        if useWatchAsSourceOfTruth {
            workoutStartDate = nil
            isWorkoutRunning = true
            sendCommandToWatch(["cmd": "start"])
            return
        }

        // Phone-only fallback
        await startPhoneWorkout()
    }

    func stopWorkout() async {
        isWorkoutRunning = false
        isWorkoutPaused = false
        stopElapsedTimer()

        if useWatchAsSourceOfTruth {
            sendCommandToWatch(["cmd": "stop"])
            return
        }

        await stopPhoneWorkout()
    }

    // MARK: - Elapsed timer (unchanged)
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
    
    func syncToWatch(themeKey: String, goalMiles: Double) {
        guard let session = wcSession else { return }

        let payload: [String: Any] = [
            "theme": themeKey.lowercased(),
            "goalMiles": goalMiles
        ]
        
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: { err in
                print("syncToWatch sendMessage error:", err)
            })
        }
        
        do {
            try session.updateApplicationContext(payload)
        } catch {
            session.transferUserInfo(payload)
        }
    }
}

// MARK: - WatchConnectivity (iPhone receives live stats)
extension HealthStreamManager: WCSessionDelegate {

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("WCSession not supported on this device.")
            return
        }
        let s = WCSession.default
        s.delegate = self
        s.activate()
        self.wcSession = s
    }

    private func sendCommandToWatch(_ message: [String: Any]) {
        guard let s = wcSession else { return }
        // isReachable requires the watch app to be in the foreground
        // If you want background delivery later: switch to transferUserInfo.
        if s.isReachable {
            s.sendMessage(message, replyHandler: nil) { err in
                print("sendMessage error:", err)
            }
        } else {
            // Background-safe fallback: deliver eventually
            s.transferUserInfo(message)
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error { print("WC activate error:", error) }
        Task { @MainActor in
            self.watchReachable = session.isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.watchReachable = session.isReachable
        }
    }

    // Receive live stats from watch
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            // Watch will send these keys
            if let miles = message["miles"] as? Double { self.miles = miles }
            if let steps = message["steps"] as? Int { self.steps = steps }
            if let hr = message["hr"] as? Int { self.heartRateBpm = hr }
            if let active = message["activeCalories"] as? Double { self.activeCalories = active }
            if let total  = message["totalCalories"] as? Double  { self.totalCalories  = total }
            if let pace = message["pace"] as? String { self.paceString = pace }
            if let elapsedSeconds = message["elapsedSeconds"] as? Int {
                self.elapsedSecondsFromWatch = elapsedSeconds
                self.elapsedString = Self.formatHMS(elapsedSeconds)
            }
            if let running = message["running"] as? Bool { self.isWorkoutRunning = running }
            if let paused = message["paused"] as? Bool { self.isWorkoutPaused = paused }
            print("📥 watch stats:", self.miles, self.steps, self.heartRateBpm)
        }
    }

    // If you use transferUserInfo on the watch side
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            if let miles = userInfo["miles"] as? Double { self.miles = miles }
            if let steps = userInfo["steps"] as? Int { self.steps = steps }
            if let hr = userInfo["hr"] as? Int { self.heartRateBpm = hr }
            if let active = userInfo["activeCalories"] as? Double { self.activeCalories = active }
            if let total = userInfo["totalCalories"] as? Double  { self.totalCalories  = total }
            if let pace = userInfo["pace"] as? String { self.paceString = pace }
            if let elapsedSeconds = userInfo["elapsedSeconds"] as? Int {
                self.elapsedSecondsFromWatch = elapsedSeconds
                self.elapsedString = Self.formatHMS(elapsedSeconds)
            }
            if let running = userInfo["running"] as? Bool { self.isWorkoutRunning = running }
            if let paused = userInfo["paused"] as? Bool { self.isWorkoutPaused = paused }
            if let goal = userInfo["goalMiles"] as? Double { self.goalMiles = goal }
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
    
    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            if let miles = applicationContext["miles"] as? Double { self.miles = miles }
            if let steps = applicationContext["steps"] as? Int { self.steps = steps }
            if let hr = applicationContext["hr"] as? Int { self.heartRateBpm = hr }
            if let active = applicationContext["activeCalories"] as? Double { self.activeCalories = active }
            if let total  = applicationContext["totalCalories"] as? Double  { self.totalCalories  = total }
            if let pace = applicationContext["pace"] as? String { self.paceString = pace }
            if let elapsedSeconds = applicationContext["elapsedSeconds"] as? Int {
                self.elapsedSecondsFromWatch = elapsedSeconds
                self.elapsedString = Self.formatHMS(elapsedSeconds)
            }
            if let running = applicationContext["running"] as? Bool { self.isWorkoutRunning = running }
            if let paused = applicationContext["paused"] as? Bool { self.isWorkoutPaused = paused }
        }
    }
}

// MARK: - Phone-only fallback
internal extension HealthStreamManager {

    func startPhoneWorkout() async {
        guard session == nil else { return }

        // Important: phone pedometer only works if phone moves.
        // If your phone sits on the treadmill, this will remain 0.
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: store, configuration: config)
            let builder = session.associatedWorkoutBuilder()

            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            session.delegate = self
            builder.delegate = self

            // Start pedometer for steps+distance if phone moves
            if let start = workoutStartDate {
                startPedometer(from: start)
            }

            session.startActivity(with: workoutStartDate ?? Date())
            try await builder.beginCollection(at: workoutStartDate ?? Date())

            self.session = session
            self.builder = builder

        } catch {
            print("Start phone workout failed:", error)
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
            try await builder.finishWorkout()
        } catch {
            print("Stop phone workout failed:", error)
        }

        self.session = nil
        self.builder = nil
    }

    func startPedometer(from start: Date) {
        guard CMPedometer.isStepCountingAvailable() || CMPedometer.isDistanceAvailable() else {
            print("Pedometer not available on this device")
            return
        }

        pedometer.startUpdates(from: start) { [weak self] data, error in
            guard let self else { return }
            if let error {
                print("Pedometer error:", error)
                return
            }
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
        pushClient.macBaseURL = macBaseURL
        pushClient.startPushing { [weak self] in
            guard let self else {
                return StatsPushClient.Payload(
                    theme: "ninja",
                    miles: 0,
                    steps: 0,
                    hr: 0,
                    elapsed: "00:00:00",
                    elapsedSeconds: 0,
                    pace: "—",
                    activeCalories: 0,
                    totalCalories: 0,
                    goalMiles: 0,
                    progress: 0,
                    running: false,
                    paused: false
                )
            }

            return StatsPushClient.Payload(
                theme: self.themeKey,
                miles: self.miles,
                steps: self.steps,
                hr: self.heartRateBpm,
                elapsed: self.elapsedString,
                elapsedSeconds: self.elapsedSecondsFromWatch,
                pace: self.paceString,
                activeCalories: self.activeCalories,
                totalCalories: self.totalCalories,
                goalMiles: self.goalMiles,
                progress: self.progress,
                running: self.isWorkoutRunning,
                paused: self.isWorkoutPaused
            )
        }
    }

    func stopPushingToMac() {
        pushClient.stopPushing()
    }
}

// MARK: - HK delegates (kept for phone fallback)
extension HealthStreamManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState, date: Date) { }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session error:", error)
    }
}

extension HealthStreamManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // Only relevant in phone-only mode; can leave this as-is.
        if let hrType = HKObjectType.quantityType(forIdentifier: .heartRate),
           collectedTypes.contains(hrType),
           let hr = workoutBuilder.statistics(for: hrType)?.mostRecentQuantity() {
            let bpm = hr.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            Task { @MainActor in
                self.heartRateBpm = Int(bpm.rounded())
            }
        }
    }
}

extension HealthStreamManager {

    func bootstrapGoalForTodayIfNeeded() {
        // Sync toggle from schedule store
        useScheduleDefault = scheduleStore.schedule.useScheduleDefaults

        guard useScheduleDefault else { return }

        let today = GoalMagicKeys.dayKey()

        // If user manually picked something today, respect it.
        if isManualOverrideToday {
            return
        }

        // Apply schedule once per day (prevents re-applying every app open)
        if lastAppliedScheduleDay != today {
            applyScheduleDefaultForToday(markApplied: true)
        }
    }
    
    func applyScheduleDefaultForToday(markApplied: Bool = false) {
        let weekday = Calendar.current.component(.weekday, from: Date()) // 1..7
        let miles = scheduleStore.schedule.miles(for: weekday)
        goalMiles = max(0, miles)

        if markApplied {
            lastAppliedScheduleDay = GoalMagicKeys.dayKey()
            clearManualOverride() // schedule becomes “the truth” again
        }
    }
    
    func setUseScheduleDefault(_ on: Bool) {
        useScheduleDefault = on
        scheduleStore.schedule.useScheduleDefaults = on

        if on {
            applyScheduleDefaultForToday(markApplied: true)
        }
    }
    
    func userManuallySetGoalToday() {
        // Don’t treat *schedule auto-apply* as manual.
        let today = GoalMagicKeys.dayKey()
        defaults.set(today, forKey: GoalMagicKeys.lastManualGoalDay)
    }
}
