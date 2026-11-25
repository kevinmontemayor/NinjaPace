//
//  WatchWorkoutControlsView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import SwiftUI

struct WatchWorkoutControlsView: View {
    @ObservedObject var manager: WatchWorkoutManager
    let theme: WatchTheme
    let isVisible: Bool
    let primaryAction: () -> Void
    let stopAction: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text("WORKOUT CONTROLS").font(.caption2.bold())
                .foregroundStyle(theme.primaryTextColor)
                .accessibilityIdentifier("controlsTitle")
            WatchWorkoutStatusView(manager: manager, theme: theme)
            Spacer(minLength: 0)
            WatchPrimaryWorkoutButton(manager: manager, theme: theme, isVisible: isVisible, action: primaryAction)
            Button(role: .destructive, action: stopAction) {
                Label("Stop", systemImage: "stop.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!manager.running)
            .accessibilityIdentifier("stopWorkoutButton")
            .accessibilityLabel("Stop")
            Spacer(minLength: 0)
            HStack {
                Text("\(manager.miles, specifier: "%.2f") MI")
                Spacer()
                Text(manager.elapsedText)
            }
            .font(.system(.caption2, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(theme.secondaryTextColor)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }.padding(12)
    }
}

struct WatchPrimaryWorkoutButton: View {
    @ObservedObject var manager: WatchWorkoutManager
    let theme: WatchTheme
    let isVisible: Bool
    var compact = false
    let action: () -> Void

    private var title: String { manager.running ? (manager.paused ? "Resume" : "Pause") : "Start" }
    private var foreground: Color {
        if manager.running && !manager.paused { return .black }
        return theme == .viking || theme == .spartan || theme == .cyborg ? .black : .white
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                WatchAnimatedThemeIconView(theme: theme, tint: foreground, size: 16,
                    isActive: isVisible && manager.running && !manager.paused)
                    .accessibilityHidden(true)
                Text(title).font(.system(size: compact ? 14 : 17, weight: .semibold))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 32 : 44)
            .foregroundStyle(foreground)
            .background((manager.running && !manager.paused ? Color.yellow : theme.tint).gradient, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("primaryWorkoutButton")
        .accessibilityLabel(title)
    }
}

#if DEBUG
@MainActor
private struct WatchWorkoutControlsPreviewHost: View {
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

            WatchWorkoutControlsView(
                manager: manager,
                theme: theme,
                isVisible: isVisible,
                primaryAction: {},
                stopAction: {}
            )
        }
    }
}

#Preview("🥷 Controls — Ready") {
    WatchWorkoutControlsPreviewHost(theme: .ninja) { manager in
        manager.goalMiles = 5.0
        manager.miles = 0
        manager.elapsedSeconds = 0
        manager.elapsedMilliseconds = 0
        manager.running = false
        manager.paused = false
    }
}

#Preview("🥷 Controls — Live") {
    WatchWorkoutControlsPreviewHost(theme: .ninja) { manager in
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

#Preview("🥷 Controls — Paused") {
    WatchWorkoutControlsPreviewHost(theme: .ninja) { manager in
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

#Preview("🤖 Controls — Cyborg Live") {
    WatchWorkoutControlsPreviewHost(theme: .cyborg) { manager in
        manager.goalMiles = 6.21
        manager.miles = 4.92
        manager.steps = 10_420
        manager.hr = 151
        manager.activeCalories = 701
        manager.elapsedSeconds = 54 * 60 + 42
        manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
        manager.running = true
        manager.paused = false
    }
}
#endif
