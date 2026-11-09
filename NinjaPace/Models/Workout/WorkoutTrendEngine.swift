//
//  WorkoutTrendEngine.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 9/7/26.
//

import Foundation

struct WorkoutBattleRecord: Equatable {
    let totalMiles: Double
    let workoutCount: Int
    let completedGoals: Int
}

struct WorkoutTrendEngine {
    let workouts: [WorkoutRecord]
    let calendar: Calendar
    let referenceDate: Date

    init(workouts: [WorkoutRecord], calendar: Calendar = .current, referenceDate: Date = .now) {
        self.workouts = workouts
        self.calendar = calendar
        self.referenceDate = referenceDate
    }

    var battleRecord: WorkoutBattleRecord {
        let totalMiles = workouts.reduce(0.0) { partial, workout in
            guard workout.completedMiles.isFinite, workout.completedMiles > 0 else { return partial }
            return partial + workout.completedMiles
        }

        let completedGoals = workouts.filter { workout in
            workout.goalMiles.isFinite
                && workout.goalMiles > 0
                && workout.wasGoalCompleted
        }.count

        return WorkoutBattleRecord(
            totalMiles: totalMiles,
            workoutCount: workouts.count,
            completedGoals: completedGoals
        )
    }

    func periods(for scope: WorkoutTrendScope) -> [WorkoutTrendPeriod] {
        guard !workouts.isEmpty else { return [] }

        let grouped = Dictionary(grouping: workouts) {
            periodStart(for: $0.startedAt, scope: scope)
        }

        guard let earliest = grouped.keys.min(),
              let latestWorkout = grouped.keys.max() else {
            return []
        }

        let current = periodStart(for: referenceDate, scope: scope)
        let latest = max(latestWorkout, current)

        return periodStarts(from: earliest, through: latest, scope: scope)
            .map { startDate in
                makePeriod(startDate: startDate, workouts: grouped[startDate] ?? [])
            }
    }

    func recentPeriods(for scope: WorkoutTrendScope, limit: Int) -> [WorkoutTrendPeriod] {
        guard limit > 0 else { return [] }
        return Array(periods(for: scope).suffix(limit))
    }

    private func makePeriod(startDate: Date, workouts: [WorkoutRecord]) -> WorkoutTrendPeriod {
        let distanceEligible = workouts.filter {
            $0.completedMiles.isFinite && $0.completedMiles > 0
        }

        let totalMiles = distanceEligible.reduce(0.0) {
            $0 + $1.completedMiles
        }

        let paceEligible = workouts.filter {
            $0.completedMiles.isFinite
                && $0.completedMiles > 0
                && $0.activeDuration.isFinite
                && $0.activeDuration > 0
        }

        let paceMiles = paceEligible.reduce(0.0) { $0 + $1.completedMiles }
        let paceActiveDuration = paceEligible.reduce(0.0) { $0 + $1.activeDuration }

        let totalActiveDuration = workouts.reduce(0.0) { partial, workout in
            guard workout.activeDuration.isFinite, workout.activeDuration > 0 else { return partial }
            return partial + workout.activeDuration
        }

        let totalSteps = workouts.reduce(0) { partial, workout in
            partial + max(0, workout.steps)
        }

        let heartRateEligible = workouts.compactMap { workout -> (Double, TimeInterval)? in
            guard let heartRate = workout.averageHeartRate,
                  heartRate.isFinite,
                  heartRate > 0,
                  workout.activeDuration.isFinite,
                  workout.activeDuration > 0 else {
                return nil
            }
            return (heartRate, workout.activeDuration)
        }

        let heartRateWeightedSum = heartRateEligible.reduce(0.0) {
            $0 + $1.0 * $1.1
        }
        let heartRateWeight = heartRateEligible.reduce(0.0) {
            $0 + $1.1
        }

        let calorieValues = workouts.compactMap { workout -> Double? in
            guard let calories = workout.activeCalories,
                  calories.isFinite,
                  calories >= 0 else {
                return nil
            }
            return calories
        }

        let recordedActiveCalories = calorieValues.isEmpty
            ? nil
            : calorieValues.reduce(0, +)

        let cadenceEligible = workouts.compactMap { workout -> (Double, TimeInterval)? in
            guard let cadence = workout.resolvedAverageCadenceSPM,
                  cadence.isFinite,
                  cadence > 0,
                  workout.activeDuration.isFinite,
                  workout.activeDuration > 0 else {
                return nil
            }
            return (cadence, workout.activeDuration)
        }

        let cadenceWeightedSum = cadenceEligible.reduce(0.0) {
            $0 + $1.0 * $1.1
        }
        let cadenceWeight = cadenceEligible.reduce(0.0) {
            $0 + $1.1
        }

        let knownGoalWorkouts = workouts.filter {
            $0.goalMiles.isFinite && $0.goalMiles > 0
        }

        return WorkoutTrendPeriod(
            startDate: startDate,
            workoutCount: workouts.count,
            totalMiles: totalMiles,
            paceMiles: paceMiles,
            paceActiveDuration: paceActiveDuration,
            totalActiveDuration: totalActiveDuration,
            totalSteps: totalSteps,
            distanceWorkoutCount: distanceEligible.count,
            heartRateWeightedSum: heartRateWeightedSum,
            heartRateWeight: heartRateWeight,
            recordedActiveCalories: recordedActiveCalories,
            activeCaloriesWorkoutCount: calorieValues.count,
            cadenceWeightedSum: cadenceWeightedSum,
            cadenceWeight: cadenceWeight,
            knownGoalCount: knownGoalWorkouts.count,
            completedGoalCount: knownGoalWorkouts.filter(\.wasGoalCompleted).count
        )
    }

    private func periodStart(for date: Date, scope: WorkoutTrendScope) -> Date {
        let components: DateComponents

        switch scope {
        case .monthly:
            components = calendar.dateComponents([.year, .month], from: date)
        case .yearly:
            components = calendar.dateComponents([.year], from: date)
        }

        return calendar.date(from: components) ?? date
    }

    private func periodStarts(from first: Date, through last: Date, scope: WorkoutTrendScope) -> [Date] {
        let component: Calendar.Component = scope == .monthly ? .month : .year
        var dates: [Date] = []
        var cursor = first

        while cursor <= last {
            dates.append(cursor)

            guard let next = calendar.date(byAdding: component, value: 1, to: cursor),
                  next > cursor else {
                break
            }

            cursor = next
        }

        return dates
    }
}
