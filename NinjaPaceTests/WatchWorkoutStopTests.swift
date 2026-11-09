//
//  WatchTelemetryOrderTests.swift
//  NinjaPaceTests
//
//  Created by Kevin Montemayor on 9/21/26.
//

import Foundation
import SwiftData
import Testing
@testable import NinjaPace

@MainActor
@Suite("Watch workout stop synchronization")
struct WatchWorkoutStopTests {
    private func snapshot(_ sentAt: Double, running: Bool, elapsed: Int,
                          paused: Bool = false, finalized: Bool = false) -> [String: Any] {
        ["sentAt": sentAt, "running": running, "paused": paused,
         "elapsedSeconds": elapsed, "finalized": finalized]
    }

    @Test("Stop freezes phone and HUD immediately, before final statistics", arguments: [false, true])
    func stopBeforeFinalization(paused: Bool) async throws {
        let manager = HealthStreamManager(startWatchServices: false)
        manager.applyWatchTelemetry(snapshot(100, running: true, elapsed: 60, paused: paused))
        manager.applyWatchTelemetry(snapshot(101, running: false, elapsed: 61))

        #expect(!manager.isWorkoutRunning)
        #expect(!manager.isWorkoutPaused)
        #expect(!manager.watchTelemetryActive)
        #expect(manager.elapsedString == "00:01:01.00")
        #expect(manager.renderedElapsedMilliseconds == 61_000)
        // Give the old smoothing task an opportunity to run after cancellation.
        try await Task.sleep(for: .milliseconds(80))
        #expect(manager.elapsedString == "00:01:01.00")
        #expect(manager.renderedElapsedMilliseconds == 61_000)
        #expect(manager.userAlert == nil)
    }

    @Test("A stopped reconnect snapshot updates the phone even without a running timer")
    func stoppedSnapshot() {
        let manager = HealthStreamManager(startWatchServices: false)
        manager.applyWatchTelemetry(snapshot(101, running: false, elapsed: 125))
        #expect(manager.elapsedString == "00:02:05.00")
        #expect(manager.renderedElapsedMilliseconds == 125_000)
        #expect(!manager.isWorkoutRunning)
    }

    @Test("Mirrored end stops a lost live stream and rejects buffered running ticks")
    func mirroredEnd() async throws {
        let manager = HealthStreamManager(startWatchServices: false)
        manager.applyWatchTelemetry(snapshot(100, running: true, elapsed: 60))
        manager.applyMirroredWatchWorkoutEnd(at: Date(timeIntervalSince1970: 102))
        manager.applyWatchTelemetry(snapshot(101, running: true, elapsed: 61))
        #expect(!manager.isWorkoutRunning)
        #expect(manager.elapsedString == "00:01:00.00")
        try await Task.sleep(for: .milliseconds(80))
        #expect(manager.renderedElapsedMilliseconds == 60_000)
        #expect(manager.userAlert == nil)
        // Final statistics remain authoritative after the fallback stopped the UI.
        manager.applyWatchTelemetry(snapshot(103, running: false, elapsed: 62))
        #expect(manager.elapsedString == "00:01:02.00")
    }

    @Test("An old mirrored end cannot stop a newer workout")
    func delayedEndAfterNewWorkout() {
        let manager = HealthStreamManager(startWatchServices: false)
        manager.applyWatchTelemetry(snapshot(100, running: true, elapsed: 60))
        manager.applyWatchTelemetry(snapshot(102, running: false, elapsed: 62))
        manager.applyWatchTelemetry(snapshot(200, running: true, elapsed: 1))
        manager.applyMirroredWatchWorkoutEnd(at: Date(timeIntervalSince1970: 102))
        #expect(manager.isWorkoutRunning)
        #expect(manager.elapsedSecondsFromWatch == 1)
        manager.applyWatchTelemetry(snapshot(201, running: false, elapsed: 2))
    }

    @Test("Final statistics save once after an immediate stop")
    func finalStatistics() throws {
        let container = try ModelContainer(for: WorkoutRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let manager = HealthStreamManager(startWatchServices: false)
        manager.workoutHistoryStore = WorkoutHistoryStore(modelContext: context,
            achievementUnlockManager: AchievementUnlockManager())
        manager.applyWatchTelemetry(snapshot(100, running: true, elapsed: 60))
        manager.applyWatchTelemetry(snapshot(101, running: false, elapsed: 61))
        #expect(try context.fetchCount(FetchDescriptor<WorkoutRecord>()) == 0)

        var final = snapshot(102, running: false, elapsed: 62, finalized: true)
        final["activeCalories"] = 42.0
        final["totalCalories"] = 50.0
        manager.applyWatchTelemetry(final)
        // Reconnect resends finalization with a newer timestamp; history stays unique.
        final["sentAt"] = 103.0
        manager.applyWatchTelemetry(final)
        let records = try context.fetch(FetchDescriptor<WorkoutRecord>())
        #expect(records.count == 1)
        #expect(records.first?.activeCalories == 42)
        #expect(records.first?.totalCalories == 50)
        #expect(records.first?.duration == 62)
        #expect(!manager.isWorkoutRunning)
        #expect(manager.elapsedString == "00:01:02.00")
    }
}
