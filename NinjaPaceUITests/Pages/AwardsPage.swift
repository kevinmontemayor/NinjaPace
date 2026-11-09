//
//  AwardsPage.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 8/4/26.
//

import XCTest

@MainActor
final class AwardsPage: MainTabPage {
    var title: XCUIElement {
        app.staticTexts["Awards"]
    }
    
    var currentStreak: XCUIElement {
        app.staticTexts["Current Streak"]
    }
    
    var milestones: XCUIElement {
        app.staticTexts["Milestones"]
    }
    
    var badges: XCUIElement {
        app.staticTexts["Badges"]
    }

    var monthlyChallengesButton: XCUIElement {
        app.buttons["monthlyChallengesNavigation"]
    }

    func openMonthlyChallenges(file: StaticString = #filePath, line: UInt = #line) -> MonthlyChallengesPage {
        scrollTo(monthlyChallengesButton, file: file, line: line)
        tapWhenHittable(monthlyChallengesButton, file: file, line: line)
        return MonthlyChallengesPage(app: app)
    }
    
    func achievement(_ rawValue: String) -> XCUIElement {
        app.buttons["achievementBadge_\(rawValue)"]
    }
    
    func openAchievement(_ rawValue: String, file: StaticString = #filePath, line: UInt = #line ) -> AchievementDetailPage {
        let badge = achievement(rawValue)
        
        scrollTo(badge, maxSwipes: 8, file: file, line: line)
        tap(badge, file: file, line: line)
        
        return AchievementDetailPage(app: app)
    }
}
