//
//  WatchDashboardPage.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import Foundation

enum WatchDashboardPage: String, Hashable, Identifiable {
    // Navigation entry above Home; never part of the customizable workout pages.
    case idleClock
    case home, overview, distance, pace, heartRate, calories, steps, elapsed, controls

    var id: String { rawValue }
    var metric: WatchFocusMetric? { WatchFocusMetric(rawValue: rawValue) }
}
