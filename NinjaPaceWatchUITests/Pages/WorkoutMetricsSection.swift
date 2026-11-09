import XCTest

@MainActor
final class WorkoutMetricsSection: WatchUITestPage {
    var elapsedTitle: XCUIElement { app.staticTexts["ET.⏱️"] }
    var paceTitle: XCUIElement { app.staticTexts["Pace 👟"] }
    var heartRateTitle: XCUIElement { app.staticTexts["HR ❤️"] }
    var caloriesTitle: XCUIElement { app.staticTexts["Cal.🔥"] }
    var stepsTitle: XCUIElement { app.staticTexts["Steps 👣"] }
    var goalTitle: XCUIElement { app.staticTexts["GOAL"] }

    // Query leaf identifiers; a parent identifier can hide metric children on watchOS.
    var elapsed: XCUIElement { app.staticTexts["elapsedMetric"] }
    var pace: XCUIElement { app.staticTexts["paceMetric"] }
    var heartRate: XCUIElement { app.staticTexts["heartRateMetric"] }
    var calories: XCUIElement { app.staticTexts["caloriesMetric"] }
    var steps: XCUIElement { app.staticTexts["stepsMetric"] }
    var goal: XCUIElement { app.staticTexts["goalValue"] }
}
