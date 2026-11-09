//
//  NinjaPaceTestApp.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 2/4/26.
//

import XCTest

@MainActor
enum NinjaPaceTestApp {
    enum LaunchState: String {
        case welcome, ready, live
    }

    /// Configuration only, so launch performance measurements contain no page waits.
    static func configured(in state: LaunchState, seededHistory: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["NINJAPACE_IPHONE_UI_TEST_STATE"] = state.rawValue
        
        if seededHistory {
            app.launchEnvironment["NINJAPACE_SCREENSHOT_DATA"] = "1"
        }
        
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        return app
    }

    static func launchWelcome() -> WelcomePage {
        let app = configured(in: .welcome)
        app.launch()
        return WelcomePage(app: app)
    }

    static func launchTraining(live: Bool = false, seededHistory: Bool = false) -> TrainingHomePage {
        let app = configured(in: live ? .live : .ready, seededHistory: seededHistory)
        app.launch()
        return TrainingHomePage(app: app)
    }
}
