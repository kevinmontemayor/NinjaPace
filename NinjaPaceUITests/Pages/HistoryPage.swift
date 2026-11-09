//
//  HistoryPage.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 8/4/26.
//

import XCTest

@MainActor
final class HistoryPage: MainTabPage {
    var title: XCUIElement {
        app.staticTexts["History"]
    }

    var emptyState: XCUIElement {
        app.staticTexts["No Workouts Yet"]
    }
    
    var workoutTrendsButton: XCUIElement {
        app.buttons["workoutTrendsButton"]
    }

    func year(_ year: Int) -> XCUIElement {
        app.buttons["historyYear_\(year)"]
    }

    func month(year: Int, month: Int) -> XCUIElement {
        app.buttons[String(format: "historyMonth_%04d-%02d", year, month)]
    }

    func openWorkoutTrends(file: StaticString = #filePath, line: UInt = #line) -> WorkoutTrendsPage {
        tapWhenHittable(workoutTrendsButton, file: file, line: line)
        
        let page = WorkoutTrendsPage(app: app)
        XCTAssertTrue(page.navigationBar.waitForExistence(timeout: 3), "Workout Trends did not open.", file: file, line: line)
        
        return page
    }
}
