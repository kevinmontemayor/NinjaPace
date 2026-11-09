//
//  GoalScheduleTests.swift
//  NinjaPaceTests
//
//  Created by Kevin Montemayor on 8/21/26.
//

import Foundation
import Testing
@testable import NinjaPace

@Suite("Goal Schedule")
struct GoalScheduleTests {

    private let tolerance = 0.000_001

    @Test("Default schedule uses 5K Sun–Fri and half marathon Saturday")
    func defaultScheduleHasExpectedMileage() {

        let schedule =
            GoalSchedule.default

        for weekday in [1, 2, 3, 4, 5, 6] {
            #expect(
                abs(
                    schedule.miles(for: weekday)
                    - 3.10686
                )
                < tolerance
            )
        }

        #expect(
            abs(
                schedule.miles(for: 7)
                - 13.1094
            )
            < tolerance
        )

        #expect(
            schedule.useScheduleDefaults
            == false
        )
    }

    @Test("Unknown weekday falls back to 5K")
    func missingWeekdayUsesFallbackMileage() {

        let schedule =
            GoalSchedule(
                milesByWeekday: [:],
                useScheduleDefaults: false
            )

        #expect(
            abs(
                schedule.miles(for: 99)
                - 3.10686
            )
            < tolerance
        )
    }

    @Test("Setting one day does not change the others")
    func setMilesChangesOnlyRequestedDay() {

        var schedule =
            GoalSchedule.default

        let originalTuesday =
            schedule.miles(for: 3)

        schedule.setMiles(
            5.0,
            for: 2
        )

        #expect(
            schedule.miles(for: 2)
            == 5.0
        )

        #expect(
            schedule.miles(for: 3)
            == originalTuesday
        )
    }

    @Test("A schedule day can be explicitly set to rest")
    func dayCanBeSetToRest() {

        var schedule =
            GoalSchedule.default

        schedule.setMiles(
            0,
            for: 2
        )

        #expect(
            schedule.miles(for: 2)
            == 0
        )
    }

    @Test("Schedule-default preference is ordinary value state")
    func scheduleDefaultsCanBeEnabled() {

        var schedule =
            GoalSchedule.default

        schedule.useScheduleDefaults =
            true

        #expect(
            schedule.useScheduleDefaults
        )
    }

    @Test("GoalSchedule survives a Codable round trip")
    func codableRoundTrip() throws {

        var original =
            GoalSchedule.default

        original.useScheduleDefaults =
            true

        original.setMiles(
            0,
            for: 2
        )

        original.setMiles(
            10.0,
            for: 7
        )

        let data =
            try JSONEncoder()
                .encode(original)

        let decoded =
            try JSONDecoder()
                .decode(
                    GoalSchedule.self,
                    from: data
                )

        #expect(
            decoded
            == original
        )
    }

    @Test("CodableAppStorage returns its default when no value exists")
    func codableAppStorageReturnsDefault() throws {

        let suiteName =
            "NinjaPaceTests.GoalSchedule.\(UUID().uuidString)"

        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )

        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let storage =
            CodableAppStorage(
                key: "schedule",
                defaultValue: GoalSchedule.default,
                storage: defaults
            )

        #expect(
            storage.wrappedValue
            == GoalSchedule.default
        )
    }

    @Test("CodableAppStorage persists and reloads a schedule")
    func codableAppStoragePersistsSchedule() throws {

        let suiteName =
            "NinjaPaceTests.GoalSchedule.\(UUID().uuidString)"

        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )

        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        var expected =
            GoalSchedule.default

        expected.useScheduleDefaults =
            true

        expected.setMiles(
            5.0,
            for: 2
        )

        var writer =
            CodableAppStorage(
                key: "schedule",
                defaultValue: GoalSchedule.default,
                storage: defaults
            )

        writer.wrappedValue =
            expected

        let reader =
            CodableAppStorage(
                key: "schedule",
                defaultValue: GoalSchedule.default,
                storage: defaults
            )

        #expect(
            reader.wrappedValue
            == expected
        )
    }

    @Test("CodableAppStorage falls back safely when stored data is invalid")
    func codableAppStorageHandlesCorruptData() throws {

        let suiteName =
            "NinjaPaceTests.GoalSchedule.\(UUID().uuidString)"

        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )

        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        defaults.set(
            Data(
                [
                    0xDE,
                    0xAD,
                    0xBE,
                    0xEF
                ]
            ),
            forKey: "schedule"
        )

        let storage =
            CodableAppStorage(
                key: "schedule",
                defaultValue: GoalSchedule.default,
                storage: defaults
            )

        #expect(
            storage.wrappedValue
            == GoalSchedule.default
        )
    }
}
