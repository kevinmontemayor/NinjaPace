//
//  WatchTelemetryOrder.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/21/26.
//

import Foundation

/// All delivery paths carry the same timestamp for a given Watch snapshot.
struct WatchTelemetryOrder {
    private var latestSentAt: TimeInterval?

    mutating func accept(sentAt: TimeInterval?) -> Bool {
        // Preserve compatibility with older Watch payloads without timestamps.
        guard let sentAt else { return true }
        guard sentAt.isFinite else { return false }
        if let latestSentAt, sentAt <= latestSentAt { return false }
        latestSentAt = sentAt
        return true
    }
}
