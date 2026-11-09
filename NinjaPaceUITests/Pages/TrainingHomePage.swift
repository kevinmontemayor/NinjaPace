//
//  TrainingHomePage.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 8/4/26.
//

import XCTest

@MainActor
final class TrainingHomePage: MainTabPage {
    var title: XCUIElement { app.staticTexts["trainingHomeTitle"] }
    var goal: GoalSectionPage { GoalSectionPage(app: app) }
    
    private var compactGoalButton: XCUIElement {
        app.buttons["compactSection_goal"]
    }
    
    private var compactTelemetryButton: XCUIElement {
        app.buttons["compactSection_telemetry"]
    }
    
    private var compactServerButton: XCUIElement {
        app.buttons["compactSection_server"]
    }
    
    func openGoal(file: StaticString = #filePath, line: UInt = #line) -> GoalSectionPage {
        let section = goal
        openSection(named: "Today's Goal", content: section.mileage, compactButton: compactGoalButton, regularButton: app.buttons["goalSectionButton"], file: file, line: line)
        
        return section
    }
    
    func openTelemetry(file: StaticString = #filePath, line: UInt = #line) -> TelemetrySectionPage {
        let section = TelemetrySectionPage(app: app)
        openSection(named: "Telemetry", content: section.title, compactButton: compactTelemetryButton, regularButton: app.buttons["Telemetry"], file: file, line: line)
        
        return section
    }
    
    func openServerControls(file: StaticString = #filePath, line: UInt = #line) {
        if compactServerButton.exists {
            if compactServerButton.value as? String != "Expanded" {
                tapWhenHittable(
                    compactServerButton,
                    file: file,
                    line: line
                )
            }
            XCTAssertEqual(compactServerButton.value as? String, "Expanded", "Server Controls compact section did not expand.", file: file, line: line)
        } else {
            tapWhenHittable(app.buttons["Server Controls"], file: file, line: line)
        }
    }
    
    func openHUD(file: StaticString = #filePath, line: UInt = #line) -> HUDCustomizationPage {
        tapWhenHittable(app.buttons["customizeNinjaPaceButton"], file: file, line: line)
        tapWhenHittable(app.buttons["Customize HUD"], file: file, line: line)
        let hud = HUDCustomizationPage(app: app)
        // Synchronize the menu-to-navigation transition before exposing the page.
        XCTAssertTrue(hud.navigationBar.waitForExistence(timeout: 5), "HUD customization did not open after selecting its menu action.", file: file, line: line)
        return hud
    }

    func openSchedule() -> TrainingSchedulePage {
        tap(app.buttons["trainingScheduleButton"])
        return TrainingSchedulePage(app: app)
    }

    func openSettings(file: StaticString = #filePath, line: UInt = #line) -> SettingsPage {
        tapWhenHittable(app.buttons["relaySettingsButton"], file: file, line: line)
        
        let page = SettingsPage(app: app)
        XCTAssertTrue(page.navigationBar.waitForExistence(timeout: 3), "Settings did not open.", file: file, line: line)
        
        return page
    }

    var warriorProgressFooter: XCUIElement {
        app.descendants(
            matching: .any
        )["warriorProgressFooter"].firstMatch
    }

    var goalCelebration: XCUIElement {
        app.descendants(
            matching: .any
        )["goalCelebrationOverlay"].firstMatch
    }

    func triggerDebugGoalCelebration(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(warriorProgressFooter.waitForExistence(timeout: 3), "Warrior footer was not available.", file: file, line: line)
        
        warriorProgressFooter.doubleTap()
    }
    
    private func openSection(named name: String, content: XCUIElement, compactButton: XCUIElement, regularButton: XCUIElement, file: StaticString, line: UInt) {
        if content.exists {
            return
        }
        
        if compactButton.exists {
            if compactButton.value as? String != "Expanded" {
                tapWhenHittable(compactButton, file: file, line: line)
            }
        } else {
            tapWhenHittable(regularButton, file: file, line: line)
        }
        
        XCTAssertTrue(content.waitForExistence(timeout: 3), "\(name) section did not expand.", file: file, line: line)
    }

}
