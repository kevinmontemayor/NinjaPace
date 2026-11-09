//
//  WorkoutTrendPeriod.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 9/7/26.
//

import Foundation

enum WorkoutTrendScope: String, CaseIterable, Identifiable {
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }

    var comparisonLabel: String {
        switch self {
        case .monthly: return "last month"
        case .yearly: return "last year"
        }
    }

    var periodTitle: String {
        switch self {
        case .monthly: return "Month"
        case .yearly: return "Year"
        }
    }

    func label(for date: Date) -> String {
        switch self {
        case .monthly:
            return date.formatted(.dateTime.month(.abbreviated))
        case .yearly:
            return date.formatted(.dateTime.year())
        }
    }

    func fullLabel(for date: Date) -> String {
        switch self {
        case .monthly:
            return date.formatted(.dateTime.month(.wide).year())
        case .yearly:
            return date.formatted(.dateTime.year())
        }
    }
}

enum WorkoutTrendDirection {
    case improved
    case even
    case declined
    case unavailable
}

enum WorkoutTrendMetric: String, CaseIterable, Identifiable {
    case miles = "Miles"
    case workouts = "Workouts"
    case duration = "Duration"
    case steps = "Steps"
    case averageDistance = "Avg Distance"
    case pace = "Avg Pace"
    case averageHeartRate = "Avg Heart Rate"
    case calories = "Calories"
    case cadence = "Cadence"
    case goalRate = "Goal Rate"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .miles: return "road.lanes"
        case .workouts: return "figure.run"
        case .duration: return "timer"
        case .steps: return "figure.walk"
        case .averageDistance: return "ruler"
        case .pace: return "speedometer"
        case .averageHeartRate: return "heart.fill"
        case .calories: return "flame.fill"
        case .cadence: return "metronome"
        case .goalRate: return "target"
        }
    }

    var chartSubtitle: String {
        switch self {
        case .miles: return "Total distance"
        case .workouts: return "Workout count"
        case .duration: return "Total active training time"
        case .steps: return "Total recorded steps"
        case .averageDistance: return "Average positive-distance"
        case .pace: return "Distance-weighted active pace"
        case .averageHeartRate: return "Time-weighted average HR"
        case .calories: return "Recorded active calories"
        case .cadence: return "Time-weighted average cadence"
        case .goalRate: return "Known goals completed"
        }
    }

    var bestTitle: String {
        switch self {
        case .miles: return "High Mileage"
        case .workouts: return "Most Active"
        case .duration: return "Most Training Time"
        case .steps: return "Most Steps"
        case .averageDistance: return "Longest Avg Distance"
        case .pace: return "Fastest Pace"
        case .averageHeartRate: return "Peak Avg Heart Rate"
        case .calories: return "Most Active Calories"
        case .cadence: return "Highest Cadence"
        case .goalRate: return "Best Goal Rate"
        }
    }

    var usesLineChart: Bool {
        switch self {
        case .averageDistance, .pace, .averageHeartRate, .cadence:
            return true
        case .miles, .workouts, .duration, .steps, .calories, .goalRate:
            return false
        }
    }

    var minimumLineSpread: Double? {
        switch self {
        case .averageDistance: return 1
        case .pace: return 30
        case .averageHeartRate: return 10
        case .cadence: return 10
        default: return nil
        }
    }

    func value(for period: WorkoutTrendPeriod) -> Double? {
        switch self {
        case .miles:
            return period.totalMiles
        case .workouts:
            return Double(period.workoutCount)
        case .duration:
            return period.totalActiveDuration
        case .steps:
            return Double(period.totalSteps)
        case .averageDistance:
            return period.averageDistanceMiles
        case .pace:
            return period.averagePaceSecondsPerMile
        case .averageHeartRate:
            return period.averageHeartRateBPM
        case .calories:
            if period.workoutCount == 0 { return 0 }
            return period.recordedActiveCalories
        case .cadence:
            return period.averageCadenceSPM
        case .goalRate:
            return period.goalCompletionRatePercent
        }
    }

    func formattedValue(for period: WorkoutTrendPeriod) -> String {
        switch self {
        case .miles:
            return "\(period.totalMiles.formatted(.number.precision(.fractionLength(2)))) mi"
        case .workouts:
            return "\(period.workoutCount)"
        case .duration:
            return Self.formatDuration(period.totalActiveDuration)
        case .steps:
            return period.totalSteps.formatted()
        case .averageDistance:
            guard let distance = period.averageDistanceMiles else { return "—" }
            return "\(distance.formatted(.number.precision(.fractionLength(2)))) mi"
        case .pace:
            guard let pace = period.averagePaceSecondsPerMile else { return "—" }
            return "\(Self.formatPace(pace)) /mi"
        case .averageHeartRate:
            guard let heartRate = period.averageHeartRateBPM else { return "—" }
            return "\(heartRate.formatted(.number.precision(.fractionLength(0)))) bpm"
        case .calories:
            guard let calories = period.recordedActiveCalories else { return "—" }
            return "\(calories.formatted(.number.precision(.fractionLength(0)))) kcal"
        case .cadence:
            guard let cadence = period.averageCadenceSPM else { return "—" }
            return "\(cadence.formatted(.number.precision(.fractionLength(0)))) spm"
        case .goalRate:
            guard let rate = period.goalCompletionRatePercent else { return "—" }
            return "\(Int(rate.rounded()))%"
        }
    }

    func axisLabel(_ value: Double) -> String {
        switch self {
        case .miles:
            return value.formatted(.number.precision(.fractionLength(0...1)))
        case .workouts:
            return "\(Int(value.rounded()))"
        case .duration:
            return Self.formatCompactDuration(value)
        case .steps:
            return Self.formatCompactCount(value)
        case .averageDistance:
            return value.formatted(.number.precision(.fractionLength(0...1)))
        case .pace:
            return Self.formatPace(value)
        case .averageHeartRate:
            return "\(Int(value.rounded()))"
        case .calories:
            return Self.formatCompactCount(value)
        case .cadence:
            return "\(Int(value.rounded()))"
        case .goalRate:
            return "\(Int(value.rounded()))%"
        }
    }

    func direction(current: WorkoutTrendPeriod, previous: WorkoutTrendPeriod?) -> WorkoutTrendDirection {
        guard let previous,
              let currentValue = value(for: current),
              let previousValue = value(for: previous) else {
            return .unavailable
        }

        let delta = currentValue - previousValue
        let threshold: Double

        switch self {
        case .miles, .averageDistance:
            threshold = 0.005
        case .workouts, .steps:
            threshold = 0.5
        case .duration:
            threshold = 30
        case .pace, .averageHeartRate, .calories, .cadence, .goalRate:
            threshold = 0.5
        }

        if abs(delta) < threshold { return .even }

        if self == .pace {
            return delta < 0 ? .improved : .declined
        }

        return delta > 0 ? .improved : .declined
    }

    func comparisonText(current: WorkoutTrendPeriod, previous: WorkoutTrendPeriod?, scope: WorkoutTrendScope) -> String {
        guard let previous else {
            return scope == .monthly ? "First month in this trend window" : "First year in this trend window"
        }

        switch self {
        case .miles:
            let delta = current.totalMiles - previous.totalMiles
            return Self.deltaText(delta, unit: "mi", comparisonLabel: scope.comparisonLabel, fractionDigits: 1)

        case .workouts:
            let delta = current.workoutCount - previous.workoutCount
            if delta == 0 { return "Same workout count as \(scope.comparisonLabel)" }
            let arrow = delta > 0 ? "↑" : "↓"
            let magnitude = abs(delta)
            let noun = magnitude == 1 ? "workout" : "workouts"
            return "\(arrow) \(magnitude) \(noun) vs \(scope.comparisonLabel)"

        case .duration:
            let delta = current.totalActiveDuration - previous.totalActiveDuration
            if abs(delta) < 30 { return "Same active time as \(scope.comparisonLabel)" }
            let arrow = delta > 0 ? "↑" : "↓"
            return "\(arrow) \(Self.formatDuration(abs(delta))) vs \(scope.comparisonLabel)"

        case .steps:
            let delta = current.totalSteps - previous.totalSteps
            if delta == 0 { return "Same step count as \(scope.comparisonLabel)" }
            let arrow = delta > 0 ? "↑" : "↓"
            return "\(arrow) \(abs(delta).formatted()) steps vs \(scope.comparisonLabel)"

        case .averageDistance:
            guard let currentDistance = current.averageDistanceMiles,
                  let previousDistance = previous.averageDistanceMiles else {
                return "Not enough distance data to compare"
            }
            let delta = currentDistance - previousDistance
            return Self.deltaText(delta, unit: "mi avg", comparisonLabel: scope.comparisonLabel, fractionDigits: 2)

        case .pace:
            guard let currentPace = current.averagePaceSecondsPerMile,
                  let previousPace = previous.averagePaceSecondsPerMile else {
                return "Not enough pace data to compare"
            }
            let improvement = previousPace - currentPace
            if abs(improvement) < 0.5 { return "Same average pace as \(scope.comparisonLabel)" }
            let arrow = improvement > 0 ? "↑" : "↓"
            let word = improvement > 0 ? "faster" : "slower"
            return "\(arrow) \(Self.formatPace(abs(improvement))) /mi \(word) vs \(scope.comparisonLabel)"

        case .averageHeartRate:
            guard let currentHeartRate = current.averageHeartRateBPM,
                  let previousHeartRate = previous.averageHeartRateBPM else {
                return "Not enough heart-rate data to compare"
            }
            let delta = currentHeartRate - previousHeartRate
            if abs(delta) < 0.5 { return "Same average heart rate as \(scope.comparisonLabel)" }
            let arrow = delta > 0 ? "↑" : "↓"
            return "\(arrow) \(abs(delta).formatted(.number.precision(.fractionLength(0)))) bpm vs \(scope.comparisonLabel)"

        case .calories:
            guard let currentCalories = current.recordedActiveCalories,
                  let previousCalories = previous.recordedActiveCalories else {
                return "Not enough calorie data to compare"
            }
            let delta = currentCalories - previousCalories
            if abs(delta) < 0.5 { return "Same active calories as \(scope.comparisonLabel)" }
            let arrow = delta > 0 ? "↑" : "↓"
            return "\(arrow) \(abs(delta).formatted(.number.precision(.fractionLength(0)))) kcal vs \(scope.comparisonLabel)"

        case .cadence:
            guard let currentCadence = current.averageCadenceSPM,
                  let previousCadence = previous.averageCadenceSPM else {
                return "Not enough cadence data to compare"
            }
            let delta = currentCadence - previousCadence
            if abs(delta) < 0.5 { return "Same average cadence as \(scope.comparisonLabel)" }
            let arrow = delta > 0 ? "↑" : "↓"
            return "\(arrow) \(abs(delta).formatted(.number.precision(.fractionLength(0)))) spm vs \(scope.comparisonLabel)"

        case .goalRate:
            guard let currentRate = current.goalCompletionRatePercent,
                  let previousRate = previous.goalCompletionRatePercent else {
                return "Not enough known-goal data to compare"
            }
            let delta = currentRate - previousRate
            if abs(delta) < 0.5 { return "Same goal rate as \(scope.comparisonLabel)" }
            let arrow = delta > 0 ? "↑" : "↓"
            return "\(arrow) \(Int(abs(delta).rounded())) pts vs \(scope.comparisonLabel)"
        }
    }

    static func bestPeriod(in periods: [WorkoutTrendPeriod], metric: WorkoutTrendMetric) -> WorkoutTrendPeriod? {
        let comparable = periods.compactMap { period -> (WorkoutTrendPeriod, Double)? in
            guard period.workoutCount > 0, let value = metric.value(for: period) else { return nil }
            return (period, value)
        }

        switch metric {
        case .pace:
            return comparable.filter { $0.1 > 0 }.min(by: { $0.1 < $1.1 })?.0
        case .miles, .workouts, .duration, .steps, .averageDistance, .averageHeartRate, .calories, .cadence, .goalRate:
            return comparable.max(by: { $0.1 < $1.1 })?.0
        }
    }

    static func formatPace(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "—" }
        let rounded = Int(seconds.rounded())
        return String(format: "%d:%02d", rounded / 60, rounded % 60)
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "—" }
        let totalSeconds = Int(seconds.rounded())
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60

        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }

        if minutes > 0 {
            return "\(minutes)m"
        }

        return "\(totalSeconds)s"
    }

    private static func formatCompactDuration(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "—" }
        if seconds >= 3_600 {
            return "\((seconds / 3_600).formatted(.number.precision(.fractionLength(0...1))))h"
        }
        return "\(Int((seconds / 60).rounded()))m"
    }

    private static func formatCompactCount(_ value: Double) -> String {
        guard value.isFinite, value >= 0 else { return "—" }
        if value >= 1_000_000 {
            return "\((value / 1_000_000).formatted(.number.precision(.fractionLength(0...1))))M"
        }
        if value >= 1_000 {
            return "\((value / 1_000).formatted(.number.precision(.fractionLength(0...1))))K"
        }
        return "\(Int(value.rounded()))"
    }

    private static func deltaText(_ delta: Double, unit: String, comparisonLabel: String, fractionDigits: Int) -> String {
        if abs(delta) < 0.005 { return "Same as \(comparisonLabel)" }
        let arrow = delta > 0 ? "↑" : "↓"
        let magnitude = abs(delta).formatted(.number.precision(.fractionLength(fractionDigits)))
        return "\(arrow) \(magnitude) \(unit) vs \(comparisonLabel)"
    }
}

struct WorkoutTrendPeriod: Identifiable, Equatable {
    let startDate: Date
    let workoutCount: Int
    let totalMiles: Double
    let paceMiles: Double
    let paceActiveDuration: TimeInterval
    let totalActiveDuration: TimeInterval
    let totalSteps: Int
    let distanceWorkoutCount: Int
    let heartRateWeightedSum: Double
    let heartRateWeight: TimeInterval
    let recordedActiveCalories: Double?
    let activeCaloriesWorkoutCount: Int
    let cadenceWeightedSum: Double
    let cadenceWeight: TimeInterval
    let knownGoalCount: Int
    let completedGoalCount: Int

    var id: Date { startDate }

    var averageDistanceMiles: Double? {
        guard distanceWorkoutCount > 0 else { return nil }
        return totalMiles / Double(distanceWorkoutCount)
    }

    var averagePaceSecondsPerMile: Double? {
        guard paceMiles > 0, paceActiveDuration > 0 else { return nil }
        return paceActiveDuration / paceMiles
    }

    var averageHeartRateBPM: Double? {
        guard heartRateWeight > 0 else { return nil }
        return heartRateWeightedSum / heartRateWeight
    }

    var averageCadenceSPM: Double? {
        guard cadenceWeight > 0 else { return nil }
        return cadenceWeightedSum / cadenceWeight
    }

    var goalCompletionRatePercent: Double? {
        guard knownGoalCount > 0 else { return nil }
        return Double(completedGoalCount) / Double(knownGoalCount) * 100
    }
}
