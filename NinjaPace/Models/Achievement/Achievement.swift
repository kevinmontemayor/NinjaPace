//
//  Achievement.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/7/26.
//

import Foundation

enum AchievementCategory: String, CaseIterable {
    case milestone
    case distance
    case consistency
    case goal
    case endurance
}

enum Achievement: String, CaseIterable, Identifiable, Hashable {
    case firstWorkout

    case fiveK
    case tenK
    case halfMarathon
    case marathon

    case fiveWorkouts
    case tenWorkouts
    case twentyFiveWorkouts
    case fiftyWorkouts
    case hundredWorkouts

    case twentyFiveMiles
    case fiftyMiles
    case hundredMiles
    case twoHundredFiftyMiles
    case fiveHundredMiles
    case thousandMiles

    case firstGoal
    case fiveGoals
    case tenGoals
    case twentyFiveGoals
    case fiftyGoals
    case hundredGoals

    case overAchiever
    case doubleGoal

    var id: String {
        rawValue
    }
}

extension Achievement {
    var title: String {
        switch self {
        case .firstWorkout:
            return "First Steps"

        case .fiveK:
            return "5K Warrior"

        case .tenK:
            return "10K Warrior"

        case .halfMarathon:
            return "Half Marathon"

        case .marathon:
            return "Marathon"

        case .fiveWorkouts:
            return "Getting Started"

        case .tenWorkouts:
            return "Double Digits"

        case .twentyFiveWorkouts:
            return "Committed"

        case .fiftyWorkouts:
            return "Battle Tested"

        case .hundredWorkouts:
            return "Centurion"

        case .twentyFiveMiles:
            return "25 Mile Club"

        case .fiftyMiles:
            return "50 Mile Club"

        case .hundredMiles:
            return "Century Runner"

        case .twoHundredFiftyMiles:
            return "250 Miles"

        case .fiveHundredMiles:
            return "500 Miles"

        case .thousandMiles:
            return "1,000 Mile Legend"

        case .firstGoal:
            return "Target Acquired"

        case .fiveGoals:
            return "Goal Hunter"

        case .tenGoals:
            return "Goal Crusher"

        case .twentyFiveGoals:
            return "Relentless"

        case .fiftyGoals:
            return "Unstoppable"

        case .hundredGoals:
            return "Goal Master"

        case .overAchiever:
            return "Overachiever"

        case .doubleGoal:
            return "Double Trouble"
        }
    }
}

extension Achievement {
    var description: String {
        switch self {
        case .firstWorkout:
            return "Complete your first NinjaPace workout."

        case .fiveK:
            return "Complete at least 3.11 miles in one workout."

        case .tenK:
            return "Complete at least 6.21 miles in one workout."

        case .halfMarathon:
            return "Complete at least 13.1 miles in one workout."

        case .marathon:
            return "Complete at least 26.2 miles in one workout."

        case .fiveWorkouts:
            return "Complete 5 workouts."

        case .tenWorkouts:
            return "Complete 10 workouts."

        case .twentyFiveWorkouts:
            return "Complete 25 workouts."

        case .fiftyWorkouts:
            return "Complete 50 workouts."

        case .hundredWorkouts:
            return "Complete 100 workouts."

        case .twentyFiveMiles:
            return "Log 25 total miles."

        case .fiftyMiles:
            return "Log 50 total miles."

        case .hundredMiles:
            return "Log 100 total miles."

        case .twoHundredFiftyMiles:
            return "Log 250 total miles."

        case .fiveHundredMiles:
            return "Log 500 total miles."

        case .thousandMiles:
            return "Log 1,000 total miles."

        case .firstGoal:
            return "Complete your first scheduled goal."

        case .fiveGoals:
            return "Complete 5 goals."

        case .tenGoals:
            return "Complete 10 goals."

        case .twentyFiveGoals:
            return "Complete 25 goals."

        case .fiftyGoals:
            return "Complete 50 goals."

        case .hundredGoals:
            return "Complete 100 goals."

        case .overAchiever:
            return "Beat a workout goal by at least 25%."

        case .doubleGoal:
            return "Complete at least twice your workout goal."
        }
    }
}

extension Achievement {
    var systemImage: String {
        switch self {
        case .firstWorkout:
            return "figure.run"

        case .fiveK:
            return "bolt.fill"

        case .tenK:
            return "flame.fill"

        case .halfMarathon:
            return "mountain.2.fill"

        case .marathon:
            return "trophy.fill"

        case .fiveWorkouts,
             .tenWorkouts,
             .twentyFiveWorkouts,
             .fiftyWorkouts,
             .hundredWorkouts:
            return "figure.run.circle.fill"

        case .twentyFiveMiles,
             .fiftyMiles,
             .hundredMiles,
             .twoHundredFiftyMiles,
             .fiveHundredMiles,
             .thousandMiles:
            return "road.lanes"

        case .firstGoal,
             .fiveGoals,
             .tenGoals,
             .twentyFiveGoals,
             .fiftyGoals,
             .hundredGoals:
            return "target"

        case .overAchiever:
            return "arrow.up.right.circle.fill"

        case .doubleGoal:
            return "2.circle.fill"
        }
    }
}

extension Achievement {
    var badgeAsset: String {
        switch self {
        case .firstWorkout:
            return "achievement_first_workout"

        case .fiveK:
            return "achievement_5k"

        case .tenK:
            return "achievement_10k"

        case .halfMarathon:
            return "achievement_half_marathon"

        case .marathon:
            return "achievement_marathon"

        case .fiveWorkouts:
            return "achievement_5_workouts"

        case .tenWorkouts:
            return "achievement_10_workouts"

        case .twentyFiveWorkouts:
            return "achievement_25_workouts"

        case .fiftyWorkouts:
            return "achievement_50_workouts"

        case .hundredWorkouts:
            return "achievement_100_workouts"

        case .twentyFiveMiles:
            return "achievement_25_miles"

        case .fiftyMiles:
            return "achievement_50_miles"

        case .hundredMiles:
            return "achievement_100_miles"

        case .twoHundredFiftyMiles:
            return "achievement_250_miles"

        case .fiveHundredMiles:
            return "achievement_500_miles"

        case .thousandMiles:
            return "achievement_1000_miles"

        case .firstGoal:
            return "achievement_first_goal"

        case .fiveGoals:
            return "achievement_5_goals"

        case .tenGoals:
            return "achievement_10_goals"

        case .twentyFiveGoals:
            return "achievement_25_goals"

        case .fiftyGoals:
            return "achievement_50_goals"

        case .hundredGoals:
            return "achievement_100_goals"

        case .overAchiever:
            return "achievement_overachiever"

        case .doubleGoal:
            return "achievement_double_goal"
        }
    }
}

extension Achievement {

    var progression: [Achievement] {
        switch self {

        // Single-workout distance
        case .fiveK,
             .tenK,
             .halfMarathon,
             .marathon:
            return [
                .fiveK,
                .tenK,
                .halfMarathon,
                .marathon
            ]

        // Workout count
        case .firstWorkout,
             .fiveWorkouts,
             .tenWorkouts,
             .twentyFiveWorkouts,
             .fiftyWorkouts,
             .hundredWorkouts:
            return [
                .firstWorkout,
                .fiveWorkouts,
                .tenWorkouts,
                .twentyFiveWorkouts,
                .fiftyWorkouts,
                .hundredWorkouts
            ]

        // Lifetime mileage
        case .twentyFiveMiles,
             .fiftyMiles,
             .hundredMiles,
             .twoHundredFiftyMiles,
             .fiveHundredMiles,
             .thousandMiles:
            return [
                .twentyFiveMiles,
                .fiftyMiles,
                .hundredMiles,
                .twoHundredFiftyMiles,
                .fiveHundredMiles,
                .thousandMiles
            ]

        // Completed goals
        case .firstGoal,
             .fiveGoals,
             .tenGoals,
             .twentyFiveGoals,
             .fiftyGoals,
             .hundredGoals:
            return [
                .firstGoal,
                .fiveGoals,
                .tenGoals,
                .twentyFiveGoals,
                .fiftyGoals,
                .hundredGoals
            ]

        // Standalone performance awards
        case .overAchiever:
            return [.overAchiever]

        case .doubleGoal:
            return [.doubleGoal]
        }
    }
}
