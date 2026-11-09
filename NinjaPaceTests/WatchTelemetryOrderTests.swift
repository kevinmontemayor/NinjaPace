//
//  WatchTelemetryOrderTests.swift
//  NinjaPaceTests
//
//  Created by Kevin Montemayor on 8/21/26.
//

import Foundation
import Testing
@testable import NinjaPace

@MainActor
@Suite("Watch telemetry delivery order")
struct WatchTelemetryOrderTests {
    @Test("Live message followed by mirror and checkpoint is applied once")
    func duplicateDelivery() {
        var order = WatchTelemetryOrder()
        #expect({ order.accept(sentAt: 100) }())
        #expect({ !order.accept(sentAt: 100) }())
        #expect({ !order.accept(sentAt: 100) }())
        #expect({ order.accept(sentAt: 101) }())
    }

    @Test("Buffered mirror data cannot replace a newer live snapshot")
    func delayedBatch() {
        var order = WatchTelemetryOrder()
        #expect({ order.accept(sentAt: 200) }())
        for timestamp in [100.0, 150, 199, 200] {
            #expect({ !order.accept(sentAt: timestamp) }())
        }
        #expect({ order.accept(sentAt: 201) }())
    }

    @Test("Invalid timestamps cannot poison subsequent telemetry")
    func invalidTimestamp() {
        var order = WatchTelemetryOrder()
        #expect({ !order.accept(sentAt: .nan) }())
        #expect({ !order.accept(sentAt: .infinity) }())
        #expect({ order.accept(sentAt: 100) }())
    }

    @Test("Legacy payloads remain accepted without resetting ordering")
    func legacyPayload() {
        var order = WatchTelemetryOrder()
        #expect({ order.accept(sentAt: 100) }())
        #expect({ order.accept(sentAt: nil) }())
        #expect({ !order.accept(sentAt: 99) }())
        #expect({ order.accept(sentAt: 101) }())
    }
}
