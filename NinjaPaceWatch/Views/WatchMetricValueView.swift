//
//  WatchMetricValueView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import SwiftUI

struct WatchMetricValueView: View {
    let metric: WatchFocusMetric
    @ObservedObject var manager: WatchWorkoutManager
    let theme: WatchTheme
    var size: CGFloat = 54
    var identifier: String? = nil

    var body: some View {
        VStack(spacing: 1) {
            Text(metric.value(from: manager))
                .font(.system(size: size, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryTextColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .contentTransition(.identity)
                .accessibilityIdentifier(identifier ?? metric.accessibilityIdentifier)
                .accessibilityLabel(metric.accessibilityLabel)
                .accessibilityValue(metric.value(from: manager) + " " + metric.unit)
            Text(metric.unit)
                .font(.system(size: size < 40 ? 9 : 12, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.secondaryTextColor)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
@MainActor
private struct WatchMetricValuePreviewHost: View {
    @StateObject private var manager: WatchWorkoutManager

    let metric: WatchFocusMetric
    let theme: WatchTheme
    let size: CGFloat

    init(
        metric: WatchFocusMetric,
        theme: WatchTheme = .ninja,
        size: CGFloat = 54,
        configure: (WatchWorkoutManager) -> Void
    ) {
        let manager = WatchWorkoutManager()
        manager.themeKey = theme.rawValue
        configure(manager)

        _manager = StateObject(wrappedValue: manager)
        self.metric = metric
        self.theme = theme
        self.size = size
    }

    var body: some View {
        ZStack {
            WatchDashboardBackground(theme: theme)

            WatchMetricValueView(
                metric: metric,
                manager: manager,
                theme: theme,
                size: size
            )
            .padding()
        }
    }
}

#Preview("🥷 Metric — Distance") {
    WatchMetricValuePreviewHost(
        metric: .distance,
        theme: .ninja
    ) { manager in
        manager.miles = 3.14
    }
}

#Preview("🥷 Metric — Pace") {
    WatchMetricValuePreviewHost(
        metric: .pace,
        theme: .ninja
    ) { manager in
        manager.miles = 3.14
        manager.elapsedSeconds = 28 * 60 + 10
        manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
    }
}

#Preview("🤖 Metric — Heart Rate") {
    WatchMetricValuePreviewHost(
        metric: .heartRate,
        theme: .cyborg
    ) { manager in
        manager.hr = 151
    }
}

#Preview("🪓 Metric — Calories") {
    WatchMetricValuePreviewHost(
        metric: .calories,
        theme: .viking
    ) { manager in
        manager.activeCalories = 701
    }
}

#Preview("🏴‍☠️ Metric — Steps") {
    WatchMetricValuePreviewHost(
        metric: .steps,
        theme: .pirate
    ) { manager in
        manager.steps = 10_420
    }
}

#Preview("🛡️ Metric — Elapsed") {
    WatchMetricValuePreviewHost(
        metric: .elapsed,
        theme: .spartan
    ) { manager in
        manager.elapsedSeconds = 62 * 60 + 18
        manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
    }
}

#Preview("🥷 Metric — Compact") {
    WatchMetricValuePreviewHost(
        metric: .heartRate,
        theme: .ninja,
        size: 30
    ) { manager in
        manager.hr = 142
    }
}
#endif
