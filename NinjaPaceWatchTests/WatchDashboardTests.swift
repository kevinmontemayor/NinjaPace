//
//  WatchDashboardTests.swift
//  NinjaPaceWatchTests
//
//  Created by Kevin Montemayor on 11/23/26.
//

import XCTest
import UIKit
import SwiftUI
@testable import NinjaPaceWatch

@MainActor
final class WatchDashboardTests: XCTestCase {
    func testDefaultPagesAndPersistedCustomization() throws {
        let suite = "WatchDashboardTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = WatchDashboardPreferences(store: defaults)
        XCTAssertEqual(preferences.visiblePages, [.home, .overview, .distance, .pace, .heartRate, .elapsed, .controls])
        XCTAssertEqual(preferences.featuredMetric, .distance)
        XCTAssertTrue(preferences.showCurrentTime)
        XCTAssertEqual(preferences.idleClockStyle, .digital)
        preferences.idleClockStyleRaw = "analog"

        preferences.showOverview = false
        preferences.showCurrentTime = false
        preferences.featuredMetricRaw = "calories"
        preferences.enabledBinding(for: .distance).wrappedValue = false
        preferences.enabledBinding(for: .calories).wrappedValue = true
        let restored = WatchDashboardPreferences(store: defaults)
        XCTAssertEqual(restored.visiblePages, [.home, .pace, .heartRate, .calories, .elapsed, .controls])
        XCTAssertEqual(restored.featuredMetric, .calories)
        XCTAssertFalse(restored.showCurrentTime)
        XCTAssertEqual(restored.idleClockStyle, .analog)
        restored.idleClockStyleRaw = "unknown"
        XCTAssertEqual(restored.idleClockStyle, .digital)

        restored.metricsRaw = ""
        XCTAssertEqual(restored.visiblePages, [.home, .controls])
        restored.featuredMetricRaw = "unknown"
        XCTAssertEqual(restored.featuredMetric, .distance)
    }

    func testUnknownAndDuplicatePreferencesDoNotCreateInvalidPages() {
        XCTAssertEqual(WatchDashboardPreferences.decodeMetrics("elapsed,unknown,pace,pace"), [.pace, .elapsed])
        XCTAssertTrue(WatchDashboardPreferences.decodeMetrics("").isEmpty)
        XCTAssertEqual(Set(WatchFocusMetric.allCases.map(\.dashboardPage)).count, 6)
    }

    func testMetricFormattingUsesManagerValues() {
        let manager = WatchWorkoutManager()
        XCTAssertEqual(WatchFocusMetric.heartRate.value(from: manager), "—")
        XCTAssertEqual(WatchFocusMetric.pace.value(from: manager), "—")
        manager.hr = 142
        manager.miles = 3.14
        manager.elapsedSeconds = 1690
        manager.activeCalories = 418.4
        manager.steps = 6240
        XCTAssertEqual(WatchFocusMetric.distance.value(from: manager),
                       manager.miles.formatted(.number.precision(.fractionLength(2))))
        XCTAssertEqual(WatchFocusMetric.pace.value(from: manager), manager.paceString)
        XCTAssertEqual(WatchFocusMetric.elapsed.value(from: manager), "00:28:10")
        XCTAssertEqual(WatchFocusMetric.heartRate.value(from: manager), 142.formatted())
        XCTAssertEqual(WatchFocusMetric.calories.value(from: manager), 418.formatted())
        XCTAssertEqual(WatchFocusMetric.steps.value(from: manager), 6240.formatted())
    }

    func testEveryWarriorArtworkIsBundledInWatchApp() {
        for theme in WatchTheme.allCases {
            XCTAssertNotNil(UIImage(named: theme.heroAssetName), "Missing artwork for \(theme)")
            for level in WarriorProgressionLevel.allCases {
                XCTAssertNotNil(UIImage(named: level.assetName(forThemeKey: theme.rawValue)),
                                "Missing \(theme) level \(level.rawValue) artwork")
                XCTAssertNotNil(level.title(forThemeKey: theme.rawValue))
            }
        }
    }

    func testPhoneProgressionSurvivesRelaunchAndRejectsStaleOrInvalidSettings() {
        let defaults = UserDefaults.standard
        let keys = ["warriorProgressionLevel", "lastAppliedSettingsUpdatedAt"]
        let originals = keys.map { defaults.object(forKey: $0) }
        defer {
            for (key, value) in zip(keys, originals) {
                if let value { defaults.set(value, forKey: key) }
                else { defaults.removeObject(forKey: key) }
            }
        }
        keys.forEach { defaults.removeObject(forKey: $0) }
        let manager = WatchWorkoutManager()
        XCTAssertNil(manager.warriorLevel)
        manager.applyPhoneSettings(["warriorLevel": 4, "settingsUpdatedAt": 200.0])
        XCTAssertEqual(manager.warriorLevel, .level4)
        XCTAssertEqual(WatchWorkoutManager().warriorLevel, .level4)
        manager.applyPhoneSettings(["warriorLevel": 1, "settingsUpdatedAt": 100.0])
        manager.applyPhoneSettings(["warriorLevel": 99, "settingsUpdatedAt": 201.0])
        manager.applyPhoneSettings(["settingsUpdatedAt": 202.0])
        XCTAssertEqual(manager.warriorLevel, .level4)
        // A genuine corrected history can reduce rank; this isn't a local high-water mark.
        manager.applyPhoneSettings(["warriorLevel": 2, "settingsUpdatedAt": 203.0])
        XCTAssertEqual(manager.warriorLevel, .level2)
    }

    func testAnalogHandsIncludeMinuteOffsetInHourHand() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 24, hour: 15, minute: 30)))
        let angles = WatchIdleClockAngles(date: date, calendar: calendar)
        XCTAssertEqual(angles.hour, 105)
        XCTAssertEqual(angles.minute, 180)
    }
}
