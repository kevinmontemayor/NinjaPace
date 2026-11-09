//
//  WorkoutTrendEngineTests.swift
//  NinjaPaceTests
//

import XCTest
@testable import NinjaPace

final class WorkoutTrendEngineTests: XCTestCase {

    func testMonthlyAggregationIncludesNewVolumeMetrics() {
        let calendar = utcCalendar()
        let reference = date(2026, 2, 20, calendar: calendar)

        let first = record(
            date: date(2026, 2, 4, calendar: calendar),
            miles: 3,
            duration: 1_800,
            steps: 5_000,
            heartRate: 140,
            calories: 300,
            cadence: 160,
            goal: 3
        )

        let second = record(
            date: date(2026, 2, 12, calendar: calendar),
            miles: 5,
            duration: 3_000,
            steps: 8_000,
            heartRate: 150,
            calories: 500,
            cadence: 170,
            goal: 4
        )

        let period = WorkoutTrendEngine(
            workouts: [first, second],
            calendar: calendar,
            referenceDate: reference
        )
        .periods(for: .monthly)
        .first

        XCTAssertNotNil(period)
        XCTAssertEqual(period?.workoutCount, 2)
        XCTAssertEqual(period?.totalMiles ?? 0, 8, accuracy: 0.0001)
        XCTAssertEqual(period?.totalActiveDuration ?? 0, 4_800, accuracy: 0.0001)
        XCTAssertEqual(period?.totalSteps, 13_000)
        XCTAssertEqual(period?.recordedActiveCalories ?? 0, 800, accuracy: 0.0001)
        XCTAssertEqual(period?.activeCaloriesWorkoutCount, 2)
    }

    func testAverageDistanceUsesPositiveDistanceWorkoutsOnly() {
        let calendar = utcCalendar()
        let reference = date(2026, 2, 20, calendar: calendar)

        let workouts = [
            record(
                date: date(2026, 2, 2, calendar: calendar),
                miles: 4,
                duration: 2_400,
                goal: 4
            ),
            record(
                date: date(2026, 2, 8, calendar: calendar),
                miles: 8,
                duration: 4_800,
                goal: 8
            ),
            record(
                date: date(2026, 2, 12, calendar: calendar),
                miles: 0,
                duration: 1_200,
                goal: 0
            )
        ]

        let period = WorkoutTrendEngine(
            workouts: workouts,
            calendar: calendar,
            referenceDate: reference
        )
        .periods(for: .monthly)
        .first

        XCTAssertEqual(period?.distanceWorkoutCount, 2)
        XCTAssertEqual(period?.averageDistanceMiles ?? 0, 6, accuracy: 0.0001)
    }

    func testAverageHeartRateIsActiveDurationWeighted() {
        let calendar = utcCalendar()
        let reference = date(2026, 2, 20, calendar: calendar)

        let workouts = [
            record(
                date: date(2026, 2, 2, calendar: calendar),
                miles: 1,
                duration: 600,
                heartRate: 120,
                goal: 1
            ),
            record(
                date: date(2026, 2, 8, calendar: calendar),
                miles: 3,
                duration: 1_800,
                heartRate: 160,
                goal: 3
            )
        ]

        let period = WorkoutTrendEngine(
            workouts: workouts,
            calendar: calendar,
            referenceDate: reference
        )
        .periods(for: .monthly)
        .first

        // (120 * 600 + 160 * 1800) / 2400 = 150 bpm.
        XCTAssertEqual(period?.averageHeartRateBPM ?? 0, 150, accuracy: 0.0001)
    }

    func testAverageCadenceIsActiveDurationWeighted() {
        let calendar = utcCalendar()
        let reference = date(2026, 2, 20, calendar: calendar)

        let workouts = [
            record(
                date: date(2026, 2, 2, calendar: calendar),
                miles: 1,
                duration: 600,
                cadence: 150,
                goal: 1
            ),
            record(
                date: date(2026, 2, 8, calendar: calendar),
                miles: 3,
                duration: 1_800,
                cadence: 170,
                goal: 3
            )
        ]

        let period = WorkoutTrendEngine(
            workouts: workouts,
            calendar: calendar,
            referenceDate: reference
        )
        .periods(for: .monthly)
        .first

        // (150 * 600 + 170 * 1800) / 2400 = 165 spm.
        XCTAssertEqual(period?.averageCadenceSPM ?? 0, 165, accuracy: 0.0001)
    }

    func testMissingOptionalMetricsStayUnavailable() {
        let calendar = utcCalendar()
        let reference = date(2026, 2, 20, calendar: calendar)

        let workout = record(
            date: date(2026, 2, 4, calendar: calendar),
            miles: 3,
            duration: 1_800,
            heartRate: nil,
            calories: nil,
            cadence: nil,
            goal: 3
        )

        let period = WorkoutTrendEngine(
            workouts: [workout],
            calendar: calendar,
            referenceDate: reference
        )
        .periods(for: .monthly)
        .first

        XCTAssertNil(period?.averageHeartRateBPM)
        XCTAssertNil(period?.recordedActiveCalories)
        XCTAssertNil(period?.averageCadenceSPM)
    }

    func testExistingDistanceWeightedPaceAndGoalRateSemanticsRemainIntact() {
        let calendar = utcCalendar()
        let reference = date(2026, 2, 20, calendar: calendar)

        let completed = record(
            date: date(2026, 2, 2, calendar: calendar),
            miles: 1,
            duration: 600,
            goal: 1
        )

        let missed = record(
            date: date(2026, 2, 8, calendar: calendar),
            miles: 9,
            duration: 4_500,
            goal: 10
        )

        let recoveredUnknownGoal = record(
            date: date(2026, 2, 12, calendar: calendar),
            miles: 6,
            duration: 3_600,
            goal: 0
        )

        let period = WorkoutTrendEngine(
            workouts: [completed, missed, recoveredUnknownGoal],
            calendar: calendar,
            referenceDate: reference
        )
        .periods(for: .monthly)
        .first

        // (600 + 4500 + 3600) / (1 + 9 + 6) = 543.75 sec/mi.
        XCTAssertEqual(period?.averagePaceSecondsPerMile ?? 0, 543.75, accuracy: 0.0001)
        XCTAssertEqual(period?.knownGoalCount, 2)
        XCTAssertEqual(period?.completedGoalCount, 1)
        XCTAssertEqual(period?.goalCompletionRatePercent ?? 0, 50, accuracy: 0.0001)
    }

    func testBattleRecordAggregatesLifetimeMilesWorkoutsAndCompletedGoals() {
        let calendar = utcCalendar()

        let completedGoal = record(
            date: date(2026, 2, 4, calendar: calendar),
            miles: 5,
            duration: 3_000,
            goal: 4
        )

        let missedGoal = record(
            date: date(2026, 3, 4, calendar: calendar),
            miles: 2,
            duration: 1_500,
            goal: 3
        )

        let unknownGoal = record(
            date: date(2026, 4, 4, calendar: calendar),
            miles: 6,
            duration: 3_600,
            goal: 0
        )

        let record = WorkoutTrendEngine(
            workouts: [completedGoal, missedGoal, unknownGoal],
            calendar: calendar,
            referenceDate: date(2026, 4, 20, calendar: calendar)
        ).battleRecord

        XCTAssertEqual(record.totalMiles, 13, accuracy: 0.0001)
        XCTAssertEqual(record.workoutCount, 3)
        XCTAssertEqual(record.completedGoals, 1)
    }

    private func record(
        date: Date,
        miles: Double,
        duration: TimeInterval,
        steps: Int = 0,
        heartRate: Double? = nil,
        calories: Double? = nil,
        cadence: Double? = nil,
        goal: Double
    ) -> WorkoutRecord {
        WorkoutRecord(
            startedAt: date,
            endedAt: date.addingTimeInterval(duration),
            goalMiles: goal,
            completedMiles: miles,
            steps: steps,
            averageHeartRate: heartRate,
            activeCalories: calories,
            averageCadenceSPM: cadence,
            duration: duration
        )
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day
            )
        )!
    }
}
