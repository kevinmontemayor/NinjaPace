//
//  WatchWorkoutManager.swift
//  NinjaPaceWatch Watch App
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
    
    @Published var miles: Double = 0
    @Published var steps: Int = 0
    @Published var hr: Int = 0
    
    @Published var running: Bool = false
    @Published var paused: Bool = false
    
    @Published var streamingEnabled: Bool = true
    @Published var elapsedSeconds: Int = 0
    
    @Published var activeCalories: Double = 0
    @Published var totalCalories: Double = 0
    
    @Published var themeKey: String = "ninja" {
        didSet { storedThemeKey = themeKey }
    }
    
    @Published var goalMiles: Double = 3.11 {
        didSet { storedGoalMiles = goalMiles }
    }
    
    var progress: Double { min(max(miles / max(goalMiles, 0.01), 0), 1) }
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    
    // Throttle outbound messages (OBS only needs ~1/sec)
    private var lastSend = Date.distantPast
    
    private var elapsedTimer: Timer?
    private var lastDingMile: Int = 0
    let pushClient = StatsPushClient()
    
    var paceString: String {
        guard miles >= 0.01, elapsedSeconds > 0 else { return "—" }
        let secPerMile = Double(elapsedSeconds) / miles
        let mile = Int(secPerMile) / 60
        let sec = Int(secPerMile) % 60
        return String(format: "%d:%02d", mile, sec)
    }
    
    func activate() {
        themeKey = storedThemeKey
        goalMiles = storedGoalMiles
        setupWC()
        requestAuth()
    }

    private func setupWC() {
        guard WCSession.isSupported() else { return }
        let s = WCSession.default
        if s.delegate == nil { s.delegate = self }
        if s.activationState != .activated { s.activate() }
    }

    private func requestAuth() {
        let hrType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let distType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        store.requestAuthorization(toShare: [HKObjectType.workoutType()],
                                  read: [hrType, distType, stepType, activeEnergy]) { _, err in
            if let err { print("HK auth err:", err) }
        }
    }

    // MARK: - UI actions
    func toggleStartPause() {
        if !running {
            start()
        } else {
            paused ? resume() : pause()
        }
    }

    func toggleStreaming() {
        streamingEnabled.toggle()

        if streamingEnabled {
            pushClient.macBaseURL = "http://localhost:8787"

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
                        goalMiles: 3.11,
                        progress: 0,
                        running: false,
                        paused: false
                    )
                }

                return StatsPushClient.Payload(
                    theme: self.themeKey,
                    miles: self.miles,
                    steps: self.steps,
                    hr: self.hr,
                    elapsed: StatsPushClient.formatHMS(self.elapsedSeconds),
                    elapsedSeconds: self.elapsedSeconds,
                    pace: self.paceString,
                    activeCalories: self.activeCalories,
                    totalCalories: self.totalCalories,
                    goalMiles: self.goalMiles,
                    progress: self.progress,
                    running: self.running,
                    paused: self.paused
                )
            }
        } else {
            pushClient.stopPushing()
        }
    }
    
    func start() {
        guard session == nil else { return }
        lastDingMile = 0
        
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
            elapsedSeconds = 0
            startElapsedTimer()
            
            paused = false

            let startDate = Date()
            healthStoreSession.startActivity(with: startDate)
            healthStoreBuilder.beginCollection(withStart: startDate) { _,_ in }

            send(force: true)
        } catch {
            print("watch start err:", error)
        }
    }

    func pause() {
        guard running, !paused else { return }
        paused = true
        session?.pause()
        stopElapsedTimer()
        send(force: true)
    }

    func resume() {
        guard running, paused else { return }
        paused = false
        session?.resume()
        startElapsedTimer()
        send(force: true)
    }

    func stop() {
        guard running else { return }
        lastDingMile = 0
        
        paused = false
        running = false

        session?.end()

        // Capture a local reference to avoid capturing the @MainActor-isolated property in a @Sendable closure
        let localBuilder = self.builder
        localBuilder?.endCollection(withEnd: Date()) { _, _ in
            localBuilder?.finishWorkout { _, _ in }
        }

        session = nil
        builder = nil

        // optional: keep stats or reset them
        // miles = 0; steps = 0; hr = 0
        stopElapsedTimer()
        send(force: true)
    }

    // MARK: - Sending
    private func send(force: Bool = false) {
        guard streamingEnabled else { return }

        let now = Date()
        if !force && now.timeIntervalSince(lastSend) < 1.0 { return }
        lastSend = now

        let payload: [String: Any] = [
            "theme": themeKey,
            "goalMiles": goalMiles,
            "miles": miles,
            "steps": steps,
            "hr": hr,
            "running": running,
            "paused": paused,
            "streaming": streamingEnabled,
            "pace": paceString,
            "elapsedSeconds": elapsedSeconds,
            "activeCalories": activeCalories,
            "totalCalories": totalCalories
        ]

        let wc = WCSession.default
        if wc.isReachable {
            wc.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            do {
                try wc.updateApplicationContext(payload)
            } catch {
                // fallback if needed
                wc.transferUserInfo(payload)
            }
        }
    }
    
    private func startElapsedTimer() {
        stopElapsedTimer()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.running, !self.paused else { return }
                self.elapsedSeconds += 1
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

        // Haptic + optional tiny sound
        WKInterfaceDevice.current().play(.notification)
    }
}

// MARK: - HK delegates
extension WatchWorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("watch session error:", error)
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {}

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {

        var newMiles: Double?
        var newHR: Int?
        var newSteps: Int?

        if let distType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
           collectedTypes.contains(distType),
           let dist = workoutBuilder.statistics(for: distType)?.sumQuantity() {
            let meters = dist.doubleValue(for: .meter())
            newMiles = meters / 1609.344
        }

        if let hrType = HKObjectType.quantityType(forIdentifier: .heartRate),
           collectedTypes.contains(hrType),
           let q = workoutBuilder.statistics(for: hrType)?.mostRecentQuantity() {
            let bpm = q.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            newHR = Int(bpm.rounded())
        }

        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
           collectedTypes.contains(stepType),
           let q = workoutBuilder.statistics(for: stepType)?.sumQuantity() {
            newSteps = Int(q.doubleValue(for: .count()).rounded())
        }
        
        if let activeType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
           collectedTypes.contains(activeType),
           let q = workoutBuilder.statistics(for: activeType)?.sumQuantity() {
            let kcal = q.doubleValue(for: .kilocalorie())
            Task { @MainActor in self.activeCalories = kcal }
        }
        
        let milesValue = newMiles
        let hrValue = newHR
        let stepsValue = newSteps

        Task { @MainActor in
            if let milesValue { self.miles = milesValue }
            if let hrValue { self.hr = hrValue }
            if let stepsValue { self.steps = stepsValue }
            self.checkForMileDing()
            self.send()
        }
    }
}

// MARK: - WatchConnectivity delegate
extension WatchWorkoutManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {}

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        if let theme = message["theme"] as? String {
            Task { @MainActor in
                self.themeKey = theme.lowercased()
                self.send(force: true)
            }
        }
        
        if let goal = message["goalMiles"] as? Double {
            Task { @MainActor in
                self.goalMiles = goal
                self.send(force: true)
            }
        } else if let goal = message["goalMiles"] as? NSNumber {
            Task { @MainActor in
                self.goalMiles = goal.doubleValue
                self.send(force: true)
            }
        }
        
        guard let cmd = message["cmd"] as? String else { return }
        Task { @MainActor in
            switch cmd {
            case "start": self.start()
            case "pause": self.pause()
            case "resume": self.resume()
            case "stop": self.stop()
            case "streamOn": self.streamingEnabled = true; self.send(force: true)
            case "streamOff": self.streamingEnabled = false
            default: break
            }
        }
    }
    
    nonisolated func session(_ session: WCSession,
                             didReceiveApplicationContext applicationContext: [String : Any]) {

        var didChange = false

        if let theme = applicationContext["theme"] as? String {
            Task { @MainActor in
                self.themeKey = theme.lowercased()
            }
            didChange = true
        }

        if let goal = applicationContext["goalMiles"] as? Double {
            Task { @MainActor in
                self.goalMiles = goal
            }
            didChange = true
        } else if let goal = applicationContext["goalMiles"] as? NSNumber {
            Task { @MainActor in
                self.goalMiles = goal.doubleValue
            }
            didChange = true
        }

        if didChange {
            Task { @MainActor in self.send(force: true) }
        }
    }
}
