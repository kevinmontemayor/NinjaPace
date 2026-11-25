//
//  WatchIdleClockUITests.swift
//  NinjaPaceWatchUITests
//
//  Created by Kevin Montemayor on 11/23/26.
//

import XCTest

@MainActor
final class WatchIdleClockUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func idle(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["idleWarriorClock"].firstMatch
    }

    private func dismissIdle(_ app: XCUIApplication) {
        let clock = idle(app)
        XCTAssertTrue(clock.waitForExistence(timeout: 5), "Idle Warrior Clock did not appear.")
        clock.tap()
        XCTAssertTrue(clock.waitUntilAbsent(timeout: 5), "Idle Warrior Clock did not dismiss.")
        XCTAssertTrue(app.staticTexts["homeThemeTitle"].waitForExistence(timeout: 5), "Warrior Home did not appear after dismissing idle clock.")
    }

    func testIdleDisplaysSyncedProgressionAcrossThemesAndClockStyles() {
        let cases = [("ninja", "1", "digital", "Shinobi"),
                     ("ninja", "4", "digital", "Tatsujin"),
                     ("viking", "4", "analog", "Jarl"),
                     ("cyborg", "3", "digital", "Vanguard"),
                     ("pirate", "3", "analog", "Captain")]
        for (theme, level, style, _) in cases {
            let app = NinjaPaceWatchTestApp.configured(in: .ready)
            app.launchEnvironment["NINJAPACE_UI_TEST_THEME"] = theme
            app.launchEnvironment["NINJAPACE_UI_TEST_WARRIOR_LEVEL"] = level
            app.launchEnvironment["NINJAPACE_UI_TEST_CLOCK_STYLE"] = style
            app.launch()
            XCTAssertTrue(idle(app).waitForExistence(timeout: 5))
            XCTAssertTrue(app.descendants(matching: .any)[style == "digital" ? "idleClockDigital" : "idleClockAnalog"].firstMatch.exists)
            XCTAssertEqual(app.images["idleWarriorArtwork"].value as? String, theme + "_lvl" + level)
            XCTAssertFalse(app.buttons["primaryWorkoutButton"].isHittable)
            XCTAssertFalse(app.buttons["dashboardSettingsButton"].isHittable)
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "Idle — " + theme + " — " + level + " — " + style
            shot.lifetime = .keepAlways
            add(shot)
            app.terminate()
        }
    }

    func testDisabledAndWorkoutStatesNeverShowIdleClock() {
        for state in [NinjaPaceWatchTestApp.LaunchState.ready, .live, .paused] {
            let app = NinjaPaceWatchTestApp.configured(in: state)
            if state == .ready { app.launchEnvironment["NINJAPACE_UI_TEST_SHOW_TIME"] = "0" }
            app.launch()
            XCTAssertTrue(app.staticTexts["workoutStatus"].waitForExistence(timeout: 5))
            XCTAssertFalse(idle(app).exists)
            XCTAssertTrue(app.staticTexts["homeThemeTitle"].exists)
            app.swipeDown()
            XCUIDevice.shared.rotateDigitalCrown(delta: -1.0)
            XCTAssertFalse(idle(app).exists, "Scrolling must not bypass workout/setting eligibility.")
            XCTAssertEqual(app.staticTexts["workoutStatus"].label, state.rawValue.uppercased())
            app.terminate()
        }
    }

    func testIdleClockDoesNotCoverOtherDashboardPages() {
        for (page, title) in [("overview", "overviewTitle"), ("distance", "focusTitle.distance"), ("controls", "controlsTitle")] {
            let app = NinjaPaceWatchTestApp.configured(in: .ready)
            app.launchEnvironment["NINJAPACE_UI_TEST_PAGE"] = page
            app.launch()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
            XCTAssertFalse(idle(app).exists)
            app.terminate()
        }
    }

    func testDismissalLastsUntilWorkoutCompletes() {
        let app = NinjaPaceWatchTestApp.configured(in: .ready)
        app.launch()
        dismissIdle(app)
        let reappeared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: idle(app))
        reappeared.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [reappeared], timeout: 2), .completed)
        let workout = WorkoutPage(app: app)
        XCTAssertEqual(workout.primaryButton.label, "Start")
        workout.primaryButton.tap()
        XCTAssertTrue(workout.status.waitForLabel("LIVE"))
        XCTAssertFalse(idle(app).exists)
        _ = workout.requestStop().confirm()
        XCTAssertTrue(idle(app).waitForExistence(timeout: 5), "Idle clock should return after the workout completes.")
        dismissIdle(app)
        XCTAssertTrue(workout.status.waitForLabel("READY"), "Ready dashboard did not appear after dismissing idle clock.")
    }

    func testClockStylePersistsAndSettingsNeverGetCovered() {
        let app = NinjaPaceWatchTestApp.configured(in: .ready)
        app.launch()
        for style in ["analog", "digital"] {
            dismissIdle(app)
            let settings = DashboardSettingsPage(app: app)
            settings.open()
            XCTAssertFalse(idle(app).exists)
            settings.chooseClockStyle(style)
            XCTAssertFalse(idle(app).exists)
            settings.done()
            let clockID = style == "analog" ? "idleClockAnalog" : "idleClockDigital"
            XCTAssertTrue(app.descendants(matching: .any)[clockID].firstMatch.waitForExistence(timeout: 5))
            app.terminate()
            app.launchEnvironment["NINJAPACE_UI_TEST_RESET_DASHBOARD"] = "0"
            app.launch()
            XCTAssertTrue(idle(app).waitForExistence(timeout: 5))
            XCTAssertTrue(app.descendants(matching: .any)[clockID].firstMatch.exists)
        }
    }

    func testEnablingClockRearmsOnlyAfterSettingsClose() {
        let app = NinjaPaceWatchTestApp.configured(in: .ready)
        app.launch()
        dismissIdle(app)
        let settings = DashboardSettingsPage(app: app)
        settings.open()
        settings.setClockVisible(false)
        XCTAssertFalse(app.buttons["idleClockStylePicker"].exists)
        settings.done()
        XCTAssertFalse(idle(app).exists)
        settings.open()
        settings.setClockVisible(true)
        XCTAssertTrue(app.buttons["idleClockStylePicker"].exists)
        XCTAssertFalse(idle(app).exists)
        settings.done()
        XCTAssertTrue(idle(app).waitForExistence(timeout: 5))
    }

    func testIdleReturnsAfterSixtySecondsWithoutInteraction() {
        let app = NinjaPaceWatchTestApp.configured(in: .ready)
        app.launch()
        dismissIdle(app)
        let dismissedAt = Date()
        XCTAssertTrue(idle(app).waitForExistence(timeout: 65))
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(dismissedAt), 57,
                                    "The clock returned before the 60-second idle timeout.")
    }

    func testTouchRestartsIdleCountdown() {
        let app = NinjaPaceWatchTestApp.configured(in: .ready)
        app.launchEnvironment["NINJAPACE_UI_TEST_IDLE_TIMEOUT"] = "10"
        app.launch()
        dismissIdle(app)
        assertStaysDismissed(app, seconds: 5)
        app.images["warriorArtwork"].tap()
        // Cross the original deadline, but not the new deadline after the tap.
        assertStaysDismissed(app, seconds: 6)
        XCTAssertTrue(idle(app).waitForExistence(timeout: 8))
    }

    func testScrollAboveHomeReturnsToIdleWithTouchAndCrown() {
        let app = NinjaPaceWatchTestApp.configured(in: .ready)
        app.launch()
        dismissIdle(app)
        app.swipeDown()
        XCTAssertTrue(idle(app).waitForExistence(timeout: 5))
        dismissIdle(app)
        for _ in 0..<2 {
            // A full native page turn; partial turns settle back on Home.
            XCUIDevice.shared.rotateDigitalCrown(delta: -1.0)
            if idle(app).exists { break }
        }
        XCTAssertTrue(idle(app).waitForExistence(timeout: 5))
    }

    func testTimeoutReturnsFromAnyDashboardPageToIdle() {
        for (page, title) in [("overview", "overviewTitle"), ("distance", "focusTitle.distance"), ("controls", "controlsTitle")] {
            let app = NinjaPaceWatchTestApp.configured(in: .ready)
            app.launchEnvironment["NINJAPACE_UI_TEST_PAGE"] = page
            app.launchEnvironment["NINJAPACE_UI_TEST_IDLE_TIMEOUT"] = "5"
            app.launch()
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
            XCTAssertTrue(idle(app).waitForExistence(timeout: 10))
            dismissIdle(app)
            XCTAssertTrue(app.staticTexts["homeThemeTitle"].exists)
            app.terminate()
        }
    }

    func testInteractionOnOverviewRestartsCountdown() {
        let app = NinjaPaceWatchTestApp.configured(in: .ready)
        app.launchEnvironment["NINJAPACE_UI_TEST_PAGE"] = "overview"
        app.launchEnvironment["NINJAPACE_UI_TEST_IDLE_TIMEOUT"] = "10"
        app.launch()
        XCTAssertTrue(app.staticTexts["overviewTitle"].waitForExistence(timeout: 5))
        assertStaysDismissed(app, seconds: 4)
        app.staticTexts["elapsedMetric"].tap()
        assertStaysDismissed(app, seconds: 6)
        XCTAssertTrue(idle(app).waitForExistence(timeout: 8))
    }

    func testTimeoutClosesDashboardSettingsAndReturnsToIdle() {
        let app = NinjaPaceWatchTestApp.configured(in: .ready)
        app.launchEnvironment["NINJAPACE_UI_TEST_IDLE_TIMEOUT"] = "8"
        app.launch()
        dismissIdle(app)
        DashboardSettingsPage(app: app).open()
        XCTAssertTrue(idle(app).waitForExistence(timeout: 12))
        XCTAssertTrue(app.navigationBars["Dashboard"].waitUntilAbsent(), "Settings did not finish dismissing.")
        dismissIdle(app)
        XCTAssertTrue(app.staticTexts["homeThemeTitle"].exists)
    }

    func testPickerInteractionResetsCountdownBeforeReturningToIdle() {
        let app = NinjaPaceWatchTestApp.configured(in: .ready)
        app.launchEnvironment["NINJAPACE_UI_TEST_IDLE_TIMEOUT"] = "10"
        app.launch()
        dismissIdle(app)
        DashboardSettingsPage(app: app).open()
        app.buttons["chooseWarriorButton"].tap()
        XCTAssertTrue(app.buttons["warriorChoice.ninja"].waitForExistence(timeout: 3))
        assertStaysDismissed(app, seconds: 4)
        app.buttons["warriorChoice.ninja"].tap()
        assertStaysDismissed(app, seconds: 6)
        XCTAssertTrue(idle(app).waitForExistence(timeout: 8))
        XCTAssertTrue(app.navigationBars["Choose Warrior"].waitUntilAbsent(), "Warrior picker did not finish dismissing.")
    }

    func testCrownScrollingInSettingsRestartsCountdown() {
        let app = NinjaPaceWatchTestApp.configured(in: .ready)
        app.launchEnvironment["NINJAPACE_UI_TEST_IDLE_TIMEOUT"] = "14"
        app.launch()
        dismissIdle(app)
        DashboardSettingsPage(app: app).open()
        assertStaysDismissed(app, seconds: 5)
        XCUIDevice.shared.rotateDigitalCrown(delta: 0.15)
        XCTAssertTrue(app.navigationBars["Dashboard"].exists)
        assertStaysDismissed(app, seconds: 7)
        XCTAssertTrue(idle(app).waitForExistence(timeout: 12))
        XCTAssertTrue(app.navigationBars["Dashboard"].waitUntilAbsent(), "Settings did not finish dismissing.")
    }

    private func assertStaysDismissed(_ app: XCUIApplication, seconds: TimeInterval) {
        let appeared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: idle(app))
        appeared.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [appeared], timeout: seconds), .completed)
    }

}
