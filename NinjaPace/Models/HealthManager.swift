//
//  ContentView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/4/26.
//

import Combine
import Foundation
import Observation

@MainActor
final class HealthManager: ObservableObject {
    // Published state used by ContentView
    @Published var miles: Double = 0
    @Published var steps: Int = 0
    @Published var heartRateBpm: Int = 0
    @Published var isWorkoutRunning: Bool = false

    // Elapsed time handling
    private var startDate: Date?
    private var timer: Timer?

    var elapsedString: String {
        guard let startDate else { return "00:00:00" }
        let elapsed = Int(Date().timeIntervalSince(startDate))
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Permissions
    func requestAuthorization() async {
        // Stub: In a real implementation, request HealthKit permissions here.
        // For now, do nothing.
    }

    // MARK: - Workout lifecycle
    func startWorkout() async {
        guard !isWorkoutRunning else { return }
        isWorkoutRunning = true
        startDate = Date()
        startTimer()

        // Stub demo values that could be updated by HealthKit in a real app
        miles = 0
        steps = 0
        heartRateBpm = 0
    }

    func stopWorkout() async {
        guard isWorkoutRunning else { return }
        isWorkoutRunning = false
        stopTimer()
    }

    // MARK: - Timer
    private func startTimer() {
        stopTimer()
        let timer = Timer(timeInterval: 1, target: self, selector: #selector(timerFired(_:)), userInfo: nil, repeats: true)
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    @objc
    private func timerFired(_ timer: Timer) {
        tick()
    }

    @MainActor
    private func tick() {
        // Trigger UI updates for elapsedString by sending objectWillChange
        self.objectWillChange.send()

        // Optionally simulate metrics increasing during a workout
        if self.isWorkoutRunning {
            self.steps += 2
            self.miles += 0.001
            self.heartRateBpm = max(90, min(170, self.heartRateBpm + Int.random(in: -2...3)))
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

