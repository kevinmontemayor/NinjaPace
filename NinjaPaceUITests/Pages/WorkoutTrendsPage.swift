//
//  WorkoutTrendsPage.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 10/4/26.
//

import XCTest

@MainActor
final class WorkoutTrendsPage: UITestPage {

    var navigationBar: XCUIElement {
        app.navigationBars["Workout Trends"]
    }

    var scopePicker: XCUIElement {
        app.descendants(matching: .any)["workoutTrendScopePicker"].firstMatch
    }

    var trainingIntel: XCUIElement {
        app.descendants(matching: .any)["workoutTrendTrainingIntel"].firstMatch
    }

    var metricMenu: XCUIElement {
        app.buttons["workoutTrendMetricMenu"]
    }

    var chart: XCUIElement {
        app.descendants(matching: .any)["workoutTrendChart"].firstMatch
    }

    var summary: XCUIElement {
        app.descendants(matching: .any)["workoutTrendLatestSummary"].firstMatch
    }
    
    var battleRecord: XCUIElement {
        app.descendants(matching: .any)["workoutBattleRecord"].firstMatch
    }

    func scopeButton(_ name: String) -> XCUIElement {
        app.buttons["workoutTrendScope_\(name)"]
    }

    func selectScope(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = scopeButton(name)
        tapWhenHittable(button, file: file, line: line)
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate( format: "value == %@", "Selected"), object: button)
        
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 3), .completed, "Trend scope did not finish switching to \(name).", file: file, line: line)
    }
    
    func selectMetric(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        tapWhenHittable(metricMenu, file: file, line: line)
        
        let option = metricButton(name)
        
        scrollTo(option, maxSwipes: 8, file: file, line: line)
        tapWhenHittable(option, file: file, line: line)

        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", name), object: metricMenu)
        
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed, "Trend metric did not finish switching to \(name).", file: file, line: line)
    }
    
    func metricButton(_ name: String) -> XCUIElement {
        app.buttons["workoutTrendMetric_\(name)"]
    }
    
    func waitForSummaryValue(_ expectedValue: String, timeout: TimeInterval = 5) -> Bool {
        waitForValue(expectedValue, in: summary, timeout: timeout)
    }
    
    func waitForValue(_ value: String, in element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND value == %@", value), object: element)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
