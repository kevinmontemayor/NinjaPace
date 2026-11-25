//
//  WatchUITestPage.swift
//  NinjaPaceWatchUITests
//
//  Created by Kevin Montemayor on 11/23/26.
//

import XCTest

/// Watch-specific interaction mechanics; business expectations stay in the tests.
@MainActor
class WatchUITestPage {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        guard element.waitForExistence(timeout: 3) else {
            XCTFail("Expected control did not appear: \(element)", file: file, line: line)
            return
        }
        // Let XCTest scroll dashboard controls into view on the small Watch screen.
        element.tap()
    }

    func tapHittableButton(named label: String, timeout: TimeInterval = 3,
                           file: StaticString = #filePath, line: UInt = #line) {
        let buttons = app.buttons.matching(NSPredicate(format: "label == %@", label))
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for index in 0..<buttons.count {
                let button = buttons.element(boundBy: index)
                if button.exists, button.isHittable {
                    button.tap()
                    return
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while Date() < deadline
        XCTFail("No hittable \(label) button appeared.", file: file, line: line)
    }
    
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
        if element.exists && element.isHittable { return }
        // Search downward first.
        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.exists && element.isHittable { return }
        }
        // Then search back upward.
        for _ in 0..<maxSwipes {
            app.swipeDown()
            if element.exists && element.isHittable { return }
        }
        XCTFail("Could not scroll control into view: \(element)", file: file, line: line)
    }
}

@MainActor
extension XCUIElement {
    func waitForLabel(_ label: String, timeout: TimeInterval = 3) -> Bool {
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
}
