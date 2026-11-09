//
//  NinjaPaceMacTests.swift
//  NinjaPaceMacTests
//
//  Created by Kevin Montemayor on 2/12/26.
//

import XCTest
@testable import NinjaPaceMac

final class MacRelayAlertTests: XCTestCase {

    func testAlertIDsAreUnique() {
        let alerts: [MacRelayAlert] = [
            .relayStartFailed,
            .relayStoppedUnexpectedly,
            .overlayUnavailable
        ]

        XCTAssertEqual(Set(alerts.map(\.id)).count, alerts.count)
    }

    func testAlertTitlesMatchExpectedCopy() {
        XCTAssertEqual(MacRelayAlert.relayStartFailed.title, "Relay Couldn’t Start")
        XCTAssertEqual(MacRelayAlert.relayStoppedUnexpectedly.title, "Relay Stopped")
        XCTAssertEqual(MacRelayAlert.overlayUnavailable.title, "Streaming HUD Unavailable")
    }

    func testEveryAlertHasUserFacingMessage() {
        let alerts: [MacRelayAlert] = [
            .relayStartFailed,
            .relayStoppedUnexpectedly,
            .overlayUnavailable
        ]

        for alert in alerts {
            XCTAssertFalse(alert.message.isEmpty)
        }
    }
}

final class MacHUDConfigurationModeTests: XCTestCase {

    func testAllExpectedModesExist() {
        XCTAssertEqual(
            MacHUDConfigurationMode.allCases,
            [.followIPhone, .localOverride]
        )
    }

    func testModeIDsMatchRawValues() {
        XCTAssertEqual(
            MacHUDConfigurationMode.followIPhone.id,
            MacHUDConfigurationMode.followIPhone.rawValue
        )
        XCTAssertEqual(
            MacHUDConfigurationMode.localOverride.id,
            MacHUDConfigurationMode.localOverride.rawValue
        )
    }

    func testModeDisplayNames() {
        XCTAssertEqual(MacHUDConfigurationMode.followIPhone.displayName, "Follow iPhone")
        XCTAssertEqual(MacHUDConfigurationMode.localOverride.displayName, "Customize on This Mac")
    }

    func testModeCodableRoundTrip() throws {
        for mode in MacHUDConfigurationMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(MacHUDConfigurationMode.self, from: data)

            XCTAssertEqual(decoded, mode)
        }
    }
}

final class MacRelayStatsTests: XCTestCase {

    func testZeroStatsRepresentIdleRelay() {
        let stats = MacRelayServer.Stats.zero

        XCTAssertNil(stats.theme)
        XCTAssertEqual(stats.miles, 0)
        XCTAssertEqual(stats.steps, 0)
        XCTAssertEqual(stats.hr, 0)
        XCTAssertEqual(stats.elapsed, "00:00:00")
        XCTAssertEqual(stats.elapsedSeconds, 0)
        XCTAssertEqual(stats.elapsedMilliseconds, 0)
        XCTAssertEqual(stats.pace, "—")
        XCTAssertEqual(stats.activeCalories, 0)
        XCTAssertEqual(stats.totalCalories, 0)
        XCTAssertEqual(stats.goalMiles, 3.11, accuracy: 0.0001)
        XCTAssertEqual(stats.progress, 0)
        XCTAssertFalse(stats.running)
        XCTAssertFalse(stats.paused)
        XCTAssertNil(stats.hudConfiguration)
    }

    func testStatsCodableRoundTripPreservesTelemetry() throws {
        let original = MacRelayServer.Stats(
            theme: "ninja",
            miles: 6.21,
            steps: 12_345,
            hr: 148,
            elapsed: "01:12:34.56",
            elapsedSeconds: 4_354,
            elapsedMilliseconds: 4_354_560,
            pace: "11:41",
            activeCalories: 642,
            totalCalories: 801,
            goalMiles: 13.11,
            progress: 0.4737,
            running: true,
            paused: false,
            hudConfiguration: nil
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MacRelayServer.Stats.self, from: data)

        XCTAssertEqual(decoded.theme, original.theme)
        XCTAssertEqual(decoded.miles, original.miles, accuracy: 0.0001)
        XCTAssertEqual(decoded.steps, original.steps)
        XCTAssertEqual(decoded.hr, original.hr)
        XCTAssertEqual(decoded.elapsed, original.elapsed)
        XCTAssertEqual(decoded.elapsedSeconds, original.elapsedSeconds)
        XCTAssertEqual(decoded.elapsedMilliseconds, original.elapsedMilliseconds)
        XCTAssertEqual(decoded.pace, original.pace)
        XCTAssertEqual(decoded.activeCalories, original.activeCalories, accuracy: 0.0001)
        XCTAssertEqual(decoded.totalCalories, original.totalCalories, accuracy: 0.0001)
        XCTAssertEqual(decoded.goalMiles, original.goalMiles, accuracy: 0.0001)
        XCTAssertEqual(decoded.progress, original.progress, accuracy: 0.0001)
        XCTAssertEqual(decoded.running, original.running)
        XCTAssertEqual(decoded.paused, original.paused)
        XCTAssertNil(decoded.hudConfiguration)
    }
}

final class MacRelayServerTests: XCTestCase {

    private let persistedKeys = [
        "NinjaPaceMac.lastRelayTheme",
        "NinjaPaceMac.hudConfigurationMode",
        "NinjaPaceMac.localHUDConfiguration"
    ]

    override func setUp() {
        super.setUp()
        clearRelayDefaults()
    }

    override func tearDown() {
        clearRelayDefaults()
        super.tearDown()
    }

    @MainActor
    func testFreshServerStartsOffline() {
        let server = MacRelayServer()

        XCTAssertFalse(server.isRunning)
        XCTAssertNil(server.activePort)
        XCTAssertNil(server.baseURLString)
        XCTAssertNil(server.userAlert)
    }

    @MainActor
    func testFreshServerFollowsIPhoneHUDByDefault() {
        let server = MacRelayServer()

        XCTAssertEqual(server.hudConfigurationMode, .followIPhone)
        XCTAssertFalse(server.hasIncomingHUDConfiguration)
        XCTAssertEqual(server.effectiveHUDConfiguration, .default)
    }

    @MainActor
    func testBeginningLocalCustomizationUsesDefaultWithoutIncomingConfiguration() {
        let server = MacRelayServer()

        server.beginLocalHUDCustomization()

        XCTAssertEqual(server.hudConfigurationMode, .localOverride)
        XCTAssertEqual(server.localHUDConfiguration, .default)
        XCTAssertEqual(server.effectiveHUDConfiguration, .default)
    }

    @MainActor
    func testLocalHUDConfigurationPersistsAcrossServerInstances() {
        let server = MacRelayServer()
        var configuration = HUDConfiguration.default
        configuration.title = "Mac Test HUD"
        configuration.borderWidth = 4.5
        configuration.showSteps = false

        server.localHUDConfiguration = configuration
        server.beginLocalHUDCustomization()

        let restored = MacRelayServer()

        XCTAssertEqual(restored.hudConfigurationMode, .localOverride)
        XCTAssertEqual(restored.localHUDConfiguration, configuration)
        XCTAssertEqual(restored.effectiveHUDConfiguration, configuration)
    }

    @MainActor
    func testFollowIPhoneModePersistsAcrossServerInstances() {
        let server = MacRelayServer()
        server.beginLocalHUDCustomization()
        server.followIPhoneHUDConfiguration()

        let restored = MacRelayServer()

        XCTAssertEqual(restored.hudConfigurationMode, .followIPhone)
        XCTAssertEqual(restored.effectiveHUDConfiguration, .default)
    }

    private func clearRelayDefaults() {
        for key in persistedKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
