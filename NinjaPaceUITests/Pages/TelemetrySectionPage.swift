//
//  TelemetrySectionPage.swift
//  NinjaPaceUITests
//
//  Created by Kevin Montemayor on 10/22/26.
//

import XCTest

@MainActor
final class TelemetrySectionPage: UITestPage {
    var title: XCUIElement { app.staticTexts["Live Stats from Watch"] }
    var miles: XCUIElement { app.staticTexts["milesMetric"] }
    var steps: XCUIElement { app.staticTexts["stepsMetric"] }
    var heartRate: XCUIElement { app.staticTexts["heartRateMetric"] }
    var elapsed: XCUIElement { app.staticTexts["elapsedMetric"] }
    var progress: XCUIElement { app.staticTexts["progressMetric"] }
    var goal: XCUIElement { app.staticTexts["goalMetric"] }
}
