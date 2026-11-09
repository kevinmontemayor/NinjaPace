//
//  WatchWorkoutManager.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 2/7/26.
//
import Combine
import Foundation
import HealthKit
import SwiftUI
import WatchConnectivity
import WatchKit

@MainActor
final class WatchWorkoutManager: NSObject, ObservableObject {
    @AppStorage("selectedTheme") private var storedThemeKey: String = "ninja"
    @AppStorage("goalMiles") private var storedGoalMiles: Double = 3.11
    @AppStorage("lastAppliedSettingsUpdatedAt") private var lastAppliedSettingsUpdatedAt: Double = 0
    @Published var miles: Double = 0
    @Published var steps: Int = 0
    @Published var hr: Int = 0
    @Published var averageHeartRate: Double = 0
    @Published var peakHeartRate: Double = 0
    @Published var running: Bool = false
    @Published var paused: Bool = false
    @Published var elapsedSeconds: Int = 0
    @Published var elapsedMilliseconds: Int = 0
    @Published var activeCalories: Double = 0
    @Published var totalCalories: Double = 0
    @Published var peakSpeedMPH: Double = 0
    @Published var themeKey: String = "ninja" { didSet { storedThemeKey = themeKey } }
    @Published var goalMiles: Double = 3.11 { didSet { storedGoalMiles = goalMiles } }
    @Published var userAlert: WatchWorkoutAlert?
    var progress: Double {
        guard goalMiles > 0 else { return 0 }
        return min(max(miles / goalMiles, 0), 1)
    }
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var workoutStartDate: Date?
    private var elapsedTimer: Timer?
    private var telemetryTask: Task<Void, Never>?
    private var lastDingMile: Int = 0
    private var lastSpeedMiles: Double?
    private var lastSpeedSampleDate: Date?
    private var accumulatedPausedDuration: TimeInterval = 0
    private var pauseStartedAt: Date?
    private var isMirroringStarting = false
    private var isMirroringActive = false
    private var workoutFinalized = false
    
    var elapsedText: String {
        let hours = elapsedSeconds / 3_600
        let minutes = (elapsedSeconds % 3_600) / 60
        let seconds = elapsedSeconds % 60
        
        return String(
            format: "%02d:%02d:%02d",
            hours,
            minutes,
            seconds
        )
    }
    
    var paceString: String {
        guard miles >= 0.01, elapsedSeconds > 0 else { return "—" }
        let secPerMile = Double(elapsedSeconds) / miles
        let mile = Int(secPerMile) / 60
        let sec = Int(secPerMile) % 60
        return String(format: "%d:%02d", mile, sec)
    }
    
    func activate() {
        // Fast local fallback while waiting for iPhone synchronization.
        themeKey = storedThemeKey
        goalMiles = storedGoalMiles
        setupWC()
        requestAuth()
        // If WCSession was already activated before this manager appeared, apply the most recently received settings immediately.
        let session = WCSession.default
        if session.activationState == .activated { applyPhoneSettings(session.receivedApplicationContext) }
    }
    
    private func setupWC() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        if session.activationState != .activated { session.activate() }
    }
    
    private func requestAuth() {
        guard HKHealthStore.isHealthDataAvailable() else {
            presentAlert(.healthUnavailable)
            return
        }
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let distType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let basalEnergy = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
        let manager = self
        store.requestAuthorization(
            toShare: [HKObjectType.workoutType()], read: [hrType, distType, stepType, activeEnergy, basalEnergy]
        ) { success, error in
            guard !success || error != nil else { return }
            Task { @MainActor in manager.presentAlert(.healthAuthorizationFailed) }
        }
    }
    
    // MARK: - UI actions
    func toggleStartPause() { if !running { start() } else { paused ? resume() : pause() } }
    
    func start() {
        guard session == nil else { return }
        resetWorkoutStateForStart()
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .indoor
        do {
            let healthStoreSession = try HKWorkoutSession(healthStore: store, configuration: config)
            let healthStoreBuilder = healthStoreSession.associatedWorkoutBuilder()
            healthStoreBuilder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            healthStoreSession.delegate = self
            healthStoreBuilder.delegate = self
            session = healthStoreSession
            builder = healthStoreBuilder
            running = true
            paused = false
            startElapsedTimer()
            let startDate = Date()
            workoutStartDate = startDate
            healthStoreSession.startActivity(with: startDate)
            startTelemetryLoopIfNeeded()
            let manager = self
            healthStoreBuilder.beginCollection(withStart: startDate) { success, _ in
                Task { @MainActor in
                    guard success else {
                        manager.handleWorkoutStartFailure()
                        return
                    }
                    manager.startTelemetryLoopIfNeeded()
                    manager.send()
                }
            }
        } catch { handleWorkoutStartFailure() }
    }
    
    func pause() {
        guard running, !paused else { return }
        beginPauseTrackingIfNeeded()
        paused = true
        lastSpeedMiles = nil
        lastSpeedSampleDate = nil
        session?.pause()
        stopElapsedTimer()
        startTelemetryLoopIfNeeded()
        send()
    }
    
    func resume() {
        guard running, paused else { return }
        endPauseTrackingIfNeeded()
        paused = false
        lastSpeedMiles = nil
        lastSpeedSampleDate = nil
        session?.resume()
        startElapsedTimer()
        startTelemetryLoopIfNeeded()
        send()
    }
    
    func stop() {
        guard running else { return }
        lastDingMile = 0
        stopElapsedTimer()
        let endDate = Date()
        endPauseTrackingIfNeeded(at: endDate)
        paused = false
        running = false
        // Publish Stop before ending the mirrored session or waiting for HealthKit queries.
        send()
        stopTelemetryLoop()
        let startDate = workoutStartDate
        let localSession = session
        let localBuilder = builder
        localSession?.end()
        guard let localBuilder else {
            send()
            clearWorkoutSessionState()
            return
        }
        localBuilder.endCollection(withEnd: endDate) { [weak self] success, _ in
            guard let manager = self else { return }
            guard success else {
                Task { @MainActor [manager] in
                    manager.send()
                    manager.clearWorkoutSessionState()
                    manager.presentAlert(.workoutFinishFailed)
                }
                return
            }
            localBuilder.finishWorkout { [weak manager] _, error in
                guard let manager else { return }
                Task { @MainActor [manager] in
                    if error != nil { manager.presentAlert(.workoutFinishFailed) }
                    // Preserve whatever final metrics HealthKit was able to produce.
                    manager.finalizeWorkoutMetrics(builder: localBuilder, startDate: startDate, endDate: endDate)
                }
            }
        }
    }
    
    private func finalizeWorkoutMetrics(builder: HKLiveWorkoutBuilder, startDate: Date?, endDate: Date) {
        captureFinalHeartRateStatistics(from: builder)
        captureFinalActiveCalories(from: builder)
        guard let startDate else {
            totalCalories = activeCalories
            finishFinalTelemetry()
            return
        }
        calculateTotalCalories(startDate: startDate, endDate: endDate) { [weak self] total in
            guard let self else { return }
            self.totalCalories = total
            self.finishFinalTelemetry()
        }
    }
    
    private func finishFinalTelemetry() {
        workoutFinalized = true
        send()
        clearWorkoutSessionState()
    }
    
    // MARK: - Sending
    private func send() {
        let payload = currentTelemetryPayload()

        checkpointLatestState(payload)
        sendViaWatchConnectivity(payload)
        sendViaWorkoutMirror(payload)
    }
    
    private func startElapsedTimer() {
        stopElapsedTimer()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.running, !self.paused else { return }
                self.elapsedSeconds += 1
                self.elapsedMilliseconds = self.elapsedSeconds * 1_000
            }
        }
    }
    
    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }
    
    private func checkForMileDing() {
        guard running, !paused else { return }
        let currentWhole = Int(floor(miles))  // 0,1,2,3...
        guard currentWhole > lastDingMile else { return }
        // Ding once per mile crossed
        lastDingMile = currentWhole
        // Haptic + sound
        WKInterfaceDevice.current().play(.notification)
    }
    
    private func startTelemetryLoopIfNeeded() {
        guard telemetryTask == nil else { return }
        telemetryTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                // Paused is still an active workout state the HUD must know about.
                if self.running { self.send() }
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
    }
    
    private func stopTelemetryLoop() {
        telemetryTask?.cancel()
        telemetryTask = nil
    }
    
    private func applyPhoneSettings(_ settings: [String: Any]) {
        // Protect against settings arriving out of order across WC transports.
        if let updatedAt = Self.doubleValue(from: settings["settingsUpdatedAt"]) {
            guard updatedAt >= lastAppliedSettingsUpdatedAt else { return }
            lastAppliedSettingsUpdatedAt = updatedAt
        }
        var didChange = false
        if let theme = settings["theme"] as? String {
            let normalizedTheme = theme.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if themeKey != normalizedTheme {
                themeKey = normalizedTheme
                didChange = true
            }
        }
        if let goal = Self.doubleValue(from: settings["goalMiles"]), goal >= 0, goalMiles != goal {
            goalMiles = goal
            didChange = true
        }
        if didChange { send() }
    }
    
    private func calculateTotalCalories(startDate: Date, endDate: Date, completion: @escaping (Double) -> Void) {
        guard let basalType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
            completion(activeCalories)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(
            quantityType: basalType, quantitySamplePredicate: predicate, options: .cumulativeSum
        ) { [weak self] _, statistics, _ in
            guard let self else { return }
            let basalCalories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            Task { @MainActor in
                let combined = self.activeCalories + basalCalories
                completion(combined)
            }
        }
        store.execute(query)
    }
    
    private func updatePeakSpeed(totalMiles: Double, at date: Date) {
        defer {
            lastSpeedMiles = totalMiles
            lastSpeedSampleDate = date
        }
        guard running, !paused, let previousMiles = lastSpeedMiles, let previousDate = lastSpeedSampleDate else {
            return
        }
        let deltaMiles = totalMiles - previousMiles
        let deltaSeconds = date.timeIntervalSince(previousDate)
        // Ignore duplicates, backward corrections, and ultra-short sample intervals.
        guard deltaMiles > 0, deltaSeconds >= 0.75 else { return }
        let instantaneousMPH = deltaMiles / (deltaSeconds / 3_600)
        // Ignore impossible one-frame spikes from HealthKit distance corrections.
        guard instantaneousMPH > 0, instantaneousMPH <= 30 else { return }
        peakSpeedMPH = max(peakSpeedMPH, instantaneousMPH)
    }
    
    private func handlePhonePayload(_ payload: [String: Any]) {
        applyPhoneSettings(payload)
        guard let command = payload["cmd"] as? String else { return }
        switch command {
        case "start": start()
        case "pause": pause()
        case "resume": resume()
        case "stop": stop()
        case "snapshot": send()
        default: break
        }
    }
    
    // MARK: - Helpers
    private func resetWorkoutStateForStart() {
        workoutFinalized = false
        isMirroringStarting = false
        isMirroringActive = false
        lastDingMile = 0
        miles = 0
        steps = 0
        hr = 0
        averageHeartRate = 0
        peakHeartRate = 0
        activeCalories = 0
        totalCalories = 0
        peakSpeedMPH = 0
        lastSpeedMiles = nil
        lastSpeedSampleDate = nil
        elapsedSeconds = 0
        elapsedMilliseconds = 0
        accumulatedPausedDuration = 0
        pauseStartedAt = nil
    }
    
    private func clearWorkoutSessionState() {
        session = nil
        builder = nil
        workoutStartDate = nil
        isMirroringStarting = false
        isMirroringActive = false
        stopElapsedTimer()
        stopTelemetryLoop()
    }
    
    private func captureFinalHeartRateStatistics(from builder: HKLiveWorkoutBuilder) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
            let statistics = builder.statistics(for: heartRateType)
        else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        if let average = statistics.averageQuantity()?.doubleValue(for: unit), average > 0 {
            averageHeartRate = average
        }
        if let peak = statistics.maximumQuantity()?.doubleValue(for: unit), peak > 0 { peakHeartRate = peak }
    }
    
    private func captureFinalActiveCalories(from builder: HKLiveWorkoutBuilder) {
        guard let activeType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let quantity = builder.statistics(for: activeType)?.sumQuantity()
        else { return }
        activeCalories = quantity.doubleValue(for: .kilocalorie())
    }
    
    nonisolated private static func doubleValue(from value: Any?) -> Double? {
        switch value {
        case let value as Double: return value
        case let value as NSNumber: return value.doubleValue
        case let value as String: return Double(value)
        default: return nil
        }
    }
    
    private func startWorkoutMirroringIfNeeded() {
        guard !isMirroringStarting, !isMirroringActive, let session else { return }
        isMirroringStarting = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await session.startMirroringToCompanionDevice()
                self.isMirroringStarting = false
                self.isMirroringActive = true
                self.send()
            } catch {
                self.isMirroringStarting = false
                self.isMirroringActive = false
            }
        }
    }
    
    private func sendViaWorkoutMirror(_ payload: [String: Any]) {
        guard isMirroringActive, let session else { return }
        guard JSONSerialization.isValidJSONObject(payload) else { return }
        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            Task { @MainActor in
                try? await session.sendToRemoteWorkoutSession(data: data)
            }
        } catch {
            // The independent WatchConnectivity message and latest-state checkpoint remain available.
        }
    }
    
    private func currentTelemetryPayload() -> [String: Any] {
        [
            "theme": themeKey,
            "goalMiles": goalMiles,
            "miles": miles,
            "steps": steps,
            "hr": hr,
            "averageHeartRate": averageHeartRate,
            "peakHeartRate": peakHeartRate,
            "peakSpeedMPH": peakSpeedMPH,
            "running": running,
            "paused": paused,
            "pace": paceString,
            "elapsedSeconds": elapsedSeconds,
            "elapsedMilliseconds": elapsedMilliseconds,
            "pausedDuration": currentPausedDuration,
            "activeCalories": activeCalories,
            "totalCalories": totalCalories,
            "finalized": workoutFinalized,
            "sentAt": Date().timeIntervalSince1970
        ]
    }
    
    private func checkpointLatestState(_ payload: [String: Any]) {
        let wc = WCSession.default
        guard wc.activationState == .activated else { return }
        try? wc.updateApplicationContext(payload)
    }
    
    private func sendViaWatchConnectivity(_ payload: [String: Any]) {
        let wc = WCSession.default
        guard wc.activationState == .activated, wc.isReachable else { return }
        // Keep the acknowledged delivery path; the phone replies after processing.
        // Mirroring and the latest-state checkpoint remain available on failure.
        wc.sendMessage(payload, replyHandler: { _ in }, errorHandler: nil)
    }

    private var currentPausedDuration: TimeInterval {
        let ongoingPause = pauseStartedAt.map { max(0, Date().timeIntervalSince($0)) } ?? 0
        return accumulatedPausedDuration + ongoingPause
    }
    private func beginPauseTrackingIfNeeded(at date: Date = Date()) {
        guard pauseStartedAt == nil else { return }
        pauseStartedAt = date
    }
    
    private func endPauseTrackingIfNeeded(at date: Date = Date()) {
        guard let pauseStartedAt else { return }
        accumulatedPausedDuration += max(0, date.timeIntervalSince(pauseStartedAt))
        self.pauseStartedAt = nil
    }
    
    private func handleWorkoutStartFailure() {
        let currentSession = session
        running = false
        paused = false
        send()
        clearWorkoutSessionState()
        currentSession?.end()
        presentAlert(.workoutStartFailed)
    }
    
    private func presentAlert(_ alert: WatchWorkoutAlert) {
        guard userAlert == nil else { return }
        userAlert = alert
    }
}

// MARK: - HK delegates
extension WatchWorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError _: Error) {
        Task { @MainActor in
            self.running = false
            self.paused = false
            // Send the final known state before tearing down our references.
            self.send()
            self.clearWorkoutSessionState()
            self.presentAlert(.workoutInterrupted)
        }
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from _: HKWorkoutSessionState, date: Date) {
        Task { @MainActor in
            guard self.session === workoutSession else { return }
            switch toState {
            case .running:
                guard self.running else { return }
                self.endPauseTrackingIfNeeded(at: date)
                self.running = true
                self.paused = false
                self.startElapsedTimer()
                self.startTelemetryLoopIfNeeded()
                self.startWorkoutMirroringIfNeeded()
                self.send()
            case .paused:
                guard self.running else { return }
                self.beginPauseTrackingIfNeeded(at: date)
                self.running = true
                self.paused = true
                self.stopElapsedTimer()
                self.startTelemetryLoopIfNeeded()
                self.send()
            case .ended:
                self.endPauseTrackingIfNeeded(at: date)
                self.running = false
                self.paused = false
                self.stopElapsedTimer()
                self.isMirroringStarting = false
                self.isMirroringActive = false
                self.send()
                self.stopTelemetryLoop()
            default: break
            }
        }
    }
    
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        var newMiles: Double?
        var newHR: Int?
        var newSteps: Int?
        var newAverageHeartRate: Double?
        var newPeakHeartRate: Double?
        var newActiveCalories: Double?
        if let distType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            collectedTypes.contains(distType), let dist = workoutBuilder.statistics(for: distType)?.sumQuantity()
        {
            let meters = dist.doubleValue(for: .meter())
            newMiles = meters / 1609.344
        }
        if let hrType = HKObjectType.quantityType(forIdentifier: .heartRate), collectedTypes.contains(hrType),
            let statistics = workoutBuilder.statistics(for: hrType)
        {
            let unit = HKUnit.count().unitDivided(by: .minute())
            if let recent = statistics.mostRecentQuantity() {
                let bpm = recent.doubleValue(for: unit)
                newHR = Int(bpm.rounded())
            }
            newAverageHeartRate = statistics.averageQuantity()?.doubleValue(for: unit)
            newPeakHeartRate = statistics.maximumQuantity()?.doubleValue(for: unit)
        }
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount), collectedTypes.contains(stepType),
            let quantity = workoutBuilder.statistics(for: stepType)?.sumQuantity()
        {
            newSteps = Int(quantity.doubleValue(for: .count()).rounded())
        }
        if let activeType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            collectedTypes.contains(activeType),
            let quantity = workoutBuilder.statistics(for: activeType)?.sumQuantity()
        {
            newActiveCalories = quantity.doubleValue(for: .kilocalorie())
        }
        let milesValue = newMiles
        let hrValue = newHR
        let stepsValue = newSteps
        let averageHeartRateValue = newAverageHeartRate
        let peakHeartRateValue = newPeakHeartRate
        let activeCaloriesValue = newActiveCalories
        let speedSampleDate = Date()

        Task { @MainActor in
            if let milesValue {
                self.updatePeakSpeed(totalMiles: milesValue, at: speedSampleDate)
                self.miles = milesValue
            }
            if let hrValue { self.hr = hrValue }
            if let stepsValue { self.steps = stepsValue }
            if let averageHeartRateValue, averageHeartRateValue > 0 { self.averageHeartRate = averageHeartRateValue }
            if let peakHeartRateValue, peakHeartRateValue > 0 { self.peakHeartRate = peakHeartRateValue }
            if let activeCaloriesValue { self.activeCalories = activeCaloriesValue }
            self.checkForMileDing()
            self.send()
        }
    }
}

// MARK: - WatchConnectivity delegate
extension WatchWorkoutManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error _: Error?) {
        guard activationState == .activated else { return }
        let context = session.receivedApplicationContext
        Task { @MainActor in self.applyPhoneSettings(context) }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            // Send current state as soon as the channel returns; don't replay old ticks.
            if reachable { self.send() }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.handlePhonePayload(message)
            replyHandler(
                self.currentTelemetryPayload()
            )
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in self.applyPhoneSettings(applicationContext) }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in self.handlePhonePayload(userInfo) }
    }
}
