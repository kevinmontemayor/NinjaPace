//
//  WatchWarriorHomeView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import SwiftUI

struct WatchWarriorHomeView: View {
    @ObservedObject var manager: WatchWorkoutManager
    let theme: WatchTheme
    let featuredMetric: WatchFocusMetric
    let isVisible: Bool
    let primaryAction: () -> Void
    let showSettings: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 2) {
                HStack {
                    Text(theme.homeTitle)
                        .font(.caption2.bold())
                        .foregroundStyle(theme.tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .accessibilityIdentifier("homeThemeTitle")
                    Spacer()
                    Button(action: showSettings) {
                        Image(systemName: "slider.horizontal.3").frame(width: 32, height: 24)
                            .foregroundStyle(theme.primaryTextColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Warrior and dashboard settings")
                    .accessibilityIdentifier("dashboardSettingsButton")
                }
                .frame(height: 24)
                WatchWarriorArtworkView(theme: theme, warriorLevel: manager.warriorLevel, running: manager.running, paused: manager.paused)
                .frame(maxWidth: .infinity)
                .frame(height: max(42, geometry.size.height * 0.32 - (manager.running && manager.goalMiles > 0.001 && manager.progress >= 1 ? 12 : 0)))
                HStack {
                    Text(warriorRankTitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(theme.primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .accessibilityIdentifier("warriorRank")

                    Spacer()

                    WatchWorkoutStatusView(
                        manager: manager,
                        theme: theme,
                        compact: true
                    )
                }
                if manager.running {
                    WatchMetricValueView(metric: manager.paused ? .elapsed : featuredMetric,
                                         manager: manager, theme: theme, size: geometry.size.height < 200 ? 22 : 30,
                                         identifier: "featuredMetric")
                        .layoutPriority(1)
                    WatchGoalProgressView(manager: manager, theme: theme, compact: true)
                    if manager.goalMiles > 0.001 && manager.progress >= 1 {
                        Text("GOAL COMPLETE").font(.system(size: 10, weight: .bold)).foregroundStyle(.green)
                    }
                } else {
                    VStack(spacing: 0) {
                        Text(manager.goalMiles <= 0.001 ? "REST DAY" : "TODAY’S GOAL")
                            .font(.system(size: 10, weight: .semibold)).foregroundStyle(theme.secondaryTextColor)
                        Text(manager.goalMiles <= 0.001 ? "Move your way" : String(format: "%.2f MI", manager.goalMiles))
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryTextColor)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .accessibilityIdentifier("homeGoal")
                    }
                }
                Spacer(minLength: 0)
                WatchPrimaryWorkoutButton(manager: manager, theme: theme, isVisible: isVisible,
                    compact: true, action: primaryAction)
            }
            .padding(.horizontal, 12)
            .padding(.top, 2)
            .padding(.bottom, 12)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    private var warriorRankTitle: String {
        guard
            let level = manager.warriorLevel,
            let title = level.title(forThemeKey: theme.rawValue)
        else {
            return theme.displayName.uppercased()
        }

        return title.uppercased()
    }
}

#if DEBUG

@MainActor
private struct WatchWarriorHomePreviewHost: View {
    @StateObject private var manager: WatchWorkoutManager

    let theme: WatchTheme
    let featuredMetric: WatchFocusMetric

    init(
        theme: WatchTheme = .ninja,
        featuredMetric: WatchFocusMetric = .distance,
        configure: (WatchWorkoutManager) -> Void
    ) {
        let manager = WatchWorkoutManager()
        manager.themeKey = theme.rawValue
        configure(manager)

        _manager = StateObject(
            wrappedValue: manager
        )

        self.theme = theme
        self.featuredMetric = featuredMetric
    }

    var body: some View {
        ZStack {
            WatchDashboardBackground(
                theme: theme
            )

            WatchWarriorHomeView(
                manager: manager,
                theme: theme,
                featuredMetric: featuredMetric,
                isVisible: true,
                primaryAction: {},
                showSettings: {}
            )
        }
    }
}

#Preview("🥷 Home — Ready") {
    WatchWarriorHomePreviewHost(
        theme: .ninja,
        featuredMetric: .distance
    ) { manager in
        manager.goalMiles = 5.0
        manager.running = false
        manager.paused = false
    }
}

#Preview("🥷 Home — Live Distance") {
    WatchWarriorHomePreviewHost(
        theme: .ninja,
        featuredMetric: .distance
    ) { manager in
        manager.goalMiles = 5.0
        manager.miles = 3.14
        manager.steps = 6_240
        manager.hr = 142
        manager.activeCalories = 418
        manager.elapsedSeconds = 28 * 60 + 10
        manager.elapsedMilliseconds =
            manager.elapsedSeconds * 1_000
        manager.running = true
        manager.paused = false
    }
}

#Preview("🥷 Home — Paused") {
    WatchWarriorHomePreviewHost(
        theme: .ninja,
        featuredMetric: .elapsed
    ) { manager in
        manager.goalMiles = 10.0
        manager.miles = 4.75
        manager.steps = 9_800
        manager.hr = 126
        manager.activeCalories = 640
        manager.elapsedSeconds =
            62 * 60 + 18
        manager.elapsedMilliseconds =
            manager.elapsedSeconds * 1_000
        manager.running = true
        manager.paused = true
    }
}

#Preview("🤖 Home — Cyborg Live HR") {
    WatchWarriorHomePreviewHost(
        theme: .cyborg,
        featuredMetric: .heartRate
    ) { manager in
        manager.goalMiles = 6.21
        manager.miles = 4.92
        manager.steps = 10_420
        manager.hr = 151
        manager.averageHeartRate = 143
        manager.peakHeartRate = 166
        manager.activeCalories = 701
        manager.elapsedSeconds =
            54 * 60 + 42
        manager.elapsedMilliseconds =
            manager.elapsedSeconds * 1_000
        manager.running = true
        manager.paused = false
    }
}

#Preview("🪓 Home — Viking Goal Complete") {
    WatchWarriorHomePreviewHost(
        theme: .viking,
        featuredMetric: .distance
    ) { manager in
        manager.goalMiles = 3.11
        manager.miles = 3.35
        manager.steps = 7_240
        manager.hr = 148
        manager.activeCalories = 482
        manager.elapsedSeconds =
            31 * 60 + 20
        manager.elapsedMilliseconds =
            manager.elapsedSeconds * 1_000
        manager.running = true
        manager.paused = false
    }
}

#Preview("🏴‍☠️ Home — Rest Day") {
    WatchWarriorHomePreviewHost(
        theme: .pirate,
        featuredMetric: .distance
    ) { manager in
        manager.goalMiles = 0
        manager.running = false
        manager.paused = false
    }
}

#endif
