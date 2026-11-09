//
//  HUDCustomizationPage.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 8/4/26.
//

import XCTest

@MainActor
final class HUDCustomizationPage: UITestPage {
    enum PreviewState: String {
        case live = "Live", paused = "Paused", idle = "Idle", goal = "Goal"
    }

    var navigationBar: XCUIElement { app.navigationBars["Customize HUD"] }
    var collapsePreviewButton: XCUIElement { app.buttons["Collapse HUD Preview"] }
    var expandPreviewButton: XCUIElement { app.buttons["Expand HUD Preview"] }
    var textSize: XCUIElement { app.staticTexts["Text Size"] }
    var milesSwitch: XCUIElement { app.switches["Miles"] }
    var stepsSwitch: XCUIElement { app.switches["Steps"] }
    var titleField: XCUIElement { app.textFields["HUD Title"] }

    func collapsedStatus(_ label: String) -> XCUIElement { app.staticTexts[label] }
    func selectPreview(_ state: PreviewState) { tap(app.buttons[state.rawValue]) }
    func collapsePreview() { tap(collapsePreviewButton) }
    func expandPreview() { tap(expandPreviewButton) }
    func openIdentity() { tap(app.buttons["Identity"]) }
    func openAppearance() { tap(app.buttons["Appearance"]) }

    func openVisibleMetrics() {
        let button = app.buttons["Visible Metrics"]
        scrollTo(button)
        tap(button)
    }

    func toggleSteps() {
        scrollTo(stepsSwitch)
        // SwiftUI exposes the whole row; the physical switch is on its right edge.
        stepsSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
    }

    func replaceTitle(with newTitle: String, file: StaticString = #filePath, line: UInt = #line) {
        replaceText(in: titleField, with: newTitle, file: file, line: line)
    }

    func requestNinjaPresetReset() -> HUDResetDialog {
        let button = app.buttons["Reset To Ninja Default Preset"]
        scrollTo(button)
        tap(button)
        return HUDResetDialog(app: app)
    }

    func backToTraining() -> TrainingHomePage {
        goBack()
        return TrainingHomePage(app: app)
    }

    func backToWelcome() -> WelcomePage {
        goBack()
        return WelcomePage(app: app)
    }
}

@MainActor
final class HUDResetDialog: UITestPage {
    // confirmationDialog actions are not consistently exposed as buttons.
    private func element(labeled label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    var title: XCUIElement { element(labeled: "Reset HUD Settings?") }
    var confirmButton: XCUIElement { element(labeled: "Reset to Ninja Defaults") }

    func confirm() -> HUDCustomizationPage {
        tap(confirmButton)
        return HUDCustomizationPage(app: app)
    }
}
