//
//  WatchFocusMetricView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import SwiftUI

struct WatchFocusMetricView: View {
    let metric: WatchFocusMetric
    @ObservedObject var manager: WatchWorkoutManager
    let theme: WatchTheme

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: metric.systemImage).foregroundStyle(theme.tint).accessibilityHidden(true)
                Text(metric.title.uppercased())
                    .font(.caption2.bold())
                    .foregroundStyle(theme.primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("focusTitle." + metric.rawValue)
                Spacer(minLength: 0)
            }
            Spacer(minLength: 0)
            WatchMetricValueView(metric: metric, manager: manager, theme: theme)
                .layoutPriority(1)
            Spacer(minLength: 0)
            context
            WatchWorkoutStatusView(manager: manager, theme: theme)
        }
        .padding(12)
    }

    @ViewBuilder private var context: some View {
        switch metric {
        case .distance:
            WatchGoalProgressView(manager: manager, theme: theme)
        case .heartRate:
            HStack {
                summary("AVG", value: manager.averageHeartRate)
                Spacer()
                summary("MAX", value: manager.peakHeartRate)
            }
        case .calories:
            Text("TOTAL  \(Int(manager.totalCalories.rounded()).formatted()) KCAL")
                .font(.caption2).monospacedDigit().foregroundStyle(theme.secondaryTextColor)
        case .pace:
            Text("AVERAGE PACE").font(.caption2).foregroundStyle(theme.secondaryTextColor)
        case .steps:
            Text("EVERY STEP COUNTS").font(.caption2).foregroundStyle(theme.secondaryTextColor)
        case .elapsed:
            Text("ACTIVE WORKOUT").font(.caption2).foregroundStyle(theme.secondaryTextColor)
        }
    }

    private func summary(_ label: String, value: Double) -> some View {
        VStack {
            Text(label).foregroundStyle(theme.secondaryTextColor)
            Text(value > 0 ? Int(value.rounded()).formatted() : "—").monospacedDigit()
                .foregroundStyle(theme.primaryTextColor)
        }.font(.caption2)
    }
}

#if DEBUG
@MainActor
private struct WatchFocusMetricPreviewHost: View {
    @StateObject private var manager: WatchWorkoutManager

    let metric: WatchFocusMetric
    let theme: WatchTheme

    init(
        metric: WatchFocusMetric,
        theme: WatchTheme = .ninja,
        configure: (WatchWorkoutManager) -> Void
    ) {
        let manager = WatchWorkoutManager()
        manager.themeKey = theme.rawValue
        configure(manager)

        _manager = StateObject(wrappedValue: manager)
        self.metric = metric
        self.theme = theme
    }

    var body: some View {
        ZStack {
            WatchDashboardBackground(theme: theme)

            WatchFocusMetricView(
                metric: metric,
                manager: manager,
                theme: theme
            )
        }
    }
}

#Preview("🥷 Focus — Distance") {
    WatchFocusMetricPreviewHost(
        metric: .distance,
        theme: .ninja
    ) { manager in
        manager.goalMiles = 5.0
        manager.miles = 3.14
        manager.running = true
        manager.paused = false
    }
}

#Preview("🥷 Focus — Pace") {
    WatchFocusMetricPreviewHost(
        metric: .pace,
        theme: .ninja
    ) { manager in
        manager.miles = 3.14
        manager.elapsedSeconds = 28 * 60 + 10
        manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
        manager.running = true
        manager.paused = false
    }
}

#Preview("🤖 Focus — Heart Rate") {
    WatchFocusMetricPreviewHost(
        metric: .heartRate,
        theme: .cyborg
    ) { manager in
        manager.hr = 151
        manager.averageHeartRate = 143
        manager.peakHeartRate = 166
        manager.running = true
        manager.paused = false
    }
}

#Preview("🪓 Focus — Calories") {
    WatchFocusMetricPreviewHost(
        metric: .calories,
        theme: .viking
    ) { manager in
        manager.activeCalories = 701
        manager.totalCalories = 824
        manager.running = true
        manager.paused = false
    }
}

#Preview("🏴‍☠️ Focus — Steps") {
    WatchFocusMetricPreviewHost(
        metric: .steps,
        theme: .pirate
    ) { manager in
        manager.steps = 10_420
        manager.running = true
        manager.paused = false
    }
}

#Preview("🛡️ Focus — Elapsed") {
    WatchFocusMetricPreviewHost(
        metric: .elapsed,
        theme: .spartan
    ) { manager in
        manager.elapsedSeconds = 62 * 60 + 18
        manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
        manager.running = true
        manager.paused = false
    }
}

#Preview("⚔️ Focus — Distance Goal Met") {
    WatchFocusMetricPreviewHost(
        metric: .distance,
        theme: .knight
    ) { manager in
        manager.goalMiles = 3.11
        manager.miles = 3.35
        manager.running = true
        manager.paused = false
    }
}

#Preview("🤖 Focus — Heart Rate Empty") {
    WatchFocusMetricPreviewHost(
        metric: .heartRate,
        theme: .cyborg
    ) { manager in
        manager.hr = 0
        manager.averageHeartRate = 0
        manager.peakHeartRate = 0
        manager.running = true
        manager.paused = false
    }
}
#endif
