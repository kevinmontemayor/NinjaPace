//
//  HistoricalGoalProgressTests.swift
//  NinjaPaceTests
//
//  Created by Kevin Montemayor on 9/18/26.
//

import Foundation
import SwiftData
import Testing
@testable import NinjaPace

@Suite("Historical Goal Progress")
@MainActor
struct HistoricalGoalProgressTests {
    private func record(goal: Double = 0) -> WorkoutRecord {
        WorkoutRecord(startedAt: Date(timeIntervalSince1970: 1_750_000_000),
                      endedAt: Date(timeIntervalSince1970: 1_750_001_800),
                      goalMiles: goal, completedMiles: 3.14, steps: 6_240,
                      duration: 1_800)
    }

    @Test("Goal corrections persist all derived fields without changing workout measurements")
    func persistedCorrection() throws {
        let container = try ModelContainer(for: WorkoutRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let workout = record()
        context.insert(workout)
        try context.save()
        #expect(workout.updateGoalMiles(3.14))
        try context.save()
        let freshContext = ModelContext(container)
        let saved = try #require(try freshContext.fetch(FetchDescriptor<WorkoutRecord>()).first)
        #expect(saved.id == workout.id)
        #expect(saved.goalMiles == 3.14)
        #expect(saved.wasGoalCompleted)
        #expect(saved.goalCompletionPercentage == 100)
        #expect(saved.milesOverGoal == 0)
        #expect(saved.completedMiles == 3.14)
        #expect(saved.steps == 6_240)
        #expect(saved.duration == 1_800)
        #expect(saved.startedAt == workout.startedAt)
        #expect(saved.endedAt == workout.endedAt)
    }

    @Test("Corrected goals cross achievement and warrior thresholds in both directions",
          arguments: [10, 25, 50])
    func progressionThresholds(threshold: Int) {
        let corrected = record()
        let workouts = (0..<(threshold - 1)).map { _ in record(goal: 3) } + [corrected]
        let achievement: Achievement = threshold == 10 ? .tenGoals : threshold == 25 ? .twentyFiveGoals : .fiftyGoals
        let expectedLevel: WarriorProgressionLevel = threshold == 10 ? .level2 : threshold == 25 ? .level3 : .level4
        #expect(!AchievementEngine(workouts: workouts).isUnlocked(achievement))
        #expect(WarriorProgressionLevel.level(for: workouts.filter(\.wasGoalCompleted).count) < expectedLevel)
        #expect(corrected.updateGoalMiles(3.11))
        #expect(workouts.filter(\.wasGoalCompleted).count == threshold)
        #expect(AchievementEngine(workouts: workouts).isUnlocked(achievement))
        #expect(WarriorProgressionLevel.level(for: workouts.filter(\.wasGoalCompleted).count) == expectedLevel)
        #expect(corrected.updateGoalMiles(5))
        #expect(workouts.filter(\.wasGoalCompleted).count == threshold - 1)
        #expect(!AchievementEngine(workouts: workouts).isUnlocked(achievement))
        #expect(WarriorProgressionLevel.level(for: workouts.filter(\.wasGoalCompleted).count) < expectedLevel)
    }

    @Test("Invalid edits leave every goal-derived field unchanged", arguments: [0.0, -1, .infinity, -.infinity, .nan])
    func invalidEdits(value: Double) {
        let workout = record(goal: 3)
        let percentage = workout.goalCompletionPercentage
        let excess = workout.milesOverGoal
        #expect(!workout.updateGoalMiles(value))
        #expect(workout.goalMiles == 3)
        #expect(workout.wasGoalCompleted)
        #expect(workout.goalCompletionPercentage == percentage)
        #expect(workout.milesOverGoal == excess)
    }
}
