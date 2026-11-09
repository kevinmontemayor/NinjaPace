//
//  WorkoutHistoryStore.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/7/26.
//

import Foundation
import SwiftData

@MainActor
final class WorkoutHistoryStore {

    private let modelContext: ModelContext
    private let achievementUnlockManager: AchievementUnlockManager

    init(modelContext: ModelContext, achievementUnlockManager: AchievementUnlockManager) {
        self.modelContext = modelContext
        self.achievementUnlockManager = achievementUnlockManager
    }

    @discardableResult
    func saveWorkout(_ record: WorkoutRecord) throws -> [Achievement] {

        // 1. Fetch history BEFORE inserting the new workout.
        let descriptor = FetchDescriptor<WorkoutRecord>(
            sortBy: [
                SortDescriptor(\WorkoutRecord.startedAt, order: .reverse)
            ]
        )

        let existingWorkouts = try modelContext.fetch(descriptor)

        // 2. Determine everything that was already unlocked.
        let achievementsBefore =
            AchievementEngine(workouts: existingWorkouts)
                .unlockedAchievements

        // 3. Insert and persist the new workout.
        modelContext.insert(record)
        try modelContext.save()

        // 4. Build the new history.
        let updatedWorkouts = existingWorkouts + [record]

        // 5. Re-evaluate achievements.
        let achievementsAfter =
            AchievementEngine(workouts: updatedWorkouts)
                .unlockedAchievements

        // 6. Determine what THIS workout unlocked.
        //
        // Using allCases preserves our intended display order.
        let newlyUnlocked = Achievement.allCases.filter {
            achievementsAfter.contains($0) &&
            !achievementsBefore.contains($0)
        }

        // 7. Tell the presentation system.
        achievementUnlockManager.enqueue(newlyUnlocked)
        MonthlyChallengeStore.shared.evaluate(workouts: updatedWorkouts)

        return newlyUnlocked
    }
}
