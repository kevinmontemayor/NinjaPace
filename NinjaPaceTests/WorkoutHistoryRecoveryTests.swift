//
//  WorkoutHistoryRecoveryTests.swift
//  NinjaPaceTests
//
//  Created by Kevin Montemayor on 10/18/26.
//

import Foundation
import SwiftData
import Testing
@testable import NinjaPace

@Suite("Workout History Recovery")
@MainActor
struct WorkoutHistoryRecoveryTests {
    private func workout(offset: TimeInterval = 0, miles: Double? = 3,
                         isIndoor: Bool? = nil) -> RecoveryWorkout {
        let start = Date(timeIntervalSince1970: 1_750_000_000 + offset)
        return RecoveryWorkout(startDate: start,
                               endDate: start.addingTimeInterval(1_900), duration: 1_800,
                               distanceMiles: miles, isIndoor: isIndoor)
    }

    @Test("Recovery preserves identity and active duration without inventing a goal")
    func preservesAvailableFacts() {
        let sample = workout()
        let record = WorkoutHistoryRecovery.makeRecord(from: sample)
        #expect(record.id == sample.uuid)
        #expect(record.completedMiles == 3)
        #expect(record.activeDuration == 1_800)
        #expect(record.averagePaceSecondsPerMile == 600)
        #expect(record.goalMiles == 0)
        #expect(!record.wasGoalCompleted)
        #expect(record.milesOverGoal == 0)
        #expect(record.averageHeartRate == nil)
    }

    @Test("Repeated imports and older local records are not duplicated")
    func importsIdempotently() throws {
        let container = try ModelContainer(for: WorkoutRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let sample = workout()
        #expect(try WorkoutHistoryRecovery.importWorkouts([sample, sample], into: container) == 1)
        #expect(try WorkoutHistoryRecovery.importWorkouts([sample], into: container) == 0)
        let context = ModelContext(container)
        let records = try context.fetch(FetchDescriptor<WorkoutRecord>())
        #expect(records.count == 1)
        let older = WorkoutHistoryRecovery.makeRecord(from: sample)
        older.id = UUID()
        older.goalMiles = 5
        #expect(WorkoutHistoryRecovery.alreadyExists(sample, in: [older]))
        #expect(older.goalMiles == 5)
    }
}


extension WorkoutHistoryRecoveryTests {
    @Test("Missing Health measurements do not fabricate pace, heart rate, or a goal")
    func missingMeasurements() {
        let record = WorkoutHistoryRecovery.makeRecord(from: workout(miles: nil))
        #expect(record.completedMiles == 0)
        #expect(record.steps == 0)
        #expect(record.averagePaceSecondsPerMile == nil)
        #expect(record.averageHeartRate == nil)
        #expect(record.peakHeartRate == nil)
        #expect(record.totalCalories == nil)
        #expect(record.workoutLocationRawValue == nil)
        #expect(record.splits.isEmpty)
        #expect(record.heartRateZones.isEmpty)
        #expect(record.unlockedAchievementIDs.isEmpty)
        #expect(!record.wasGoalCompleted)
    }

    @Test("Recovery preserves indoor and outdoor metadata", arguments: [true, false])
    func locationMetadata(indoor: Bool) {
        let record = WorkoutHistoryRecovery.makeRecord(
            from: workout(isIndoor: indoor))
        #expect(record.workoutLocationRawValue == (indoor ? "indoor" : "outdoor"))
    }

    @Test("Timestamp matching requires both endpoints and respects the five-second boundary")
    func timestampMatching() {
        let sample = workout()
        let local = WorkoutHistoryRecovery.makeRecord(from: sample)
        local.id = UUID()
        local.startedAt = sample.startDate.addingTimeInterval(4.9)
        local.endedAt = sample.endDate.addingTimeInterval(-4.9)
        #expect(WorkoutHistoryRecovery.alreadyExists(sample, in: [local]))
        local.startedAt = sample.startDate.addingTimeInterval(5)
        #expect(!WorkoutHistoryRecovery.alreadyExists(sample, in: [local]))
        local.startedAt = sample.startDate
        local.endedAt = sample.endDate.addingTimeInterval(5)
        #expect(!WorkoutHistoryRecovery.alreadyExists(sample, in: [local]))
        // A Health UUID remains authoritative even if local timestamps differ.
        local.id = sample.uuid
        #expect(WorkoutHistoryRecovery.alreadyExists(sample, in: [local]))
    }

    @Test("Mixed recovery preserves edited local records and inserts only distinct workouts")
    func mixedImportPreservesEdits() throws {
        let container = try ModelContainer(for: WorkoutRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let sample = workout()
        let local = WorkoutHistoryRecovery.makeRecord(from: sample)
        local.id = UUID() // Older phone records used independent UUIDs.
        let localID = local.id
        #expect(local.updateGoalMiles(2))
        local.unlockedAchievementIDs = ["firstGoal"]
        context.insert(local)
        try context.save()
        let distinct = workout(offset: 86_400)
        #expect(try WorkoutHistoryRecovery.importWorkouts([sample, distinct, distinct], into: container) == 1)
        let verify = ModelContext(container)
        let records = try verify.fetch(FetchDescriptor<WorkoutRecord>())
        #expect(records.count == 2)
        let preserved = try #require(records.first { $0.id == localID })
        #expect(preserved.goalMiles == 2)
        #expect(preserved.wasGoalCompleted)
        #expect(preserved.unlockedAchievementIDs == ["firstGoal"])
        #expect(try WorkoutHistoryRecovery.importWorkouts([], into: container) == 0)
        #expect(try WorkoutHistoryRecovery.importWorkouts([sample, distinct], into: container) == 0)
    }
}
