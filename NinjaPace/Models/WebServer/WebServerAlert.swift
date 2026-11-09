//
//  WebServerAlert.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 6/3/26.
//

import Foundation

enum WebServerAlert: Identifiable {

    case serverStartFailed
    case serverStoppedUnexpectedly

    var id: String {
        switch self {
        case .serverStartFailed:
            return "serverStartFailed"
            
        case .serverStoppedUnexpectedly:
            return "serverStoppedUnexpectedly"
        }
    }

    var title: String {
        switch self {
        case .serverStartFailed:
            return "Streaming Server Unavailable"
            
        case .serverStoppedUnexpectedly:
            return "Streaming Server Stopped"
        }
    }

    var message: String {
        switch self {
        case .serverStartFailed:
            return "NinjaPace couldn’t start its local streaming server. Make sure local network access is allowed and try again."
            
        case .serverStoppedUnexpectedly:
            return "The NinjaPace streaming server stopped unexpectedly. You can restart it from Server Controls."
        }
    }
}
