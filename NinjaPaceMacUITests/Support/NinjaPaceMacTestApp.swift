import XCTest

@MainActor
enum NinjaPaceMacTestApp {
    enum LaunchState: String {
        case offline, waiting, live
    }

    /// Configuration only, keeping page waits outside launch measurements.
    static func configured(in state: LaunchState) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["NINJAPACE_MAC_UI_TEST_STATE"] = state.rawValue
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        return app
    }

    static func launch(in state: LaunchState) -> RelayDashboardPage {
        let app = configured(in: state)
        app.launch()
        return RelayDashboardPage(app: app)
    }
}
