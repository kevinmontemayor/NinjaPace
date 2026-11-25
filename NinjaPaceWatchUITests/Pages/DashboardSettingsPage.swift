//
//  DashboardSettingsPage.swift
//  NinjaPaceWatchUITests
//
//  Created by Kevin Montemayor on 11/23/26.
//

import XCTest

@MainActor
final class DashboardSettingsPage: WatchUITestPage {
    func open(file: StaticString = #filePath, line: UInt = #line) {
        tap(app.buttons["dashboardSettingsButton"], file: file, line: line)
        let anchor = app.descendants(matching: .any)["showCurrentTimeToggle"].firstMatch
        XCTAssertTrue(anchor.waitForExistence(timeout: 3), "Dashboard settings did not open.", file: file, line: line)
    }

    func setClockVisible(_ visible: Bool, file: StaticString = #filePath, line: UInt = #line) {
        setToggle("showCurrentTimeToggle", to: visible, file: file, line: line)
    }

    func setOverviewVisible(_ visible: Bool, file: StaticString = #filePath, line: UInt = #line) {
        setToggle("showOverviewToggle", to: visible, file: file, line: line)
    }

    func setMetric(_ metric: String, enabled: Bool, file: StaticString = #filePath, line: UInt = #line) {
        setToggle("metricToggle." + metric, to: enabled, file: file, line: line)
    }

    func chooseWarrior(_ key: String, file: StaticString = #filePath, line: UInt = #line) {
        let picker = app.buttons["chooseWarriorButton"]
        scrollTo(picker, maxSwipes: 6, file: file, line: line)
        tap(picker, file: file, line: line)
        let choice = app.descendants(matching: .any)["warriorChoice." + key].firstMatch
        scrollTo(choice, maxSwipes: 8, file: file, line: line)
        tap(choice, file: file, line: line)
        XCTAssertEqual(choice.value as? String, "Selected", file: file, line: line)
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 3), "Choose Warrior back button did not appear.", file: file, line: line)
        backButton.tap()
        let dashboardAnchor = app.descendants(matching: .any)["showCurrentTimeToggle"].firstMatch
        XCTAssertTrue(dashboardAnchor.waitForExistence(timeout: 3), "Dashboard did not return after selecting \(key).", file: file, line: line)
    }

    func chooseFeaturedMetric(_ key: String, file: StaticString = #filePath, line: UInt = #line) {
        let picker = app.buttons["featuredMetricPicker"].firstMatch
        scrollTo(picker, maxSwipes: 6, file: file, line: line)
        XCTAssertTrue(picker.exists, "Featured Metric picker did not appear.", file: file, line: line)
        tapWhenHittable(picker, file: file, line: line)
        XCTAssertTrue(app.navigationBars["Featured Metric"].waitForExistence(timeout: 3), "Featured Metric picker did not open.", file: file, line: line)
        let choice = app.descendants(matching: .any)["featuredChoice." + key].firstMatch
        for _ in 0..<10 {
            if choice.exists && choice.isHittable {
                break
            }
            XCUIDevice.shared.rotateDigitalCrown(delta: 0.15)
        }
        if !(choice.exists && choice.isHittable) {
            for _ in 0..<10 {
                XCUIDevice.shared.rotateDigitalCrown(delta: -0.15)
                if choice.exists && choice.isHittable {
                    break
                }
            }
        }
        XCTAssertTrue(choice.exists, "Featured metric choice \(key) did not appear.", file: file, line: line)
        tapWhenHittable(choice, file: file, line: line)
        XCTAssertTrue(choice.waitUntilAbsent(), "Featured metric picker did not dismiss.", file: file, line: line)
        let dashboardAnchor = app.descendants(matching: .any)["featuredMetricPicker"].firstMatch
        XCTAssertTrue(dashboardAnchor.waitForExistence(timeout: 3), "Dashboard did not return after selecting \(key).", file: file, line: line)
    }

    func chooseClockStyle(_ key: String, file: StaticString = #filePath, line: UInt = #line) {
        let picker = app.buttons["idleClockStylePicker"]
        scrollTo(picker, maxSwipes: 10, file: file, line: line)
        tap(picker, file: file, line: line)
        let choice = app.buttons["idleClockStyleChoice." + key]
        tap(choice, file: file, line: line)
        XCTAssertTrue(choice.waitUntilAbsent(), "Clock Style picker did not dismiss.", file: file, line: line)
    }

    func done(file: StaticString = #filePath, line: UInt = #line) {
        let navigationBar = app.navigationBars["Dashboard"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 3), "Dashboard navigation bar did not appear.", file: file, line: line)
        let button = navigationBar.buttons["dashboardSettingsDone"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 3), "Dashboard Done button did not appear.", file: file, line: line)
        button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(navigationBar.waitUntilAbsent(), "Dashboard settings did not dismiss.", file: file, line: line)
    }

    override func scrollTo(_ element: XCUIElement, maxSwipes: Int = 6, file: StaticString = #filePath, line: UInt = #line) {
        if isFullyVisible(element) { return }
        for _ in 0..<maxSwipes {
            XCUIDevice.shared.rotateDigitalCrown(delta: 0.15)
            if isFullyVisible(element) { return }
        }
        for _ in 0..<maxSwipes {
            XCUIDevice.shared.rotateDigitalCrown(delta: -0.15)
            if isFullyVisible(element) { return }
        }
        XCTFail("Could not scroll control into view: \(element)", file: file, line: line)
    }

    private func toggleIsOn(_ toggle: XCUIElement) -> Bool {
        if let value = toggle.value as? String {
            switch value.lowercased() {
            case "1", "on", "true", "yes":
                return true
            case "0", "off", "false", "no":
                return false
            default:
                XCTFail("Unexpected toggle value: \(value)")
                return false
            }
        }
        if let value = toggle.value as? NSNumber {
            return value.boolValue
        }
        XCTFail("Unexpected toggle value type: \(String(describing: toggle.value))")
        return false
    }

    private func isFullyVisible(_ element: XCUIElement) -> Bool {
        guard element.exists, element.isHittable else { return false }
        let navigationBar = app.navigationBars.firstMatch
        let top = navigationBar.exists ? navigationBar.frame.maxY : app.frame.minY
        return element.frame.minY >= top + 2 && element.frame.maxY <= app.frame.maxY - 4
    }

    private func setToggle(_ identifier: String, to enabled: Bool,
                           file: StaticString, line: UInt) {
        let toggle = app.switches[identifier].firstMatch
        scrollTo(toggle, maxSwipes: 10, file: file, line: line)
        guard isFullyVisible(toggle) else { return }
        if toggleIsOn(toggle) != enabled {
            // watchOS exposes a labeled row switch containing the actual switch.
            // Tap that leaf instead of a coordinate in a potentially clipped row.
            let control = toggle.switches.firstMatch
            tapWhenHittable(control.exists ? control : toggle, file: file, line: line)
        }
        let changed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@ OR value == %@",
                                   enabled ? "1" : "0", NSNumber(value: enabled)),
            object: toggle
        )
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 3), .completed,
                       "\(identifier) did not change to \(enabled); value: \(String(describing: toggle.value)).",
                       file: file, line: line)
    }
}
