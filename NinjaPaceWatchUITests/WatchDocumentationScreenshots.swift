import XCTest

/// Run this capture case alone when refreshing the GitHub Watch gallery.
@MainActor
final class WatchDocumentationScreenshots: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testCaptureWatchV2Gallery() {
        for theme in ["ninja", "viking", "knight", "pirate", "cyborg", "spartan"] {
            let app = NinjaPaceWatchTestApp.configured(in: .live)
            app.launchEnvironment["NINJAPACE_UI_TEST_THEME"] = theme
            app.launchEnvironment["NINJAPACE_UI_TEST_WARRIOR_LEVEL"] = "4"
            app.launch()
            XCTAssertTrue(app.staticTexts["homeThemeTitle"].waitForExistence(timeout: 5))
            capture("watch-v2-home-" + theme, app: app)

            if theme == "ninja" {
                let workout = WorkoutPage(app: app)
                workout.showOverview()
                capture("watch-v2-overview", app: app)
                workout.pageForward(to: "focusTitle.distance")
                capture("watch-v2-distance", app: app)
                workout.pageForward(to: "focusTitle.heartRate")
                capture("watch-v2-heart-rate", app: app)
                workout.showControls()
                capture("watch-v2-controls", app: app)
            }

            if theme == "cyborg" {
                DashboardSettingsPage(app: app).open()
                capture("watch-v2-settings", app: app)
                app.buttons["chooseWarriorButton"].tap()
                XCTAssertTrue(app.buttons["warriorChoice.ninja"].waitForExistence(timeout: 3))
                capture("watch-v2-warrior-picker", app: app)
            }
            app.terminate()
        }

        for state in [NinjaPaceWatchTestApp.LaunchState.ready, .paused] {
            let app = NinjaPaceWatchTestApp.configured(in: state)
            app.launchEnvironment["NINJAPACE_UI_TEST_WARRIOR_LEVEL"] = "4"
            app.launch()
            let workout = WorkoutPage(app: app)
            if state == .ready { workout.dismissIdleClock() }
            XCTAssertTrue(app.staticTexts["homeThemeTitle"].waitForExistence(timeout: 5))
            capture("watch-v2-home-" + state.rawValue, app: app)
            app.terminate()
        }
    }

    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
