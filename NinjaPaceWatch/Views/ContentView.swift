//
//  ContentView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 2/6/26.
//

import Foundation
import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var manager = WatchWorkoutManager()
    @State private var confirmAction: ConfirmAction?
    @State private var hasCelebratedCurrentGoal = false
    
    private enum ConfirmAction: Identifiable {
        case pause
        case stop

        var id: String {
            switch self {
            case .pause: return "pause"
            case .stop: return "stop"
            }
        }

        var title: String {
            switch self {
            case .pause: return "Pause workout?"
            case .stop: return "Stop workout?"
            }
        }

        var message: String {
            switch self {
            case .pause: return "Your workout will pause, and your progress will be preserved."
            case .stop: return "This will end the workout."
            }
        }
    }

    private var theme: WatchTheme { .from(manager.themeKey) }

    private var isUITesting: Bool {
#if DEBUG
        ProcessInfo.processInfo.environment["NINJAPACE_UI_TEST_STATE"] != nil
#else
        false
#endif
    }

    @MainActor
    init(manager: WatchWorkoutManager? = nil) {
        let instance = manager ?? WatchWorkoutManager()

#if DEBUG
        if manager == nil {
            Self.configureUITestStateIfNeeded(instance)
        }
#endif

        _manager = StateObject(wrappedValue: instance)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                header
                statsGrid
                progressBar
                controlsRow
                Color.clear.frame(height: 8)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            if !isUITesting {
                manager.activate()
            }
        }
        .onChange(of: manager.progress) { oldProgress, newProgress in
            handleGoalProgressChange(
                from: oldProgress,
                to: newProgress
            )
        }
        .alert(item: $confirmAction) { action in
            Alert(
                title: Text(action.title),
                message: Text(action.message),
                primaryButton: .destructive(Text(action == .stop ? "Stop" : "Pause")) {
                    switch action {
                    case .pause: manager.pause()
                    case .stop: manager.stop()
                    }
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: manager.running ? "figure.run" : "figure.walk")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(theme.emoji) \(theme.headerTitle)")
                    .font(.headline)

                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
                    .accessibilityIdentifier("workoutStatus")
                    .overlay(alignment: .trailing) {
                        if manager.running && !manager.paused {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                                .shadow(radius: 2)
                                .offset(x: 10)
                                .accessibilityHidden(true)
                        }
                    }
            }

            Spacer()

            WatchAnimatedThemeIconView(
                theme: theme,
                tint: theme.tint,
                size: 18,
                isActive: manager.running && !manager.paused
            )
            .accessibilityHidden(true)
        }
    }

    // MARK: - Stats

    private var statsGrid: some View {
        VStack(spacing: 6) {
            statRow(label: "ET.⏱️", value: manager.elapsedText, identifier: "elapsedMetric")
            statRow(label: "Pace 👟", value: manager.paceString, identifier: "paceMetric")
            statRow(
                label: "HR ❤️",
                value: manager.hr > 0 ? "\(manager.hr) bpm" : "—",
                identifier: "heartRateMetric"
            )
            statRow(
                label: "Cal.🔥",
                value: "\(Int(manager.activeCalories.rounded())) kcal",
                identifier: "caloriesMetric"
            )
            statRow(label: "Steps 👣", value: manager.steps.formatted(), identifier: "stepsMetric")
        }
        .font(.system(.footnote, design: .monospaced))
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var statusText: String {
        guard manager.running else { return "READY" }
        return manager.paused ? "PAUSED" : "LIVE"
    }

    private var statusColor: Color {
        guard manager.running else { return .secondary }
        return manager.paused ? .yellow : .green
    }

    private func statRow(label: String, value: String, identifier: String) -> some View {
        HStack {
            Text(label).opacity(0.7)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .accessibilityIdentifier(identifier)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        HStack {
            VStack(spacing: 4) {
                HStack {
                    Text("GOAL")
                        .font(.caption2)
                        .opacity(0.7)

                    Spacer()

                    Text("\(manager.miles, specifier: "%.2f") / \(manager.goalMiles, specifier: "%.2f")")
                        .font(.caption2)
                        .fontDesign(.monospaced)
                        .opacity(0.9)
                        .accessibilityIdentifier("goalValue")
                }

                ProgressView(value: manager.progress)
                    .tint(manager.goalMiles > 0 && manager.miles >= manager.goalMiles ? Color.green : theme.tint)
                    .accessibilityIdentifier("goalProgress")
                    .accessibilityLabel("Goal Progress")
                    .accessibilityValue("\(Int((manager.progress * 100).rounded())) percent")
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Controls

    private var controlsRow: some View {
        HStack(spacing: 8) {
            Button {
                if manager.running && !manager.paused {
                    confirmAction = .pause
                } else {
                    manager.toggleStartPause()
                }
            } label: {
                primaryActionLabel
            }
            .buttonStyle(.borderedProminent)
            .tint(manager.running && !manager.paused ? .yellow : theme.tint)
            .accessibilityIdentifier("primaryWorkoutButton")
            .accessibilityLabel(primaryActionTitle)

            Button(role: .destructive) {
                confirmAction = .stop
            } label: {
                Image(systemName: "stop.fill")
            }
            .buttonStyle(.bordered)
            .disabled(!manager.running)
            .accessibilityIdentifier("stopWorkoutButton")
            .accessibilityLabel("Stop")
        }
    }

    private var primaryActionLabel: some View {
        HStack(spacing: 6) {
            if !manager.paused {
                WatchAnimatedThemeIconView(
                    theme: theme,
                    tint: primaryButtonForegroundColor,
                    size: 17,
                    isActive: manager.running
                )
                .accessibilityHidden(true)
            }

            Text(primaryActionTitle)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var primaryActionTitle: String {
        if manager.paused { return "Resume" }
        return manager.running ? "Pause" : "Start"
    }

    private var primaryButtonForegroundColor: Color {
        if manager.running && !manager.paused { return .black }

        switch theme {
        case .viking, .spartan: return .black
        default: return .white
        }
    }
    
    // MARK: - Goal Completion
    
    private func handleGoalProgressChange(from oldProgress: Double, to newProgress: Double) {
        if newProgress < 1 {
            hasCelebratedCurrentGoal = false
            return
        }

        guard oldProgress < 1, newProgress >= 1, !hasCelebratedCurrentGoal, manager.goalMiles > 0.001, manager.running else { return }
        
        hasCelebratedCurrentGoal = true
        
        WKInterfaceDevice.current().play(.success)
        
        WatchGoalCelebrationSoundPlayer.shared.play(
            assetName: theme.celebrationSoundAsset
        )
    }

#if DEBUG

    @MainActor
    private static func configureUITestStateIfNeeded(_ manager: WatchWorkoutManager) {
        guard let rawState = ProcessInfo.processInfo.environment["NINJAPACE_UI_TEST_STATE"] else {
            return
        }

        manager.themeKey = "ninja"
        manager.goalMiles = 5

        switch rawState {
        case "live":
            manager.miles = 3.14
            manager.steps = 6_240
            manager.hr = 142
            manager.activeCalories = 418
            manager.elapsedSeconds = 28 * 60 + 10
            manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
            manager.running = true
            manager.paused = false

        case "paused":
            manager.miles = 3.14
            manager.steps = 6_240
            manager.hr = 142
            manager.activeCalories = 418
            manager.elapsedSeconds = 28 * 60 + 10
            manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
            manager.running = true
            manager.paused = true

        default:
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

#endif
}

#if DEBUG

@MainActor
private struct PreviewHost: View {
    @StateObject private var manager: WatchWorkoutManager

    init(configure: (WatchWorkoutManager) -> Void) {
        let manager = WatchWorkoutManager()
        configure(manager)
        _manager = StateObject(wrappedValue: manager)
    }

    var body: some View {
        ContentView(manager: manager)
    }
}

#Preview("NinjaPace — LIVE") {
    PreviewHost { manager in
        manager.miles = 3.14
        manager.steps = 6_240
        manager.hr = 142
        manager.activeCalories = 418
        manager.running = true
        manager.paused = false
        manager.elapsedSeconds = 28 * 60 + 10
    }
}

#Preview("NinjaPace — PAUSED") {
    PreviewHost { manager in
        manager.miles = 9.50
        manager.steps = 10_500
        manager.hr = 120
        manager.activeCalories = 847
        manager.running = true
        manager.paused = true
        manager.elapsedSeconds = 90 * 60 + 5
    }
}

#endif
