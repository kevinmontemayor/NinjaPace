//
//  WatchFocusMetric.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import Foundation

enum WatchFocusMetric: String, CaseIterable, Identifiable {
    case distance, pace, heartRate, calories, steps, elapsed

    var id: String { rawValue }
    var dashboardPage: WatchDashboardPage {
        switch self {
        case .distance: return .distance
        case .pace: return .pace
        case .heartRate: return .heartRate
        case .calories: return .calories
        case .steps: return .steps
        case .elapsed: return .elapsed
        }
    }
    var title: String {
        switch self {
        case .distance: return "Distance"
        case .pace: return "Pace"
        case .heartRate: return "Heart Rate"
        case .calories: return "Active Calories"
        case .steps: return "Steps"
        case .elapsed: return "Elapsed"
        }
    }
    var systemImage: String {
        switch self {
        case .distance: return "figure.run"
        case .pace: return "speedometer"
        case .heartRate: return "heart.fill"
        case .calories: return "flame.fill"
        case .steps: return "shoeprints.fill"
        case .elapsed: return "stopwatch"
        }
    }
    var unit: String {
        switch self {
        case .distance: return "MI"
        case .pace: return "/ MI"
        case .heartRate: return "BPM"
        case .calories: return "KCAL"
        case .steps: return "STEPS"
        case .elapsed: return "HRS : MIN : SEC"
        }
    }
    var accessibilityLabel: String { title }
    var accessibilityIdentifier: String { rawValue + "Metric" }

    @MainActor
    func value(from manager: WatchWorkoutManager) -> String {
        switch self {
        case .distance: return manager.miles.formatted(.number.precision(.fractionLength(2)))
        case .pace: return manager.paceString
        case .heartRate: return manager.hr > 0 ? manager.hr.formatted() : "—"
        case .calories: return Int(manager.activeCalories.rounded()).formatted()
        case .steps: return manager.steps.formatted()
        case .elapsed: return manager.elapsedText
        }
    }
}
