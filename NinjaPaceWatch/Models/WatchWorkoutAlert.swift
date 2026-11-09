//
//  WatchWorkoutAlert.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 6/4/26.
//

import Foundation

enum WatchWorkoutAlert: Identifiable, Equatable {

    case healthUnavailable
    case healthAuthorizationFailed
    case workoutStartFailed
    case workoutFinishFailed
    case workoutInterrupted

    var id: String {
        switch self {
        case .healthUnavailable:
            return "healthUnavailable"

        case .healthAuthorizationFailed:
            return "healthAuthorizationFailed"

        case .workoutStartFailed:
            return "workoutStartFailed"

        case .workoutFinishFailed:
            return "workoutFinishFailed"

        case .workoutInterrupted:
            return "workoutInterrupted"
        }
    }

    var title: String {
        switch self {
        case .healthUnavailable:
            return "Health Unavailable"

        case .healthAuthorizationFailed:
            return "Health Access Needed"

        case .workoutStartFailed:
            return "Workout Couldn’t Start"

        case .workoutFinishFailed:
            return "Workout Couldn’t Finish"

        case .workoutInterrupted:
            return "Workout Interrupted"
        }
    }

    var message: String {
        switch self {
        case .healthUnavailable:
            return "Health data is not available on this Apple Watch."

        case .healthAuthorizationFailed:
            return "NinjaPace needs Health access to track your workout."

        case .workoutStartFailed:
            return "NinjaPace couldn’t start the workout. Please try again."

        case .workoutFinishFailed:
            return "NinjaPace couldn’t finish saving the workout normally."

        case .workoutInterrupted:
            return "The workout session ended unexpectedly. Please start a new workout."
        }
    }
}
