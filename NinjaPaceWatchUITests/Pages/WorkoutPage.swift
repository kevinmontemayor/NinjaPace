//
//  WorkoutPage.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import XCTest

@MainActor
final class WorkoutPage: WatchUITestPage {
    var status: XCUIElement { app.staticTexts["workoutStatus"].firstMatch }
    var primaryButton: XCUIElement { app.buttons["primaryWorkoutButton"].firstMatch }
    var stopButton: XCUIElement { app.buttons["stopWorkoutButton"] }
    var metrics: WorkoutMetricsSection { WorkoutMetricsSection(app: app) }
    var artwork: XCUIElement { app.images["warriorArtwork"].firstMatch }
    var clock: XCUIElement { app.descendants(matching: .any)["homeClock"].firstMatch }
    var idleClock: XCUIElement {
        app.descendants(matching: .any)["idleWarriorClock"].firstMatch
    }

    var idleArtwork: XCUIElement {
        app.images["idleWarriorArtwork"].firstMatch
    }

    func dismissIdleClock(file: StaticString = #filePath, line: UInt = #line) {
        let idle = idleClock
        
        XCTAssertTrue(idle.waitForExistence(timeout: 5), "Idle Warrior Clock did not appear.", file: file, line: line)
        
        idle.tap()
        
        XCTAssertTrue(app.staticTexts["homeThemeTitle"].waitForExistence(timeout: 5), "Home did not appear after dismissing the Idle Warrior Clock.", file: file, line: line)
    }
    
    func showOverview(file: StaticString = #filePath, line: UInt = #line) {
        pageForward(to: "overviewTitle", file: file, line: line)
    }

    func showControls(file: StaticString = #filePath, line: UInt = #line) {
        pageForward(to: "controlsTitle", file: file, line: line)
    }

    func pageForward(to identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let title = app.staticTexts[identifier]
        for _ in 0..<9 {
            if title.exists && title.isHittable { return }
            app.swipeUp()
        }
        XCTFail("Did not reach dashboard page \(identifier)", file: file, line: line)
    }

    func requestPause(file: StaticString = #filePath, line: UInt = #line) -> WorkoutConfirmationPage {
        tap(primaryButton, file: file, line: line)
        return WorkoutConfirmationPage(app: app, action: .pause)
    }

    func requestStop(file: StaticString = #filePath, line: UInt = #line) -> WorkoutConfirmationPage {
        showControls(file: file, line: line)
        tap(stopButton, file: file, line: line)
        return WorkoutConfirmationPage(app: app, action: .stop)
    }

    func resume(file: StaticString = #filePath, line: UInt = #line) {
        tap(primaryButton, file: file, line: line)
    }
}
