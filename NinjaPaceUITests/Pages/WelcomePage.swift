//
//  WelcomePage.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 8/4/26.
//

import XCTest

@MainActor
final class WelcomePage: UITestPage {
    enum Warrior: String {
        case ninja, viking, knight, pirate, cyborg, spartan
    }

    var title: XCUIElement { app.staticTexts["welcomeTitle"] }

    func warrior(_ warrior: Warrior) -> XCUIElement {
        app.buttons["warrior_\(warrior.rawValue)"]
    }

    func selectWarrior(_ warrior: Warrior) {
        tap(self.warrior(warrior))
    }

    func beginTraining() -> TrainingHomePage {
        tap(app.buttons["beginTrainingButton"])
        return TrainingHomePage(app: app)
    }

    func openHUD() -> HUDCustomizationPage {
        tap(app.buttons["welcomeCustomizeHUDButton"])
        return HUDCustomizationPage(app: app)
    }
}
