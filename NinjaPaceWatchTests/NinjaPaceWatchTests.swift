//
//  NinjaPaceWatchTests.swift
//  NinjaPaceWatchTests
//
//  Created by Kevin Montemayor on 2/6/26.
//

import XCTest
@testable import NinjaPaceWatch

final class WatchWorkoutManagerTests: XCTestCase {

    @MainActor
    func testProgressReturnsZeroForRestDayGoal() {
        let manager = WatchWorkoutManager()
        manager.goalMiles = 0
        manager.miles = 4

        XCTAssertEqual(manager.progress, 0, accuracy: 0.0001)
    }

    @MainActor
    func testProgressCalculatesFractionOfGoal() {
        let manager = WatchWorkoutManager()
        manager.goalMiles = 6
        manager.miles = 3

        XCTAssertEqual(manager.progress, 0.5, accuracy: 0.0001)
    }

    @MainActor
    func testProgressClampsAtOneAfterGoalIsExceeded() {
        let manager = WatchWorkoutManager()
        manager.goalMiles = 5
        manager.miles = 6.2

        XCTAssertEqual(manager.progress, 1, accuracy: 0.0001)
    }

    @MainActor
    func testProgressClampsAtZeroForNegativeDistance() {
        let manager = WatchWorkoutManager()
        manager.goalMiles = 5
        manager.miles = -1

        XCTAssertEqual(manager.progress, 0, accuracy: 0.0001)
    }

    @MainActor
    func testElapsedTextFormatsHoursMinutesAndSeconds() {
        let manager = WatchWorkoutManager()
        manager.elapsedSeconds = 90 * 60 + 5

        XCTAssertEqual(manager.elapsedText, "01:30:05")
    }

    @MainActor
    func testElapsedTextFormatsZero() {
        let manager = WatchWorkoutManager()
        manager.elapsedSeconds = 0

        XCTAssertEqual(manager.elapsedText, "00:00:00")
    }

    @MainActor
    func testPaceStringCalculatesMinutesPerMile() {
        let manager = WatchWorkoutManager()
        manager.miles = 3.14
        manager.elapsedSeconds = 28 * 60 + 10

        XCTAssertEqual(manager.paceString, "8:58")
    }

    @MainActor
    func testPaceStringReturnsDashWithoutEnoughDistance() {
        let manager = WatchWorkoutManager()
        manager.miles = 0.009
        manager.elapsedSeconds = 600

        XCTAssertEqual(manager.paceString, "—")
    }

    @MainActor
    func testPaceStringReturnsDashWithoutElapsedTime() {
        let manager = WatchWorkoutManager()
        manager.miles = 1
        manager.elapsedSeconds = 0

        XCTAssertEqual(manager.paceString, "—")
    }
}

final class WatchWorkoutAlertTests: XCTestCase {

    func testAlertIDsAreUnique() {
        let alerts: [WatchWorkoutAlert] = [
            .healthUnavailable,
            .healthAuthorizationFailed,
            .workoutStartFailed,
            .workoutFinishFailed,
            .workoutInterrupted
        ]

        XCTAssertEqual(Set(alerts.map(\.id)).count, alerts.count)
    }

    func testEveryAlertHasUserFacingCopy() {
        let alerts: [WatchWorkoutAlert] = [
            .healthUnavailable,
            .healthAuthorizationFailed,
            .workoutStartFailed,
            .workoutFinishFailed,
            .workoutInterrupted
        ]

        for alert in alerts {
            XCTAssertFalse(alert.title.isEmpty)
            XCTAssertFalse(alert.message.isEmpty)
        }
    }

    func testHealthUnavailableAlertCopy() {
        let alert = WatchWorkoutAlert.healthUnavailable

        XCTAssertEqual(alert.title, "Health Unavailable")
        XCTAssertEqual(alert.message, "Health data is not available on this Apple Watch.")
    }

    func testInterruptedWorkoutAlertCopy() {
        let alert = WatchWorkoutAlert.workoutInterrupted

        XCTAssertEqual(alert.title, "Workout Interrupted")
        XCTAssertEqual(
            alert.message,
            "The workout session ended unexpectedly. Please start a new workout."
        )
    }
}
