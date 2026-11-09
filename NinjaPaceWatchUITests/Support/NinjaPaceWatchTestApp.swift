import XCTest

@MainActor
enum NinjaPaceWatchTestApp {
    enum LaunchState: String {
        case ready, live, paused
    }

    static func configured(in state: LaunchState) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["NINJAPACE_UI_TEST_STATE"] = state.rawValue
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        return app
    }

    static func launch(in state: LaunchState) -> WorkoutPage {
        let app = configured(in: state)
        app.launch()
        return WorkoutPage(app: app)
    }
}
