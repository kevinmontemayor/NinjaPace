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

        // READY now launches into the Idle Warrior Clock when Current Time is enabled.
        XCTAssertTrue(workout.idleClock.exists)
        XCTAssertTrue(workout.app.descendants(matching: .any)["homeClock"].firstMatch.exists)
        XCTAssertTrue(workout.idleArtwork.exists)

        workout.dismissIdleClock()

        XCTAssertEqual(workout.status.label, "READY")
        XCTAssertEqual(workout.primaryButton.label, "Start")

        XCTAssertTrue(workout.artwork.exists)

        XCTAssertGreaterThan(
            workout.artwork.frame.height,
            30,
            "Artwork must not collapse on a small Watch."
        )

        XCTAssertTrue(
            workout.app.frame.contains(workout.primaryButton.frame)
        )

        XCTAssertTrue(
            workout.app.staticTexts["homeThemeTitle"].exists
        )

        workout.showOverview()

        let metrics = workout.metrics

        XCTAssertTrue(metrics.elapsedTitle.exists)
        XCTAssertTrue(metrics.paceTitle.exists)
        XCTAssertTrue(metrics.heartRateTitle.exists)
        XCTAssertTrue(metrics.caloriesTitle.exists)
        XCTAssertTrue(metrics.stepsTitle.exists)
        XCTAssertTrue(metrics.goalTitle.exists)

        workout.showControls()

        XCTAssertTrue(
            workout.stopButton.waitForExistence(timeout: 3),
            "Stop button did not appear on Controls."
        )

        XCTAssertFalse(workout.stopButton.isEnabled)
    }

    @MainActor
    func testLiveStateShowsWorkoutMetrics() {
        let workout = launch(in: .live)
        XCTAssertEqual(workout.status.label, "LIVE")
        XCTAssertEqual(workout.primaryButton.label, "Pause")

        workout.showOverview()
        let metrics = workout.metrics
        XCTAssertEqual(metrics.elapsed.label, "00:28:10")
        XCTAssertEqual(metrics.pace.label, "8:58")
        XCTAssertEqual(metrics.heartRate.label, "142 bpm")
        XCTAssertEqual(metrics.calories.label, "418 kcal")
        XCTAssertEqual(metrics.steps.label, "6,240")
        XCTAssertEqual(metrics.goal.label, "3.14 / 5.00")
        workout.showControls()
        XCTAssertTrue(workout.stopButton.isEnabled)
    }

    @MainActor
    func testPausedStateShowsResume() {
        let workout = launch(in: .paused)
        XCTAssertEqual(workout.status.label, "PAUSED")
        XCTAssertEqual(workout.primaryButton.label, "Resume")
        workout.showControls()
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

        XCTAssertTrue(
            confirmation.cancelButton.waitForExistence(timeout: 3),
            "Stop confirmation did not appear."
        )

        let workout = confirmation.cancel()

        XCTAssertTrue(
            workout.status.waitForLabel("LIVE"),
            "Cancelling Stop did not preserve the live workout."
        )

        workout.showControls()

        XCTAssertTrue(
            workout.stopButton.waitForExistence(timeout: 3),
            "Stop button did not return after cancelling Stop."
        )

        XCTAssertTrue(workout.stopButton.isEnabled)
    }

    @MainActor
    func testStopReturnsWorkoutToReadyState() {
        let confirmation = launch(in: .live).requestStop()

        XCTAssertTrue(
            confirmation.cancelButton.waitForExistence(timeout: 3),
            "Stop confirmation did not appear."
        )

        let workout = confirmation.confirm()

        XCTAssertTrue(
            workout.idleClock.waitForExistence(timeout: 5),
            "Stopping the workout did not return to the Idle Warrior Clock."
        )

        workout.dismissIdleClock()

        XCTAssertTrue(
            workout.status.waitForLabel("READY"),
            "Dismissing the idle clock did not reveal the Ready dashboard."
        )

        XCTAssertEqual(
            workout.primaryButton.label,
            "Start"
        )

        workout.showControls()

        XCTAssertTrue(
            workout.stopButton.waitForExistence(timeout: 3),
            "Stop button did not appear on the Ready Controls page."
        )

        XCTAssertFalse(workout.stopButton.isEnabled)
    }

    @MainActor
    func testDefaultFocusPagesUseNativeVerticalPaging() {
        let workout = launch(in: .live)
        workout.showOverview()
        for metric in ["distance", "pace", "heartRate", "elapsed"] {
            workout.app.swipeUp()
            XCTAssertTrue(workout.app.staticTexts["focusTitle." + metric].waitForExistence(timeout: 3))
        }
        workout.app.swipeUp()
        XCTAssertTrue(workout.app.staticTexts["controlsTitle"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testDashboardSettingsPersistAndKeepWorkoutRunning() {
        let workout = launch(in: .live)
        let settings = DashboardSettingsPage(app: workout.app)

        settings.open()

        settings.setClockVisible(false)
        settings.setOverviewVisible(false)
        settings.chooseFeaturedMetric("heartRate")
        settings.setMetric("calories", enabled: true)

        settings.done()

        XCTAssertTrue(
            workout.status.waitForLabel("LIVE"),
            "Workout did not remain LIVE after changing dashboard settings."
        )

        XCTAssertEqual(
            workout.app.staticTexts["featuredMetric"].value as? String,
            "142 BPM"
        )

        // Overview was disabled, so the first page after Home should now be Distance.
        workout.app.swipeUp()

        XCTAssertTrue(
            workout.app.staticTexts["focusTitle.distance"]
                .waitForExistence(timeout: 3),
            "Distance should follow Home when Overview is disabled."
        )

        workout.app.terminate()

        workout.app.launchEnvironment[
            "NINJAPACE_UI_TEST_RESET_DASHBOARD"
        ] = "0"

        workout.app.launch()

        XCTAssertTrue(
            workout.status.waitForExistence(timeout: 5)
        )

        XCTAssertEqual(
            workout.app.staticTexts["featuredMetric"].value as? String,
            "142 BPM"
        )

        workout.app.swipeUp()

        XCTAssertTrue(
            workout.app.staticTexts["focusTitle.distance"]
                .waitForExistence(timeout: 3)
        )

        workout.pageForward(
            to: "focusTitle.calories"
        )

        XCTAssertEqual(
            workout.app.staticTexts["caloriesMetric"].label,
            "Active Calories"
        )
    }
    @MainActor
    func testWarriorSelectionUpdatesHomeArtwork() {
        let workout = launch(in: .ready)
        workout.dismissIdleClock()
        let settings = DashboardSettingsPage(app: workout.app)
        settings.open()
        settings.chooseWarrior("viking")
        settings.done()
        XCTAssertEqual(workout.app.staticTexts["warriorRank"].label, "DRENGR")
        XCTAssertEqual(workout.artwork.label, "Viking warrior")
    }

    @MainActor
    func testRestDayDoesNotShowGoalPercentage() {
        let app = NinjaPaceWatchTestApp.configured(in: .live)
        app.launchEnvironment["NINJAPACE_UI_TEST_GOAL"] = "0"
        app.launch()
        XCTAssertTrue(app.staticTexts["restDayLabel"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.progressIndicators["goalProgress"].exists)
    }

    @MainActor
    func testCaptureSmallWatchPages() {
        // READY starts on the Idle Warrior Clock.
        let ready = launch(in: .ready)

        let idle = XCTAttachment(
            screenshot: ready.app.screenshot()
        )
        idle.name = "Idle Warrior Clock — ready"
        idle.lifetime = .keepAlways
        add(idle)

        ready.dismissIdleClock()

        let readyHome = XCTAttachment(
            screenshot: ready.app.screenshot()
        )
        readyHome.name = "Warrior Home — ready"
        readyHome.lifetime = .keepAlways
        add(readyHome)

        ready.app.terminate()

        // LIVE and PAUSED do not present the idle clock.
        for state in [
            NinjaPaceWatchTestApp.LaunchState.live,
            .paused
        ] {
            let workout = launch(in: state)

            let shot = XCTAttachment(
                screenshot: workout.app.screenshot()
            )
            shot.name = "Warrior Home — " + state.rawValue
            shot.lifetime = .keepAlways
            add(shot)

            workout.app.terminate()
        }

        let workout = launch(in: .live)

        workout.showOverview()

        let overview = XCTAttachment(
            screenshot: workout.app.screenshot()
        )
        overview.name = "Workout Overview"
        overview.lifetime = .keepAlways
        add(overview)

        workout.pageForward(
            to: "focusTitle.distance"
        )

        let distance = XCTAttachment(
            screenshot: workout.app.screenshot()
        )
        distance.name = "Distance Focus"
        distance.lifetime = .keepAlways
        add(distance)
    }

    @MainActor
    private func launch(
        in state: NinjaPaceWatchTestApp.LaunchState,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> WorkoutPage {
        let page = NinjaPaceWatchTestApp.launch(in: state)

        if state == .ready {
            XCTAssertTrue(
                page.idleClock.waitForExistence(timeout: 5),
                "NinjaPace Watch did not reach the ready Idle Warrior Clock.",
                file: file,
                line: line
            )
        } else {
            XCTAssertTrue(
                page.status.waitForExistence(timeout: 5),
                "NinjaPace Watch did not reach its initial \(state.rawValue) UI state.",
                file: file,
                line: line
            )
        }

        return page
    }
}
