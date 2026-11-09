import XCTest

/// Mac-specific interaction mechanics; expected behavior stays in the tests.
@MainActor
class MacUITestPage {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        guard element.waitForExistence(timeout: 3) else {
            XCTFail("Expected control did not appear: \(element)", file: file, line: line)
            return
        }
        element.tap()
    }
}

@MainActor
extension XCUIElement {
    /// macOS SwiftUI StaticText often exposes visible text as value, not label.
    var textValue: String {
        if let text = value as? String, !text.isEmpty { return text }
        return label
    }

    func waitForText(_ expectedText: String, timeout: TimeInterval = 3) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if exists, textValue == expectedText { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while Date() < deadline
        return false
    }
}
