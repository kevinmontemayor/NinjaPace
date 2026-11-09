//
//  RelayBackgroundDelivery.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/21/26.
//

#if os(iOS)
import UIKit

/// A finite execution allowance for one telemetry upload. Expiration releases it
/// even when the relay is unreachable; ending twice is harmless.
@MainActor
final class RelayBackgroundDelivery {
    private var identifier: UIBackgroundTaskIdentifier = .invalid

    init() {
        identifier = UIApplication.shared.beginBackgroundTask(withName: "Relay telemetry") { [weak self] in
            self?.end()
        }

    }

    func end() {
        guard identifier != .invalid else { return }
        UIApplication.shared.endBackgroundTask(identifier)
        identifier = .invalid
    }
}
#endif
