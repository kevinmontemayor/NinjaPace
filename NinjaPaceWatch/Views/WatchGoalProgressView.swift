//
//  WatchGoalProgressView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import SwiftUI

struct WatchGoalProgressView: View {
    @ObservedObject var manager: WatchWorkoutManager
    let theme: WatchTheme
    var compact = false

    var body: some View {
        VStack(spacing: 4) {
            if manager.goalMiles <= 0.001 {
                Text("REST DAY")
                    .font(.caption2.bold())
                    .foregroundStyle(theme.secondaryTextColor)
                    .accessibilityIdentifier("restDayLabel")
            } else {
                if !compact {
                    HStack {
                        Text(manager.progress >= 1 ? "GOAL MET" : "GOAL")
                            .foregroundStyle(manager.progress >= 1 ? .green : theme.secondaryTextColor)
                        Spacer(minLength: 2)
                        Text("\(manager.miles, specifier: "%.2f") / \(manager.goalMiles, specifier: "%.2f")")
                            .foregroundStyle(theme.primaryTextColor)
                            .monospacedDigit()
                            .accessibilityIdentifier("goalValue")
                    }
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
                ProgressView(value: manager.progress)
                    .tint(manager.progress >= 1 ? .green : theme.tint)
                    .scaleEffect(x: 1, y: compact ? 0.4 : 1)
                    .frame(height: compact ? 5 : nil)
                    .accessibilityIdentifier("goalProgress")
                    .accessibilityLabel("Goal Progress")
                    .accessibilityValue("\(Int((manager.progress * 100).rounded())) percent")
            }
        }
    }
}

#if DEBUG
@MainActor
private struct WatchGoalProgressPreviewHost: View {
    @StateObject private var manager: WatchWorkoutManager

    let theme: WatchTheme
    let compact: Bool

    init(
        theme: WatchTheme = .ninja,
        compact: Bool = false,
        configure: (WatchWorkoutManager) -> Void
    ) {
        let manager = WatchWorkoutManager()
        manager.themeKey = theme.rawValue
        configure(manager)

        _manager = StateObject(wrappedValue: manager)
        self.theme = theme
        self.compact = compact
    }

    var body: some View {
        ZStack {
            WatchDashboardBackground(theme: theme)

            WatchGoalProgressView(
                manager: manager,
                theme: theme,
                compact: compact
            )
            .padding()
        }
    }
}

#Preview("🥷 Goal — In Progress") {
    WatchGoalProgressPreviewHost(
        theme: .ninja
    ) { manager in
        manager.goalMiles = 5.0
        manager.miles = 3.14
    }
}

#Preview("🥷 Goal — Compact") {
    WatchGoalProgressPreviewHost(
        theme: .ninja,
        compact: true
    ) { manager in
        manager.goalMiles = 5.0
        manager.miles = 3.14
    }
}

#Preview("🪓 Goal — Nearly There") {
    WatchGoalProgressPreviewHost(
        theme: .viking
    ) { manager in
        manager.goalMiles = 3.11
        manager.miles = 2.95
    }
}

#Preview("🤖 Goal — Complete") {
    WatchGoalProgressPreviewHost(
        theme: .cyborg
    ) { manager in
        manager.goalMiles = 6.21
        manager.miles = 6.48
    }
}

#Preview("🏴‍☠️ Goal — Rest Day") {
    WatchGoalProgressPreviewHost(
        theme: .pirate
    ) { manager in
        manager.goalMiles = 0
        manager.miles = 0
    }
}
#endif
