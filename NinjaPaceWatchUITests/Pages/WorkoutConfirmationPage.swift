import XCTest

@MainActor
final class WorkoutConfirmationPage: WatchUITestPage {
    enum Action: String {
        case pause = "Pause", stop = "Stop"
    }

    private let action: Action

    init(app: XCUIApplication, action: Action) {
        self.action = action
        super.init(app: app)
    }

    // SwiftUI Watch confirmations are not reliably exposed through app.alerts.
    var cancelButton: XCUIElement { app.buttons["Cancel"] }

    func confirm(file: StaticString = #filePath, line: UInt = #line) -> WorkoutPage {
        guard waitForPresentation(file: file, line: line) else { return WorkoutPage(app: app) }
        // The dashboard may expose the same label; select the hittable alert action.
        tapHittableButton(named: action.rawValue, file: file, line: line)
        return finishDismissal(file: file, line: line)
    }

    func cancel(file: StaticString = #filePath, line: UInt = #line) -> WorkoutPage {
        guard waitForPresentation(file: file, line: line) else { return WorkoutPage(app: app) }
        tapHittableButton(named: "Cancel", file: file, line: line)
        return finishDismissal(file: file, line: line)
    }

    private func waitForPresentation(file: StaticString, line: UInt) -> Bool {
        guard cancelButton.waitForExistence(timeout: 3) else {
            XCTFail("\(action.rawValue) confirmation did not appear.", file: file, line: line)
            return false
        }
        return true
    }

    private func finishDismissal(file: StaticString, line: UInt) -> WorkoutPage {
        XCTAssertTrue(cancelButton.waitUntilAbsent(), "\(action.rawValue) confirmation did not dismiss.",
                      file: file, line: line)
        return WorkoutPage(app: app)
    }
}
