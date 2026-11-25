//
//  WatchDashboardPreferences.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import SwiftUI

/// Presentation preferences only. Workout values continue to belong to the manager.
struct WatchDashboardPreferences: DynamicProperty {
    @AppStorage("watchDashboard.showCurrentTime") var showCurrentTime = true
    @AppStorage("watchDashboard.idleClockStyle") var idleClockStyleRaw = WatchIdleClockStyle.digital.rawValue
    @AppStorage("watchDashboard.featuredMetric") var featuredMetricRaw = WatchFocusMetric.distance.rawValue
    @AppStorage("watchDashboard.showOverview") var showOverview = true
    @AppStorage("watchDashboard.metrics") var metricsRaw = "distance,pace,heartRate,elapsed"

    init(store: UserDefaults? = nil) {
        _showCurrentTime = AppStorage(wrappedValue: true, "watchDashboard.showCurrentTime", store: store)
        _idleClockStyleRaw = AppStorage(wrappedValue: "digital", "watchDashboard.idleClockStyle", store: store)
        _featuredMetricRaw = AppStorage(wrappedValue: "distance", "watchDashboard.featuredMetric", store: store)
        _showOverview = AppStorage(wrappedValue: true, "watchDashboard.showOverview", store: store)
        _metricsRaw = AppStorage(wrappedValue: "distance,pace,heartRate,elapsed", "watchDashboard.metrics", store: store)
    }

    var featuredMetric: WatchFocusMetric { WatchFocusMetric(rawValue: featuredMetricRaw) ?? .distance }
    var idleClockStyle: WatchIdleClockStyle { WatchIdleClockStyle(rawValue: idleClockStyleRaw) ?? .digital }
    var enabledMetrics: [WatchFocusMetric] { Self.decodeMetrics(metricsRaw) }
    var visiblePages: [WatchDashboardPage] {
        [.home] + (showOverview ? [.overview] : []) + enabledMetrics.map(\.dashboardPage) + [.controls]
    }

    static func decodeMetrics(_ raw: String) -> [WatchFocusMetric] {
        let enabled = Set(raw.split(separator: ",").compactMap { WatchFocusMetric(rawValue: String($0)) })
        // Canonical order and stable IDs, even if stored values contain duplicates or unknown keys.
        return WatchFocusMetric.allCases.filter { enabled.contains($0) }
    }

    func enabledBinding(for metric: WatchFocusMetric) -> Binding<Bool> {
        Binding(
            get: { enabledMetrics.contains(metric) },
            set: { enabled in
                var selection = Set(enabledMetrics)
                if enabled { selection.insert(metric) } else { selection.remove(metric) }
                metricsRaw = WatchFocusMetric.allCases.filter { selection.contains($0) }
                    .map(\.rawValue).joined(separator: ",")
            }
        )
    }
}
