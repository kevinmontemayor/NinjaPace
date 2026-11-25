//
//  WatchWorkoutOverviewView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import SwiftUI

struct WatchWorkoutOverviewView: View {
    @ObservedObject var manager: WatchWorkoutManager

    let theme: WatchTheme
    let isVisible: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("OVERVIEW")
                    .font(.caption2.bold())
                    .foregroundStyle(theme.primaryTextColor)
                    .accessibilityIdentifier("overviewTitle")

                Spacer()

                WatchWorkoutStatusView(manager: manager, theme: theme)

                WatchAnimatedThemeIconView(
                    theme: theme,
                    tint: theme.tint,
                    size: 16,
                    isActive: isVisible && manager.running && !manager.paused
                )
                .accessibilityHidden(true)
            }

            Spacer(minLength: 0)

            VStack(spacing: 7) {
                row(.elapsed, label: "Elapsed")
                row(.pace, label: "Pace")
                row(
                    .heartRate,
                    label: "HR",
                    suffix: manager.hr > 0 ? " bpm" : ""
                )
                row(.calories, label: "Calories", suffix: " kcal")
                row(.steps, label: "Steps")
            }

            Spacer(minLength: 0)

            WatchGoalProgressView(
                manager: manager,
                theme: theme
            )
        }
        .padding(12)
    }

    private func row(_ metric: WatchFocusMetric, label: String, suffix: String = "") -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.secondaryTextColor)

            Spacer(minLength: 4)

            Text(metric.value(from: manager) + suffix)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryTextColor)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier(metric.accessibilityIdentifier)
        }
        .lineLimit(1)
    }
}

#if DEBUG
@MainActor
private struct WatchWorkoutOverviewPreviewHost: View {
    @StateObject private var manager: WatchWorkoutManager

    let theme: WatchTheme
    let isVisible: Bool

    init(
        theme: WatchTheme = .ninja,
        isVisible: Bool = true,
        configure: (WatchWorkoutManager) -> Void
    ) {
        let manager = WatchWorkoutManager()
        manager.themeKey = theme.rawValue
        configure(manager)

        _manager = StateObject(wrappedValue: manager)

        self.theme = theme
        self.isVisible = isVisible
    }

    var body: some View {
        ZStack {
            WatchDashboardBackground(theme: theme)

            WatchWorkoutOverviewView(
                manager: manager,
                theme: theme,
                isVisible: isVisible
            )
        }
    }
}

#Preview("🥷 Overview — Ready") {
    WatchWorkoutOverviewPreviewHost(
        theme: .ninja
    ) { manager in
        manager.goalMiles = 5.0
        manager.miles = 0
        manager.steps = 0
        manager.hr = 0
        manager.activeCalories = 0
        manager.elapsedSeconds = 0
        manager.elapsedMilliseconds = 0
        manager.running = false
        manager.paused = false
    }
}

#Preview("🥷 Overview — Live") {
    WatchWorkoutOverviewPreviewHost(
        theme: .ninja
    ) { manager in
        manager.goalMiles = 5.0
        manager.miles = 3.14
        manager.steps = 6_240
        manager.hr = 142
        manager.activeCalories = 418
        manager.elapsedSeconds = 28 * 60 + 10
        manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
        manager.running = true
        manager.paused = false
    }
}

#Preview("🥷 Overview — Paused") {
    WatchWorkoutOverviewPreviewHost(
        theme: .ninja
    ) { manager in
        manager.goalMiles = 10.0
        manager.miles = 4.75
        manager.steps = 9_800
        manager.hr = 126
        manager.activeCalories = 640
        manager.elapsedSeconds = 62 * 60 + 18
        manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
        manager.running = true
        manager.paused = true
    }
}

#Preview("🤖 Overview — Cyborg Live") {
    WatchWorkoutOverviewPreviewHost(
        theme: .cyborg
    ) { manager in
        manager.goalMiles = 6.21
        manager.miles = 4.92
        manager.steps = 10_420
        manager.hr = 151
        manager.averageHeartRate = 143
        manager.peakHeartRate = 166
        manager.activeCalories = 701
        manager.elapsedSeconds = 54 * 60 + 42
        manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
        manager.running = true
        manager.paused = false
    }
}

#Preview("🪓 Overview — Goal Complete") {
    WatchWorkoutOverviewPreviewHost(
        theme: .viking
    ) { manager in
        manager.goalMiles = 3.11
        manager.miles = 3.35
        manager.steps = 7_240
        manager.hr = 148
        manager.activeCalories = 482
        manager.elapsedSeconds = 31 * 60 + 20
        manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
        manager.running = true
        manager.paused = false
    }
}
#endif
