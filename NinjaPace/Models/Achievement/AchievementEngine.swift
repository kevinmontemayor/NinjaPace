//
//  AchievementEngine.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/7/26.
//

import Foundation

struct AchievementEngine {
    let workouts: [WorkoutRecord]
    
    private var totalMiles: Double {
        workouts.reduce(0) {
            $0 + $1.completedMiles
        }
    }
    
    private var completedGoals: Int {
        workouts.filter {
            $0.wasGoalCompleted
        }
        .count
    }
    
    func isUnlocked(_ achievement: Achievement) -> Bool {
        switch achievement {
            
        case .firstWorkout:
            return !workouts.isEmpty
            
        // MARK: Distance in one workout
            
        case .fiveK:
            return containsWorkout(
                miles: 3.10686
            )
            
        case .tenK:
            return containsWorkout(
                miles: 6.21371
            )
            
        case .halfMarathon:
            return containsWorkout(
                miles: 13.1094
            )
            
        case .marathon:
            return containsWorkout(
                miles: 26.2188
            )
            
        // MARK: Workout count
            
        case .fiveWorkouts:
            return workouts.count >= 5
            
        case .tenWorkouts:
            return workouts.count >= 10
            
        case .twentyFiveWorkouts:
            return workouts.count >= 25
            
        case .fiftyWorkouts:
            return workouts.count >= 50
            
        case .hundredWorkouts:
            return workouts.count >= 100
            
        // MARK: Lifetime mileage
            
        case .twentyFiveMiles:
            return totalMiles >= 25
            
        case .fiftyMiles:
            return totalMiles >= 50
            
        case .hundredMiles:
            return totalMiles >= 100
            
        case .twoHundredFiftyMiles:
            return totalMiles >= 250
            
        case .fiveHundredMiles:
            return totalMiles >= 500
            
        case .thousandMiles:
            return totalMiles >= 1_000
            
        // MARK: Completed goals
            
        case .firstGoal:
            return completedGoals >= 1
            
        case .fiveGoals:
            return completedGoals >= 5
            
        case .tenGoals:
            return completedGoals >= 10
            
        case .twentyFiveGoals:
            return completedGoals >= 25
            
        case .fiftyGoals:
            return completedGoals >= 50
            
        case .hundredGoals:
            return completedGoals >= 100
            
        // MARK: Goal performance
            
        case .overAchiever:
            return workouts.contains { workout in
                guard workout.goalMiles > 0 else {
                    return false
                }
                
                return workout.completedMiles >= workout.goalMiles * 1.25
            }
            
        case .doubleGoal:
            return workouts.contains { workout in
                guard workout.goalMiles > 0 else {
                    return false
                }
                
                return workout.completedMiles >= workout.goalMiles * 2
            }
        }
    }
    
    private func containsWorkout(miles requiredMiles: Double) -> Bool {
        workouts.contains {
            $0.completedMiles >= requiredMiles
        }
    }
}

extension AchievementEngine {
    func progress(for achievement: Achievement) -> AchievementProgress {
        switch achievement {
            
        case .firstWorkout:
            return .init(current: Double(workouts.count), target: 1)
            
        case .fiveWorkouts:
            return workoutCountProgress(5)
            
        case .tenWorkouts:
            return workoutCountProgress(10)
            
        case .twentyFiveWorkouts:
            return workoutCountProgress(25)
            
        case .fiftyWorkouts:
            return workoutCountProgress(50)
            
        case .hundredWorkouts:
            return workoutCountProgress(100)
            
        case .twentyFiveMiles:
            return mileageProgress(25)
            
        case .fiftyMiles:
            return mileageProgress(50)
            
        case .hundredMiles:
            return mileageProgress(100)
            
        case .twoHundredFiftyMiles:
            return mileageProgress(250)
            
        case .fiveHundredMiles:
            return mileageProgress(500)
            
        case .thousandMiles:
            return mileageProgress(1_000)
            
        case .firstGoal:
            return goalProgress(1)
            
        case .fiveGoals:
            return goalProgress(5)
            
        case .tenGoals:
            return goalProgress(10)
            
        case .twentyFiveGoals:
            return goalProgress(25)
            
        case .fiftyGoals:
            return goalProgress(50)
            
        case .hundredGoals:
            return goalProgress(100)
            
        case .fiveK:
            return bestDistanceProgress(target: 3.10686)
            
        case .tenK:
            return bestDistanceProgress(target: 6.21371)
            
        case .halfMarathon:
            return bestDistanceProgress(target: 13.1094)
            
        case .marathon:
            return bestDistanceProgress(target: 26.2188)
            
        case .overAchiever:
            return bestGoalMultiplierProgress(target: 1.25)
            
        case .doubleGoal:
            return bestGoalMultiplierProgress(target: 2)
        }
    }

    private func workoutCountProgress(_ target: Double) -> AchievementProgress {
        .init(current: Double(workouts.count), target: target)
    }

    private func mileageProgress(_ target: Double) -> AchievementProgress {
        .init(current: totalMiles, target: target)
    }

    private func goalProgress(_ target: Double) -> AchievementProgress {
        .init(current: Double(completedGoals), target: target)
    }

    private func bestDistanceProgress(target: Double) -> AchievementProgress {
        let best = workouts.map(\.completedMiles).max() ?? 0
        
        return .init(current: best, target: target)
    }

    private func bestGoalMultiplierProgress(target: Double) -> AchievementProgress {
        let bestMultiplier = workouts.compactMap { workout -> Double? in
            guard workout.goalMiles > 0 else {
                return nil
            }
            
            return workout.completedMiles / workout.goalMiles
        }.max() ?? 0
        
        return .init(current: bestMultiplier, target: target)
    }
}

extension AchievementEngine {
    var unlockedAchievements: Set<Achievement> {
        Set(
            Achievement.allCases.filter {
                isUnlocked($0)
            }
        )
    }
    
    var unlockedAchievementCount: Int {
        unlockedAchievements.count
    }
    
    var totalAchievementCount: Int {
        Achievement.allCases.count
    }
    
    var hasUnlockedAllAchievements: Bool {
        totalAchievementCount > 0 && unlockedAchievementCount == totalAchievementCount
    }
}

extension AchievementEngine {

    // MARK: - Achievement History

    func firstEarnedDate(for achievement: Achievement) -> Date? {

        let chronologicalWorkouts = workouts.sorted {
            $0.endedAt < $1.endedAt
        }

        // Prefer the permanently recorded unlock event.
        if let recordedWorkout = chronologicalWorkouts.first(
            where: {
                $0.unlockedAchievementIDs.contains(
                    achievement.rawValue
                )
            }
        ) {
            return recordedWorkout.endedAt
        }

        // Older workout records may not have stored unlock IDs.
        // Reconstruct the original milestone from workout history.
        switch achievement {

        case .firstWorkout:
            return chronologicalWorkouts.first?.endedAt

        case .fiveK:
            return firstDistanceDate(
                3.10686,
                in: chronologicalWorkouts
            )

        case .tenK:
            return firstDistanceDate(
                6.21371,
                in: chronologicalWorkouts
            )

        case .halfMarathon:
            return firstDistanceDate(
                13.1094,
                in: chronologicalWorkouts
            )

        case .marathon:
            return firstDistanceDate(
                26.2188,
                in: chronologicalWorkouts
            )

        case .fiveWorkouts:
            return workoutCountDate(
                5,
                in: chronologicalWorkouts
            )

        case .tenWorkouts:
            return workoutCountDate(
                10,
                in: chronologicalWorkouts
            )

        case .twentyFiveWorkouts:
            return workoutCountDate(
                25,
                in: chronologicalWorkouts
            )

        case .fiftyWorkouts:
            return workoutCountDate(
                50,
                in: chronologicalWorkouts
            )

        case .hundredWorkouts:
            return workoutCountDate(
                100,
                in: chronologicalWorkouts
            )

        case .twentyFiveMiles:
            return cumulativeMileageDate(
                25,
                in: chronologicalWorkouts
            )

        case .fiftyMiles:
            return cumulativeMileageDate(
                50,
                in: chronologicalWorkouts
            )

        case .hundredMiles:
            return cumulativeMileageDate(
                100,
                in: chronologicalWorkouts
            )

        case .twoHundredFiftyMiles:
            return cumulativeMileageDate(
                250,
                in: chronologicalWorkouts
            )

        case .fiveHundredMiles:
            return cumulativeMileageDate(
                500,
                in: chronologicalWorkouts
            )

        case .thousandMiles:
            return cumulativeMileageDate(
                1_000,
                in: chronologicalWorkouts
            )

        case .firstGoal:
            return completedGoalDate(
                1,
                in: chronologicalWorkouts
            )

        case .fiveGoals:
            return completedGoalDate(
                5,
                in: chronologicalWorkouts
            )

        case .tenGoals:
            return completedGoalDate(
                10,
                in: chronologicalWorkouts
            )

        case .twentyFiveGoals:
            return completedGoalDate(
                25,
                in: chronologicalWorkouts
            )

        case .fiftyGoals:
            return completedGoalDate(
                50,
                in: chronologicalWorkouts
            )

        case .hundredGoals:
            return completedGoalDate(
                100,
                in: chronologicalWorkouts
            )

        case .overAchiever:
            return chronologicalWorkouts.first {
                guard $0.goalMiles > 0 else {
                    return false
                }

                return $0.completedMiles >=
                    $0.goalMiles * 1.25
            }?.endedAt

        case .doubleGoal:
            return chronologicalWorkouts.first {
                guard $0.goalMiles > 0 else {
                    return false
                }

                return $0.completedMiles >=
                    $0.goalMiles * 2
            }?.endedAt
        }
    }

    func qualifyingCount(
        for achievement: Achievement
    ) -> Int? {

        switch achievement {

        case .fiveK:
            return distanceCount(3.10686)

        case .tenK:
            return distanceCount(6.21371)

        case .halfMarathon:
            return distanceCount(13.1094)

        case .marathon:
            return distanceCount(26.2188)

        case .overAchiever:
            return workouts.filter {
                guard $0.goalMiles > 0 else {
                    return false
                }

                return $0.completedMiles >=
                    $0.goalMiles * 1.25
            }
            .count

        case .doubleGoal:
            return workouts.filter {
                guard $0.goalMiles > 0 else {
                    return false
                }

                return $0.completedMiles >=
                    $0.goalMiles * 2
            }
            .count

        default:
            // These are cumulative milestones rather than
            // independently repeatable accomplishments.
            return nil
        }
    }

    private func distanceCount(
        _ requiredMiles: Double
    ) -> Int {
        workouts.filter {
            $0.completedMiles >= requiredMiles
        }
        .count
    }

    private func firstDistanceDate(
        _ requiredMiles: Double,
        in workouts: [WorkoutRecord]
    ) -> Date? {
        workouts.first {
            $0.completedMiles >= requiredMiles
        }?.endedAt
    }

    private func workoutCountDate(
        _ requiredCount: Int,
        in workouts: [WorkoutRecord]
    ) -> Date? {
        guard workouts.count >= requiredCount else {
            return nil
        }

        return workouts[requiredCount - 1].endedAt
    }

    private func completedGoalDate(
        _ requiredCount: Int,
        in workouts: [WorkoutRecord]
    ) -> Date? {
        let completed = workouts.filter {
            $0.wasGoalCompleted
        }

        guard completed.count >= requiredCount else {
            return nil
        }

        return completed[requiredCount - 1].endedAt
    }

    private func cumulativeMileageDate(
        _ targetMiles: Double,
        in workouts: [WorkoutRecord]
    ) -> Date? {
        var total = 0.0

        for workout in workouts {
            total += workout.completedMiles

            if total >= targetMiles {
                return workout.endedAt
            }
        }

        return nil
    }
    
    func nextLockedAchievement(after achievement: Achievement) -> Achievement? {
        
        let progression = achievement.progression
        
        guard let currentIndex = progression.firstIndex(of: achievement) else {
            return nil
        }
        
        let remainingAchievements = progression.dropFirst(
            currentIndex + 1
        )
        
        return remainingAchievements.first {
            !isUnlocked($0)
        }
    }
}
