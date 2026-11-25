//
//  MacRelayAlert.swift
//  NinjaPaceMac
//
//  Created by Kevin Montemayor on 6/4/26.
//

import Foundation

enum MacRelayAlert: Identifiable, Equatable {

    case relayStartFailed
    case relayStoppedUnexpectedly
    case overlayUnavailable

    var id: String {
        switch self {

        case .relayStartFailed:
            return "relayStartFailed"

        case .relayStoppedUnexpectedly:
            return "relayStoppedUnexpectedly"

        case .overlayUnavailable:
            return "overlayUnavailable"
        }
    }

    var title: String {
        switch self {

        case .relayStartFailed:
            return "Relay Couldn’t Start"

        case .relayStoppedUnexpectedly:
            return "Relay Stopped"

        case .overlayUnavailable:
            return "Streaming HUD Unavailable"
        }
    }

    var message: String {
        switch self {

        case .relayStartFailed:
            return "NinjaPace couldn’t start its local relay. Close any other NinjaPace instances and try again."

        case .relayStoppedUnexpectedly:
            return "The NinjaPace relay stopped unexpectedly. Restart it from Relay Controls."

        case .overlayUnavailable:
            return "NinjaPace couldn’t load the streaming HUD. Please restart the app. If the problem continues, reinstall NinjaPace."
        }
    }
}
