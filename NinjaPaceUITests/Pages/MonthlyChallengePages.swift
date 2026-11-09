//
//  NinjaPaceUITests.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 10/4/26.
//

import XCTest

@MainActor
final class MonthlyChallengesPage: UITestPage {
    var navigationBar: XCUIElement {
        app.navigationBars["Monthly Challenges"]
    }

    var currentChallenge: XCUIElement {
        app.buttons["currentMonthlyChallenge"]
    }

    func openCurrentChallenge(file: StaticString = #filePath, line: UInt = #line) -> MonthlyChallengeDetailPage {
        scrollTo(currentChallenge, file: file, line: line)
        tapWhenHittable(currentChallenge, file: file, line: line)
        return MonthlyChallengeDetailPage(app: app)
    }

    func backToAwards(file: StaticString = #filePath, line: UInt = #line) -> AwardsPage {
        goBack(file: file, line: line)
        return AwardsPage(app: app)
    }
}

@MainActor
final class MonthlyChallengeDetailPage: UITestPage {
    var title: XCUIElement {
        app.staticTexts["MONTHLY CHALLENGE"]
    }

    var lockedStatus: XCUIElement {
        app.staticTexts["ACHIEVEMENT LOCKED"]
    }

    var continueTrainingButton: XCUIElement {
        app.buttons["Continue Training"]
    }

    func continueTraining(file: StaticString = #filePath, line: UInt = #line) -> MonthlyChallengesPage {
        // The detail content can extend below the viewport on an iPhone.
        scrollTo(continueTrainingButton, file: file, line: line)
        tapWhenHittable(continueTrainingButton, file: file, line: line)
        return MonthlyChallengesPage(app: app)
    }
}
