//
//  MainTabPage.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 8/4/26.
//

import XCTest

@MainActor
class MainTabPage: UITestPage {
    func showToday(file: StaticString = #filePath, line: UInt = #line) -> TrainingHomePage {
        tapNavigationButton("Today", file: file, line: line)
        
        let page = TrainingHomePage(app: app)
        XCTAssertTrue(page.title.waitForExistence(timeout: 3), "Today did not appear after selecting its navigation control.", file: file, line: line)
        
        return page
    }

    func showHistory(file: StaticString = #filePath, line: UInt = #line) -> HistoryPage {
        tapNavigationButton("History", file: file, line: line)
        
        let page = HistoryPage(app: app)
        XCTAssertTrue(page.title.waitForExistence(timeout: 3),"History did not appear after selecting its navigation control.", file: file, line: line)
        
        return page
    }

    func showAwards(file: StaticString = #filePath, line: UInt = #line) -> AwardsPage {
        tapNavigationButton("Awards", file: file, line: line)
        
        let page = AwardsPage(app: app)
        XCTAssertTrue(page.title.waitForExistence(timeout: 3), "Awards did not appear after selecting its navigation control.", file: file, line: line)
        
        return page
    }

    private func tapNavigationButton(_ label: String, file: StaticString, line: UInt) {
        let button = app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
        
        tapWhenHittable(button, file: file, line: line)
    }
}
