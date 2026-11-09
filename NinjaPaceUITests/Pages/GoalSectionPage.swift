//
//  GoalSectionPage.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 10/4/26.
//

import XCTest

@MainActor
final class GoalSectionPage: UITestPage {
    enum Preset: String {
        case oneMile = "1 mile", fiveK = "5K", tenK = "10K"
    }

    var mileage: XCUIElement { app.staticTexts["goalMilesValue"] }
    func preset(_ preset: Preset) -> XCUIElement { app.buttons["goalPreset_\(preset.rawValue)"] }
    func selectPreset(_ preset: Preset) { tap(self.preset(preset)) }
    func subtractQuarterMile() { tap(app.buttons["goalMinusQuarterButton"]) }
    func addQuarterMile() { tap(app.buttons["goalPlusQuarterButton"]) }
    func roundToQuarterMile() { tap(app.buttons["goalRoundButton"]) }
}
