//
//  HealthStreamAlert.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 6/3/26.
//

import Foundation

enum HealthStreamAlert: Identifiable {
    
    case healthUnavailable
    case healthAuthorizationFailed
    case watchCommunicationUnavailable
    case watchConnectionFailed
    case workoutStartFailed
    case workoutStopFailed
    case workoutSaveFailed
    case motionUnavailable
    case relayConnectionFailed
    
    var id: String {
        switch self {
        case .healthUnavailable:
            return "healthUnavailable"
            
        case .healthAuthorizationFailed:
            return "healthAuthorizationFailed"
            
        case .watchCommunicationUnavailable:
            return "watchCommunicationUnavailable"
            
        case .watchConnectionFailed:
            return "watchConnectionFailed"
            
        case .workoutStartFailed:
            return "workoutStartFailed"
            
        case .workoutStopFailed:
            return "workoutStopFailed"
            
        case .workoutSaveFailed:
            return "workoutSaveFailed"
            
        case .motionUnavailable:
            return "motionUnavailable"
            
        case .relayConnectionFailed:
            return "relayConnectionFailed"
        }
    }

    var title: String {
        switch self {
        case .healthUnavailable:
            return "Health Data Unavailable"
            
        case .healthAuthorizationFailed:
            return "Health Access Needed"
            
        case .watchCommunicationUnavailable,
             .watchConnectionFailed:
            return "Apple Watch Connection"
            
        case .workoutStartFailed:
            return "Workout Couldn’t Start"
            
        case .workoutStopFailed:
            return "Workout Couldn’t Finish"
            
        case .workoutSaveFailed:
            return "Workout Couldn’t Be Saved"
            
        case .motionUnavailable:
            return "Motion Data Unavailable"
        
        case .relayConnectionFailed:
            return "Relay Connection"
        }
    }

    var message: String {
        switch self {
        case .healthUnavailable:
            return "Health data is not available on this device."
            
        case .healthAuthorizationFailed:
            return "NinjaPace couldn’t access the Health data needed for workouts. Please review Health permissions in Settings."
            
        case .watchCommunicationUnavailable:
            return "NinjaPace couldn’t communicate with your Apple Watch. Make sure the Watch is paired and NinjaPace is installed."
            
        case .watchConnectionFailed:
            return "NinjaPace lost communication with your Apple Watch. Reopen NinjaPace on the Watch and try again."
            
        case .workoutStartFailed:
            return "NinjaPace couldn’t start the workout. Please try again."
            
        case .workoutStopFailed:
            return "NinjaPace couldn’t finish the workout normally. Your latest telemetry will remain visible."
            
        case .workoutSaveFailed:
            return "Your workout finished, but NinjaPace couldn’t save it to workout history."
            
        case .motionUnavailable:
            return "Step and distance tracking are not available from this device."
            
        case .relayConnectionFailed:
            return "NinjaPace couldn’t connect to the relay. Please check your connection and try again."
        }
    }
}
