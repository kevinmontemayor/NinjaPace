//
//  NinjaPaceMacUITests.swift
//  NinjaPaceMacUITests
//
//  Created by Kevin Montemayor on 10/6/26.
//

import XCTest

final class NinjaPaceMacUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOfflineStateShowsReadyDashboard() {
        let dashboard = launch(in: .offline)
        XCTAssertEqual(dashboard.relayStatus.textValue, "OFFLINE")
        XCTAssertEqual(dashboard.workoutStatus.textValue, "WAITING")
        XCTAssertEqual(dashboard.obsURL.textValue, "Relay not running")
        XCTAssertTrue(dashboard.startButton.isEnabled)
        XCTAssertFalse(dashboard.stopButton.isEnabled)
        XCTAssertFalse(dashboard.copyURLButton.exists)
    }

    @MainActor
    func testWaitingStateShowsOnlineRelayWithoutActiveWorkout() {
        let dashboard = launch(in: .waiting)
        XCTAssertEqual(dashboard.relayStatus.textValue, "ONLINE")
        XCTAssertEqual(dashboard.workoutStatus.textValue, "WAITING")
        XCTAssertEqual(dashboard.obsURL.textValue, "http://localhost:8787/")
        XCTAssertFalse(dashboard.startButton.isEnabled)
        XCTAssertTrue(dashboard.stopButton.isEnabled)
        XCTAssertTrue(dashboard.copyURLButton.exists)
    }

    @MainActor
    func testLiveStateShowsTelemetry() {
        let dashboard = launch(in: .live)
        XCTAssertEqual(dashboard.themeName.textValue, "Ninja")
        XCTAssertEqual(dashboard.relayStatus.textValue, "ONLINE")
        XCTAssertEqual(dashboard.workoutStatus.textValue, "WORKOUT ACTIVE")

        let telemetry = dashboard.telemetry
        XCTAssertEqual(telemetry.miles.textValue, "3.14")
        XCTAssertEqual(telemetry.steps.textValue, "6,240")
        XCTAssertEqual(telemetry.heartRate.textValue, "142 bpm")
        XCTAssertEqual(telemetry.elapsed.textValue, "00:28:10.00")
        XCTAssertEqual(telemetry.goal.textValue, "5.00 mi")
        XCTAssertEqual(telemetry.progress.textValue, "63%")
    }

    @MainActor
    func testStopRelayReturnsDashboardOffline() {
        let dashboard = launch(in: .waiting)
        dashboard.stopRelay()

        XCTAssertTrue(dashboard.relayStatus.waitForText("OFFLINE"), "Relay did not transition to OFFLINE.")
        XCTAssertEqual(dashboard.obsURL.textValue, "Relay not running")
        XCTAssertTrue(dashboard.startButton.isEnabled)
        XCTAssertFalse(dashboard.stopButton.isEnabled)
        XCTAssertFalse(dashboard.copyURLButton.exists)
    }

    @MainActor
    func testHUDStudioWindowOpens() {
        let studio = launch(in: .waiting).openHUDStudio()
        XCTAssertTrue(studio.marker.waitForExistence(timeout: 3), "HUD Studio window did not open.")
    }

    @MainActor
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = NinjaPaceMacTestApp.configured(in: .offline)
            app.launch()
            app.terminate()
        }
    }

    @MainActor
    private func launch(in state: NinjaPaceMacTestApp.LaunchState,
                        file: StaticString = #filePath, line: UInt = #line) -> RelayDashboardPage {
        let page = NinjaPaceMacTestApp.launch(in: state)
        XCTAssertTrue(page.relayStatus.waitForExistence(timeout: 5),
                      "NinjaPaceMac did not reach its initial \(state.rawValue) UI state.",
                      file: file, line: line)
        return page
    }
}
