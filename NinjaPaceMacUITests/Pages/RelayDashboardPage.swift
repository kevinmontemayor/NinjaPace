import XCTest

@MainActor
final class RelayDashboardPage: MacUITestPage {
    var themeName: XCUIElement { app.staticTexts["themeName"] }
    var relayStatus: XCUIElement { app.staticTexts["relayStatus"] }
    var workoutStatus: XCUIElement { app.staticTexts["workoutStatus"] }
    var obsURL: XCUIElement { app.staticTexts["obsURL"] }
    var startButton: XCUIElement { app.buttons["startRelayButton"] }
    var stopButton: XCUIElement { app.buttons["stopRelayButton"] }
    var copyURLButton: XCUIElement { app.buttons["copyOBSURLButton"] }
    var telemetry: RelayTelemetrySection { RelayTelemetrySection(app: app) }

    func stopRelay(file: StaticString = #filePath, line: UInt = #line) {
        tap(stopButton, file: file, line: line)
    }

    func openHUDStudio(file: StaticString = #filePath, line: UInt = #line) -> HUDStudioPage {
        tap(app.buttons["customizeHUDButton"], file: file, line: line)
        return HUDStudioPage(app: app)
    }
}
