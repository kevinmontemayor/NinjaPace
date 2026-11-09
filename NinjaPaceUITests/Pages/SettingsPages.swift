//
//  SettingsPages.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 8/4/26.
//

import XCTest

@MainActor
final class TrainingSchedulePage: UITestPage {
    var navigationBar: XCUIElement { app.navigationBars["Goal Schedule"] }

    func backToTraining() -> TrainingHomePage {
        goBack()
        return TrainingHomePage(app: app)
    }
}

@MainActor
final class SettingsPage: UITestPage {
    
    var navigationBar: XCUIElement {
        app.navigationBars["Settings"]
    }
    
    var goalAlertsButton: XCUIElement {
        app.buttons["goalAlertsButton"]
    }
    
    var goalCelebrationsSwitch: XCUIElement {
        app.switches["goalCelebrationsToggle"]
    }
    
    var hiddenAddress: XCUIElement {
        app.staticTexts["Relay Address Hidden"]
    }
    
    var unlockButton: XCUIElement {
        app.buttons["Unlock to Reveal and Edit"]
    }
    
    var addressField: XCUIElement {
        app.textFields["Mac name or IP address"]
    }
    
    var saveButton: XCUIElement {
        app.buttons["Save Relay Address"]
    }
    
    func openGoalAlerts(file: StaticString = #filePath, line: UInt = #line) -> GoalAlertsPage {
        tapWhenHittable(goalAlertsButton, file: file, line: line)
        
        let page = GoalAlertsPage(app: app)
        XCTAssertTrue(page.navigationBar.waitForExistence(timeout: 3), "Goal Alerts did not open.", file: file, line: line)
        
        return page
    }

    func setGoalCelebrations(_ enabled: Bool) {
        if goalCelebrationsSwitch.isSwitchOn != enabled {
            tap(goalCelebrationsSwitch)
        }
    }

    func backToTraining() -> TrainingHomePage {
        tap(app.buttons["Back"])
        return TrainingHomePage(app: app)
    }
}

@MainActor
final class GoalAlertsPage: UITestPage {

    var navigationBar: XCUIElement {
        app.navigationBars["Goal Alerts"]
    }

    var dailyReminderSwitch: XCUIElement {
        app.switches["dailyGoalReminderToggle"]
    }

    var reminderTimePicker: XCUIElement {
        app.datePickers["goalReminderTimePicker"]
    }

    func backToSettings() -> SettingsPage {
        tap(app.buttons["Back"])
        return SettingsPage(app: app)
    }
}
