//
//  UITestPage.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 2/4/26.
//

import XCTest

/// Shared mechanics only; screen-specific locators and actions belong to Pages.
@MainActor
class UITestPage {
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

    /// Menu items may exist in the accessibility tree before presentation finishes.
    func tapWhenHittable(_ element: XCUIElement, timeout: TimeInterval = 5, file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"), object: element
        )
        guard XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed else {
            XCTFail("Control did not become hittable: \(element)", file: file, line: line)
            return
        }
        element.tap()
    }

    func scrollTo(_ element: XCUIElement, maxSwipes: Int = 6, file: StaticString = #filePath, line: UInt = #line) {
        for attempt in 0...maxSwipes {
            if element.exists && element.isHittable { return }
            if attempt < maxSwipes { app.swipeUp() }
        }
        XCTFail("Could not scroll control into view: \(element)", file: file, line: line)
    }

    func goBack(file: StaticString = #filePath, line: UInt = #line) {
        tap(app.buttons["Back"], file: file, line: line)
    }
    
    func replaceText(in field: XCUIElement, with newText: String, file: StaticString, line: UInt) {
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Text field did not appear.", file: file, line: line)
        
        let currentText = field.value as? String ?? ""
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        
        if !currentText.isEmpty {
            let deleteCount = currentText.utf16.count + 8
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: deleteCount))
        }
        
        field.typeText(newText)
        XCTAssertEqual(field.value as? String, newText, "Text field did not contain the requested replacement text.", file: file, line: line)
    }
}

@MainActor
extension XCUIElement {
    func waitForLabel(_ label: String, timeout: TimeInterval = 4) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label == %@", label), object: self
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func waitUntilAbsent(timeout: TimeInterval = 3) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: self
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    var isSwitchOn: Bool {
        let text = String(describing: value ?? "").lowercased()
        return text == "1" || text == "on" || text == "true"
    }

    func waitForSwitchState(_ expectedOn: Bool, timeout: TimeInterval = 2) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if exists, isSwitchOn == expectedOn { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while Date() < deadline
        return false
    }
}
