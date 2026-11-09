//
//  WorkoutRecordTests.swift
//  NinjaPaceTests
//
//  Created by Kevin Montemayor on 10/18/26.
//

import Foundation
import Testing
@testable import NinjaPace

@Suite("Workout Record")
struct WorkoutRecordTests {

    @Test("Correcting a recovered goal updates completion in both directions")
    func correctHistoricalGoal() {
        let record = makeRecord(goalMiles: 0, completedMiles: 3.14)
        #expect(record.updateGoalMiles(3.11))
        #expect(record.wasGoalCompleted)
        #expect(abs(record.milesOverGoal - 0.03) < 0.000001)
        #expect(abs(record.goalCompletionPercentage - 3.14 / 3.11 * 100) < 0.000001)
        #expect(record.updateGoalMiles(5))
        #expect(!record.wasGoalCompleted)
        #expect(record.milesOverGoal == 0)
        #expect(abs(record.goalCompletionPercentage - 62.8) < 0.000001)
    }

    @Test("Invalid corrections preserve the saved goal")
    func rejectsInvalidGoal() {
        let record = makeRecord(goalMiles: 3, completedMiles: 4)
        for invalid in [0.0, -1.0, Double.nan, Double.infinity] {
            #expect(!record.updateGoalMiles(invalid))
            #expect(record.goalMiles == 3)
            #expect(record.wasGoalCompleted)
            #expect(record.milesOverGoal == 1)
        }
    }

    private let tolerance = 0.000_001

    @Test("Meeting the goal exactly counts as completed")
    func exactGoalIsCompleted() {

        let record =
            makeRecord(
                goalMiles: 5.0,
                completedMiles: 5.0
            )

        #expect(record.wasGoalCompleted)

        #expect(
            abs(
                record.goalCompletionPercentage
                - 100
            )
            < tolerance
        )

        #expect(record.milesOverGoal == 0)
    }

    @Test("Finishing below the goal does not count as completed")
    func belowGoalIsNotCompleted() {

        let record =
            makeRecord(
                goalMiles: 5.0,
                completedMiles: 4.99
            )

        #expect(!record.wasGoalCompleted)
        #expect(record.milesOverGoal == 0)
    }

    @Test("Goal completion percentage can exceed 100 percent")
    func percentageCanExceedOneHundred() {

        let record =
            makeRecord(
                goalMiles: 4.0,
                completedMiles: 5.0
            )

        #expect(
            abs(
                record.goalCompletionPercentage
                - 125
            )
            < tolerance
        )

        #expect(
            abs(
                record.milesOverGoal
                - 1.0
            )
            < tolerance
        )
    }

    @Test("Zero-mile goals are not treated as completed goals")
    func zeroGoalIsHandledSafely() {

        let record =
            makeRecord(
                goalMiles: 0,
                completedMiles: 3.11,
                wasScheduledRestDay: true
            )

        #expect(!record.wasGoalCompleted)
        #expect(record.goalCompletionPercentage == 0)
        #expect(record.wasScheduledRestDay)
    }

    @Test("Active duration subtracts paused time")
    func activeDurationSubtractsPause() {

        let record =
            makeRecord(
                duration: 3_600,
                pausedDuration: 600
            )

        #expect(record.activeDuration == 3_000)
    }

    @Test("Active duration equals total duration when there was no pause")
    func activeDurationWithoutPause() {

        let record =
            makeRecord(
                duration: 3_600,
                pausedDuration: nil
            )

        #expect(record.activeDuration == 3_600)
    }

    @Test("Active duration never becomes negative")
    func activeDurationClampsToZero() {

        let record =
            makeRecord(
                duration: 300,
                pausedDuration: 600
            )

        #expect(record.activeDuration == 0)
    }

    @Test("Stored cadence wins when available")
    func storedCadenceIsPreferred() throws {

        let record =
            makeRecord(
                steps: 1_000,
                duration: 600,
                averageCadenceSPM: 171
            )

        let cadence =
            try #require(
                record.resolvedAverageCadenceSPM
            )

        #expect(cadence == 171)
    }

    @Test("Cadence is derived for older records when needed")
    func cadenceFallsBackToStepsPerMinute() throws {

        let record =
            makeRecord(
                steps: 600,
                duration: 300,
                averageCadenceSPM: nil
            )

        let cadence =
            try #require(
                record.resolvedAverageCadenceSPM
            )

        #expect(abs(cadence - 120) < tolerance)
    }

    @Test("Cadence fallback returns nil without usable inputs")
    func cadenceFallbackRequiresStepsAndDuration() {

        let noSteps =
            makeRecord(
                steps: 0,
                duration: 300,
                averageCadenceSPM: nil
            )

        let noDuration =
            makeRecord(
                steps: 600,
                duration: 0,
                averageCadenceSPM: nil
            )

        #expect(noSteps.resolvedAverageCadenceSPM == nil)
        #expect(noDuration.resolvedAverageCadenceSPM == nil)
    }

    @Test("Stored average speed wins when available")
    func storedAverageSpeedIsPreferred() throws {

        let record =
            makeRecord(
                completedMiles: 5,
                duration: 3_600,
                averageSpeedMPH: 7.25
            )

        let speed =
            try #require(
                record.resolvedAverageSpeedMPH
            )

        #expect(speed == 7.25)
    }

    @Test("Average speed fallback uses active duration")
    func averageSpeedUsesActiveDuration() throws {

        let record =
            makeRecord(
                completedMiles: 5,
                duration: 3_600,
                pausedDuration: 600,
                averageSpeedMPH: nil
            )

        let speed =
            try #require(
                record.resolvedAverageSpeedMPH
            )

        #expect(abs(speed - 6.0) < tolerance)
    }

    @Test("Average speed fallback requires distance and active duration")
    func averageSpeedFallbackRequiresUsableInputs() {

        let noDistance =
            makeRecord(
                completedMiles: 0,
                duration: 3_600,
                averageSpeedMPH: nil
            )

        let noActiveTime =
            makeRecord(
                completedMiles: 5,
                duration: 600,
                pausedDuration: 600,
                averageSpeedMPH: nil
            )

        #expect(noDistance.resolvedAverageSpeedMPH == nil)
        #expect(noActiveTime.resolvedAverageSpeedMPH == nil)
    }

    @Test("Positive peak speed is exposed")
    func peakSpeedIsResolved() throws {

        let record =
            makeRecord(
                peakSpeedMPH: 8.5
            )

        let speed =
            try #require(
                record.resolvedPeakSpeedMPH
            )

        #expect(speed == 8.5)
    }

    @Test("Missing or non-positive peak speed resolves to nil")
    func invalidPeakSpeedResolvesToNil() {

        let missing =
            makeRecord(
                peakSpeedMPH: nil
            )

        let zero =
            makeRecord(
                peakSpeedMPH: 0
            )

        #expect(missing.resolvedPeakSpeedMPH == nil)
        #expect(zero.resolvedPeakSpeedMPH == nil)
    }

    @Test("Achievement IDs survive encoding and decoding")
    func achievementIDsRoundTrip() {

        let expected = [
            "first5K",
            "tenK",
            "marathon"
        ]

        let record =
            makeRecord(
                unlockedAchievementIDs:
                    expected
            )

        #expect(
            record.unlockedAchievementIDs
            == expected
        )
    }

    @Test("Achievement IDs can be replaced after initialization")
    func achievementIDsSetterRoundTrips() {

        let record =
            makeRecord()

        record.unlockedAchievementIDs =
            [
                "halfMarathon",
                "marathon"
            ]

        #expect(
            record.unlockedAchievementIDs
            == [
                "halfMarathon",
                "marathon"
            ]
        )
    }

    @Test("Workout splits survive encoding and decoding")
    func splitsRoundTrip() throws {

        let expected =
            WorkoutSplit(
                splitNumber: 1,
                distanceMiles: 1,
                duration: 600,
                averageHeartRate: 140,
                averageCadenceSPM: 165
            )

        let record =
            makeRecord(
                splits: [
                    expected
                ]
            )

        let decoded =
            try #require(
                record.splits.first
            )

        #expect(decoded.splitNumber == 1)
        #expect(decoded.distanceMiles == 1)
        #expect(decoded.duration == 600)
    }

    @Test("Heart-rate zones survive encoding and decoding")
    func heartRateZonesRoundTrip() throws {

        let expected =
            HeartRateZoneSummary(
                zone: 3,
                minimumBPM: 140,
                maximumBPM: 154,
                duration: 900
            )

        let record =
            makeRecord(
                heartRateZones: [
                    expected
                ]
            )

        let decoded =
            try #require(
                record.heartRateZones.first
            )

        #expect(decoded.zone == 3)
        #expect(decoded.minimumBPM == 140)
        #expect(decoded.maximumBPM == 154)
        #expect(decoded.duration == 900)
    }

    private func makeRecord(
        goalMiles: Double = 5.0,
        completedMiles: Double = 5.0,
        steps: Int = 1_000,
        duration: TimeInterval = 3_600,
        pausedDuration: TimeInterval? = nil,
        wasScheduledRestDay: Bool = false,
        averageCadenceSPM: Double? = nil,
        averageSpeedMPH: Double? = nil,
        peakSpeedMPH: Double? = nil,
        splits: [WorkoutSplit] = [],
        heartRateZones: [HeartRateZoneSummary] = [],
        unlockedAchievementIDs: [String] = []
    ) -> WorkoutRecord {

        let startedAt =
            Date(
                timeIntervalSince1970:
                    1_700_000_000
            )

        return WorkoutRecord(
            startedAt: startedAt,
            endedAt:
                startedAt
                    .addingTimeInterval(
                        duration
                    ),
            goalMiles: goalMiles,
            completedMiles: completedMiles,
            steps: steps,
            averageCadenceSPM:
                averageCadenceSPM,
            duration: duration,
            pausedDuration:
                pausedDuration,
            wasScheduledRestDay:
                wasScheduledRestDay,
            averageSpeedMPH:
                averageSpeedMPH,
            peakSpeedMPH:
                peakSpeedMPH,
            splits: splits,
            heartRateZones:
                heartRateZones,
            unlockedAchievementIDs:
                unlockedAchievementIDs
        )
    }
}
