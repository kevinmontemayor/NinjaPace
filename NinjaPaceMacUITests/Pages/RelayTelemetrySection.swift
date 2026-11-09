import XCTest

@MainActor
final class RelayTelemetrySection: MacUITestPage {
    var miles: XCUIElement { app.staticTexts["milesMetric"] }
    var steps: XCUIElement { app.staticTexts["stepsMetric"] }
    var heartRate: XCUIElement { app.staticTexts["heartRateMetric"] }
    var elapsed: XCUIElement { app.staticTexts["elapsedMetric"] }
    var goal: XCUIElement { app.staticTexts["goalMetric"] }
    var progress: XCUIElement { app.staticTexts["progressMetric"] }
}
