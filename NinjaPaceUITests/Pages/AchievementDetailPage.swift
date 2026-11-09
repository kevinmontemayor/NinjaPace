//
//  AchievementDetailPage.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 9/29/26.
//

import XCTest

@MainActor
final class AchievementDetailPage: UITestPage {
    
    var status: XCUIElement {
        app.staticTexts["achievementDetailStatus"]
    }
    
    var title: XCUIElement {
        app.staticTexts["achievementDetailTitle"]
    }
    
    var nextTarget: XCUIElement {
        app.staticTexts["achievementDetailNextTarget"]
    }
    
    var legendStatus: XCUIElement {
        app.staticTexts["achievementDetailLegendStatus"]
    }
    
    var returnButton: XCUIElement {
        app.buttons["achievementDetailReturn"]
    }
    
    func close(file: StaticString = #filePath, line: UInt = #line) -> AwardsPage {
        tap(returnButton, file: file, line: line)
        return AwardsPage(app: app)
    }
}
