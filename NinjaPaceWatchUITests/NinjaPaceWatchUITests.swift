//
//  NinjaPaceWatchUITests.swift
//  NinjaPaceWatchUITests
//
//  Created by Kevin Montemayor on 2/6/26.
//

import XCTest

final class NinjaPaceWatchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testReadyStateShowsDashboardAndDisabledStop() {
        let workout = launch(in: .ready)
        XCTAssertEqual(workout.status.label, "READY")
        XCTAssertEqual(workout.primaryButton.label, "Start")
        XCTAssertFalse(workout.stopButton.isEnabled)

        let metrics = workout.metrics
        XCTAssertTrue(metrics.elapsedTitle.exists)
        XCTAssertTrue(metrics.paceTitle.exists)
        XCTAssertTrue(metrics.heartRateTitle.exists)
        XCTAssertTrue(metrics.caloriesTitle.exists)
        XCTAssertTrue(metrics.stepsTitle.exists)
        XCTAssertTrue(metrics.goalTitle.exists)
    }

    @MainActor
    func testLiveStateShowsWorkoutMetrics() {
        let workout = launch(in: .live)
        XCTAssertEqual(workout.status.label, "LIVE")
        XCTAssertEqual(workout.primaryButton.label, "Pause")
        XCTAssertTrue(workout.stopButton.isEnabled)

        let metrics = workout.metrics
        XCTAssertEqual(metrics.elapsed.label, "00:28:10")
        XCTAssertEqual(metrics.pace.label, "8:58")
        XCTAssertEqual(metrics.heartRate.label, "142 bpm")
        XCTAssertEqual(metrics.calories.label, "418 kcal")
        XCTAssertEqual(metrics.steps.label, "6,240")
        XCTAssertEqual(metrics.goal.label, "3.14 / 5.00")
    }

    @MainActor
    func testPausedStateShowsResume() {
        let workout = launch(in: .paused)
        XCTAssertEqual(workout.status.label, "PAUSED")
        XCTAssertEqual(workout.primaryButton.label, "Resume")
        XCTAssertTrue(workout.stopButton.isEnabled)
    }

    @MainActor
    func testPauseConfirmationCanBeCancelled() {
        let confirmation = launch(in: .live).requestPause()
        XCTAssertTrue(confirmation.cancelButton.waitForExistence(timeout: 3), "Pause confirmation did not appear.")
        let workout = confirmation.cancel()
        XCTAssertTrue(workout.status.waitForLabel("LIVE"), "Cancelling Pause did not preserve the live workout.")
        XCTAssertEqual(workout.primaryButton.label, "Pause")
    }

    @MainActor
    func testPauseAndResumeFlow() {
        let confirmation = launch(in: .live).requestPause()
        XCTAssertTrue(confirmation.cancelButton.waitForExistence(timeout: 3), "Pause confirmation did not appear.")
        let workout = confirmation.confirm()
        XCTAssertTrue(workout.status.waitForLabel("PAUSED"), "Confirming Pause did not pause the workout.")
        XCTAssertEqual(workout.primaryButton.label, "Resume")

        workout.resume()
        XCTAssertTrue(workout.status.waitForLabel("LIVE"), "Resume did not return the workout to Live.")
        XCTAssertEqual(workout.primaryButton.label, "Pause")
    }

    @MainActor
    func testStopConfirmationCanBeCancelled() {
        let confirmation = launch(in: .live).requestStop()
        XCTAssertTrue(confirmation.cancelButton.waitForExistence(timeout: 3), "Stop confirmation did not appear.")
        let workout = confirmation.cancel()
        XCTAssertTrue(workout.status.waitForLabel("LIVE"), "Cancelling Stop did not preserve the live workout.")
        XCTAssertTrue(workout.stopButton.isEnabled)
    }

    @MainActor
    func testStopReturnsWorkoutToReadyState() {
        let confirmation = launch(in: .live).requestStop()
        XCTAssertTrue(confirmation.cancelButton.waitForExistence(timeout: 3), "Stop confirmation did not appear.")
        let workout = confirmation.confirm()
        XCTAssertTrue(workout.status.waitForLabel("READY"), "Confirming Stop did not return the workout to Ready.")
        XCTAssertEqual(workout.primaryButton.label, "Start")
        XCTAssertFalse(workout.stopButton.isEnabled)
    }

    @MainActor
    private func launch(in state: NinjaPaceWatchTestApp.LaunchState,
                        file: StaticString = #filePath, line: UInt = #line) -> WorkoutPage {
        let page = NinjaPaceWatchTestApp.launch(in: state)
        XCTAssertTrue(page.status.waitForExistence(timeout: 5),
                      "NinjaPace Watch did not reach its initial \(state.rawValue) UI state.",
                      file: file, line: line)
        return page
    }
}
