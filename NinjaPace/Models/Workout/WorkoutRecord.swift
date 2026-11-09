//
//  WorkoutRecord.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/4/26.
//

import Foundation
import SwiftData

@Model
final class WorkoutRecord {

    @Attribute(.unique)
    var id: UUID

    var startedAt: Date
    var endedAt: Date
    var goalMiles: Double
    var completedMiles: Double
    var steps: Int

    // MARK: - Heart Rate

    var averageHeartRate: Double?
    var peakHeartRate: Double?

    // MARK: - Calories

    var activeCalories: Double?
    var totalCalories: Double?

    // MARK: - Cadence

    /// Average steps per minute captured directly
    /// from the workout when available.
    var averageCadenceSPM: Double?

    // MARK: - Elevation

    /// Positive elevation gain in feet.
    var elevationGainFeet: Double?

    // MARK: - Speed / Pace

    var averagePaceSecondsPerMile: Double?

    /// Miles per hour.
    var averageSpeedMPH: Double?

    /// Peak recorded speed in miles per hour.
    var peakSpeedMPH: Double?

    // MARK: - Timing

    var duration: TimeInterval

    /// Total time the workout was paused.
    var pausedDuration: TimeInterval?

    // MARK: - Goal

    var wasGoalCompleted: Bool
    var wasScheduledRestDay: Bool
    var goalCompletionPercentage: Double
    var milesOverGoal: Double

    // MARK: - Classification

    var workoutTypeRawValue: String

    /// Example: indoor, outdoor.
    var workoutLocationRawValue: String?

    var source: String

    // MARK: - Rich Historical Data

    /// JSON encoded `[WorkoutSplit]`.
    var splitsData: Data?

    /// JSON encoded `[HeartRateZoneSummary]`.
    var heartRateZonesData: Data?

    /// JSON encoded `[String]`.
    ///
    /// Store raw achievement identifiers so the workout
    /// permanently remembers what it unlocked.
    var unlockedAchievementsData: Data?

    init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date,
        goalMiles: Double,
        completedMiles: Double,
        steps: Int,
        averageHeartRate: Double? = nil,
        peakHeartRate: Double? = nil,
        activeCalories: Double? = nil,
        totalCalories: Double? = nil,
        averageCadenceSPM: Double? = nil,
        elevationGainFeet: Double? = nil,
        duration: TimeInterval,
        pausedDuration: TimeInterval? = nil,
        wasScheduledRestDay: Bool = false,
        averagePaceSecondsPerMile: Double? = nil,
        averageSpeedMPH: Double? = nil,
        peakSpeedMPH: Double? = nil,
        workoutTypeRawValue: String = "running",
        workoutLocationRawValue: String? = nil,
        source: String = "NinjaPace",
        splits: [WorkoutSplit] = [],
        heartRateZones: [HeartRateZoneSummary] = [],
        unlockedAchievementIDs: [String] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.goalMiles = goalMiles
        self.completedMiles = completedMiles
        self.steps = steps

        self.averageHeartRate = averageHeartRate
        self.peakHeartRate = peakHeartRate

        self.activeCalories = activeCalories
        self.totalCalories = totalCalories

        self.averageCadenceSPM = averageCadenceSPM
        self.elevationGainFeet = elevationGainFeet

        self.duration = duration
        self.pausedDuration = pausedDuration
        
        self.wasScheduledRestDay = wasScheduledRestDay
        
        let goalMetrics = Self.goalMetrics(completedMiles: completedMiles, goalMiles: goalMiles)
        self.wasGoalCompleted = goalMetrics.wasCompleted
        self.goalCompletionPercentage = goalMetrics.completionPercentage
        self.milesOverGoal = goalMetrics.milesOverGoal

        self.averagePaceSecondsPerMile = averagePaceSecondsPerMile
        self.averageSpeedMPH = averageSpeedMPH
        self.peakSpeedMPH = peakSpeedMPH

        self.workoutTypeRawValue = workoutTypeRawValue
        self.workoutLocationRawValue = workoutLocationRawValue
        self.source = source

        self.splitsData = Self.encode(splits)
        self.heartRateZonesData = Self.encode(heartRateZones)
        self.unlockedAchievementsData = Self.encode(unlockedAchievementIDs)
    }
}

extension WorkoutRecord {

    /// Recalculate every goal-derived value together after a historical correction.
    @discardableResult
    func updateGoalMiles(_ miles: Double) -> Bool {
        guard miles.isFinite, miles > 0 else { return false }
        
        let metrics = Self.goalMetrics(completedMiles: completedMiles, goalMiles: miles)
        goalMiles = miles
        wasGoalCompleted = metrics.wasCompleted
        goalCompletionPercentage = metrics.completionPercentage
        milesOverGoal = metrics.milesOverGoal
        
        return true
    }


    var splits: [WorkoutSplit] {
        get {
            Self.decode(
                [WorkoutSplit].self,
                from: splitsData
            ) ?? []
        }
        set {
            splitsData = Self.encode(newValue)
        }
    }

    var heartRateZones: [HeartRateZoneSummary] {
        get {
            Self.decode(
                [HeartRateZoneSummary].self,
                from: heartRateZonesData
            ) ?? []
        }
        set {
            heartRateZonesData = Self.encode(newValue)
        }
    }

    var unlockedAchievementIDs: [String] {
        get {
            Self.decode(
                [String].self,
                from: unlockedAchievementsData
            ) ?? []
        }
        set {
            unlockedAchievementsData = Self.encode(newValue)
        }
    }

    /// Prefer cadence captured from the workout,
    /// but gracefully derive it for older records.
    var resolvedAverageCadenceSPM: Double? {
        if let averageCadenceSPM, averageCadenceSPM > 0 {
            return averageCadenceSPM
        }

        guard duration > 0, steps > 0 else { return nil }

        let minutes = duration / 60
        return Double(steps) / minutes
    }

    var resolvedAverageSpeedMPH: Double? {
        if let averageSpeedMPH, averageSpeedMPH > 0 {
            return averageSpeedMPH
        }

        guard completedMiles > 0.001, activeDuration > 0 else { return nil }

        return completedMiles / (activeDuration / 3_600)
    }

    var resolvedPeakSpeedMPH: Double? {
        guard let peakSpeedMPH, peakSpeedMPH > 0 else { return nil }
        return peakSpeedMPH
    }

    var activeDuration: TimeInterval {
        max(0, duration - (pausedDuration ?? 0))
    }

    private static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - Goal Calculations

    /// NinjaPace presents historical mileage to two decimal places.
    /// Goal-derived values use the same precision so the stored state
    /// always agrees with what the runner sees in the UI.
    static func goalMetrics(completedMiles: Double, goalMiles: Double) -> (
        wasCompleted: Bool,
        completionPercentage: Double,
        milesOverGoal: Double
    ) {
        guard completedMiles.isFinite,
              goalMiles.isFinite,
              goalMiles > 0 else {
            return (false, 0, 0)
        }
        
        let completedHundredths = mileageHundredths(completedMiles)
        let goalHundredths = mileageHundredths(goalMiles)
        
        guard goalHundredths > 0 else {
            return (false, 0, 0)
        }
        
        let wasCompleted = completedHundredths >= goalHundredths
        let completionPercentage = Double(completedHundredths) / Double(goalHundredths) * 100
        let milesOverGoal = Double(max(0, completedHundredths - goalHundredths)) / 100
        
        return (wasCompleted, completionPercentage, milesOverGoal)
    }

    static func goalWasCompleted(completedMiles: Double, goalMiles: Double) -> Bool {
        goalMetrics(completedMiles: completedMiles, goalMiles: goalMiles).wasCompleted
    }

    private static func mileageHundredths(_ miles: Double) -> Int {
        Int((miles * 100).rounded())
    }
}
