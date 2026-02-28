//
//  LaunchPadView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/27/26.
//

import SwiftUI

struct LaunchPadView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    @StateObject private var web = WebServerManager()
    @StateObject private var health = HealthStreamManager()

    private var hasMacRelay: Bool {
        !health.pushClient.macBaseURL
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }
    
    private var shouldWiggleWeapon: Bool {
        health.pushClient.enabled && themeStore.theme == .viking
    }
    
    private func syncTheme(_ theme: AppTheme) {
        let key = theme.rawValue
        web.themeKey = key
        health.themeKey = key
    }
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Button(health.isWorkoutRunning ? "Stop Workout" : "Start Workout") {
                        Task {
                            if health.isWorkoutRunning { await health.stopWorkout() }
                            else { await health.startWorkout() }
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button(web.isRunning ? "Stop Server" : "Start Server") {
                        web.isRunning ? web.stop() : web.start(health: health)
                    }
                    .buttonStyle(.bordered)
                }

                if let url = web.serverURLString {
                    Text("Stream URL: \(url)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Text(health.watchReachable ? "Watch: Reachable ✅" : "Watch: Not reachable ⛔️")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Server Controls")
            }

            Section {
                GoalLaunchPad(
                    goalMiles: $health.goalMiles,
                    applyScheduleDefault: { health.applyScheduleDefaultForToday() },
                    useScheduleDefault: Binding(
                        get: { health.useScheduleDefault },
                        set: { health.setUseScheduleDefault($0) }
                    ),
                    markManualOverride: { health.userManuallySetGoalToday() }
                )
            } header: {
                Text("Goal")
            } footer: {
                Text("GoalMiles is sent with every push to Mac, so the HUD will change immediately.")
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Live Stats (from watch)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text("Miles: \(health.miles, specifier: "%.2f")   Steps: \(health.steps)   HR: \(health.heartRateBpm)")
                        .font(.system(.body, design: .monospaced))

                    Text("Progress: \(Int((health.progress * 100).rounded()))%   Goal: \(health.goalMiles, specifier: "%.2f") mi")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Telemetry")
            }
        }
        .navigationTitle(themeStore.theme.launchPadTitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    RelaySettingsView(pushClient: health.pushClient, scheduleStore: health.scheduleStore)
                } label: {
                    ZStack {
                        Circle()
                            .fill(hasMacRelay ? themeStore.theme.badgeFill : Color.clear)

                        Group {
                            if hasMacRelay {
                                ThemeIconView(icon: themeStore.theme.toolbarIcon, tint: .black, size: 16)
                            } else {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
                    .rotationEffect(.degrees(health.pushClient.enabled ? 360 : 0))
                    .animation(
                        health.pushClient.enabled
                        ? .linear(duration: 2).repeatForever(autoreverses: false)
                        : .default,
                        value: health.pushClient.enabled
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .task {
            await health.requestAuthorization()
            web.start(health: health)
            health.startPushingToMac(macBaseURL: health.pushClient.macBaseURL)
            health.bootstrapGoalForTodayIfNeeded()
            syncTheme(themeStore.theme)
        }
        .onChange(of: health.goalMiles) { _, _ in
            if health.useScheduleDefault {
                health.userManuallySetGoalToday()
            }
            health.syncToWatch(themeKey: health.themeKey, goalMiles: health.goalMiles)
        }
        .onAppear {
            syncTheme(themeStore.theme)
            health.syncToWatch(themeKey: health.themeKey, goalMiles: health.goalMiles)
        }
        .onChange(of: themeStore.theme) { _, newTheme in
            syncTheme(newTheme)
            health.syncToWatch(themeKey: health.themeKey, goalMiles: health.goalMiles)
        }
    }
}

#Preview("iPhone – LaunchPadView") {
    NavigationStack {
        LaunchPadView()
            .environmentObject(ThemeStore())
    }
}
