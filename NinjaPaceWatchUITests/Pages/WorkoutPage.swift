import XCTest

@MainActor
final class WorkoutPage: WatchUITestPage {
    var status: XCUIElement { app.staticTexts["workoutStatus"] }
    var primaryButton: XCUIElement { app.buttons["primaryWorkoutButton"] }
    var stopButton: XCUIElement { app.buttons["stopWorkoutButton"] }
    var metrics: WorkoutMetricsSection { WorkoutMetricsSection(app: app) }

    func requestPause(file: StaticString = #filePath, line: UInt = #line) -> WorkoutConfirmationPage {
        tap(primaryButton, file: file, line: line)
        return WorkoutConfirmationPage(app: app, action: .pause)
    }

    func requestStop(file: StaticString = #filePath, line: UInt = #line) -> WorkoutConfirmationPage {
        tap(stopButton, file: file, line: line)
        return WorkoutConfirmationPage(app: app, action: .stop)
    }

    func resume(file: StaticString = #filePath, line: UInt = #line) {
        tap(primaryButton, file: file, line: line)
    }
}
