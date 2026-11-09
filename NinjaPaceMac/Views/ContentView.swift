//
//  ContentView.swift
//  NinjaPaceMac
//
//  Created by Kevin Montemayor on 2/12/26.
//

import AppKit
import SwiftUI

@MainActor
struct ContentView: View {

    @ObservedObject private var server: MacRelayServer
    @Environment(\.openWindow) private var openWindow

    @State private var workoutPulse = false
    @State private var telemetryGlowPulse = false

    private let startsServerAutomatically: Bool

    private var uiTestState: String? {
#if DEBUG
        ProcessInfo.processInfo.environment["NINJAPACE_MAC_UI_TEST_STATE"]
#else
        nil
#endif
    }

    private var isUITesting: Bool { uiTestState != nil }

    private var relayTheme: MacRelayTheme {
        MacRelayTheme(themeKey: server.displayedStats.theme ?? server.lastKnownThemeKey)
    }

    private var isWorkoutActive: Bool {
        server.displayedStats.running
    }

    init(server: MacRelayServer, startsServerAutomatically: Bool = true) {
        self.server = server
        self.startsServerAutomatically = startsServerAutomatically
    }

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 22) {
                    header
                    relayStatusCard
                    telemetryCard
                    hudStudioCard
                    serverControls
                    footer
                }
                .frame(maxWidth: 760)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 720, minHeight: 650)
        .onAppear {
#if DEBUG
            if let uiTestState {
                server.configureUITestState(uiTestState)
            } else if startsServerAutomatically {
                server.start()
            }
#else
            if startsServerAutomatically { server.start() }
#endif
            updateWorkoutAnimations(isWorkoutActive)
        }
        .onChange(of: isWorkoutActive) { _, active in
            updateWorkoutAnimations(active)
        }
        .alert(item: $server.userAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            Color.black

            LinearGradient(
                colors: relayTheme.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [relayTheme.glowColor, .clear],
                center: .top,
                startRadius: 40,
                endRadius: 520
            )

            RadialGradient(
                colors: [relayTheme.secondaryColor.opacity(0.10), .clear],
                center: .bottomTrailing,
                startRadius: 80,
                endRadius: 500
            )
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.45), value: relayTheme)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(relayTheme.primaryColor.opacity(0.16))
                        .frame(width: 48, height: 48)

                    Circle()
                        .stroke(relayTheme.primaryColor.opacity(0.45), lineWidth: 1)
                        .frame(width: 48, height: 48)

                    MacAnimatedWarriorIcon(
                        theme: relayTheme,
                        isActive: isWorkoutActive
                    )
                }
                .shadow(color: relayTheme.glowColor, radius: 12)

                Text("NinjaPace")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Spacer()

                Text(relayTheme.displayName)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(relayTheme.primaryColor)
                    .accessibilityIdentifier("themeName")
                    .accessibilityLabel(Text(relayTheme.displayName))
            }

            Text("Mac Relay Command Center")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Receive live workout telemetry from NinjaPace and serve your streaming HUD.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.35), value: relayTheme)
    }

    // MARK: - Relay Status

    private var relayStatusCard: some View {
        dashboardCard {
            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Label(
                            "\(relayTheme.displayName) Relay",
                            systemImage: "antenna.radiowaves.left.and.right"
                        )
                        .font(.title3.weight(.semibold))

                        Text(server.isRunning ? "Ready for iPhone connections" : "Relay is currently offline")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                    statusBadge
                }

                Divider()

                HStack(spacing: 12) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.title2)
                        .foregroundStyle(server.isRunning ? .green : .secondary)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Bonjour Discovery")
                            .fontWeight(.semibold)

                        Text(server.isRunning ? "Advertising NinjaPace on your local network" : "Not advertising")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if let activePort = server.activePort, activePort != 8787 {
                            Label(
                                "Relay is using alternate port \(activePort)",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(.orange)

                            Text("Another instance is already using the default relay port.")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }

                    Spacer()
                }

                obsAddressRow
            }
        }
    }

    private var statusBadge: some View {
        let color: Color = server.isRunning ? .green : .secondary

        return HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)

            Text(server.isRunning ? "ONLINE" : "OFFLINE")
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .accessibilityIdentifier("relayStatus")
                .accessibilityLabel(Text(server.isRunning ? "ONLINE" : "OFFLINE"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(color.opacity(0.12), in: Capsule())
        .foregroundStyle(color)
    }

    private var obsAddressRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Streaming Browser Source", systemImage: "display")
                .fontWeight(.semibold)

            HStack {
                Text(server.baseURLString ?? "Relay not running")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(server.isRunning ? .primary : .secondary)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("obsURL")
                    .accessibilityLabel(Text(server.baseURLString ?? "Relay not running"))

                Spacer()

                if server.isRunning {
                    Button {
                        copyOBSURL()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("copyOBSURLButton")
                }
            }

            Text("Add this URL to OBS as a Browser Source on this Mac.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Live Telemetry

    private var telemetryCard: some View {
        dashboardCard(isActive: isWorkoutActive) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Label("Live Telemetry", systemImage: "waveform.path.ecg")
                        .font(.title3.weight(.semibold))

                    Spacer()

                    Text(isWorkoutActive ? "WORKOUT ACTIVE" : "WAITING")
                        .font(.system(.caption, design: .monospaced).weight(.bold))
                        .accessibilityIdentifier("workoutStatus")
                        .accessibilityLabel(Text(isWorkoutActive ? "WORKOUT ACTIVE" : "WAITING"))
                        .foregroundStyle(isWorkoutActive ? relayTheme.primaryColor : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            (isWorkoutActive ? relayTheme.primaryColor : Color.secondary).opacity(0.10),
                            in: Capsule()
                        )
                        .scaleEffect(isWorkoutActive ? (workoutPulse ? 1.06 : 0.98) : 1)
                        .opacity(isWorkoutActive ? (workoutPulse ? 1 : 0.78) : 1)
                        .shadow(
                            color: isWorkoutActive
                                ? relayTheme.primaryColor.opacity(workoutPulse ? 0.55 : 0.18)
                                : .clear,
                            radius: workoutPulse ? 10 : 3
                        )
                }
                .opacity(isWorkoutActive ? 1 : 0.45)

                Divider()

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible()), count: 3),
                    spacing: 14
                ) {
                    statTile(
                        title: "Miles",
                        value: server.displayedStats.miles.formatted(.number.precision(.fractionLength(2))),
                        icon: "figure.run",
                        identifier: "milesMetric"
                    )

                    statTile(
                        title: "Steps",
                        value: server.displayedStats.steps.formatted(),
                        icon: "shoeprints.fill",
                        identifier: "stepsMetric"
                    )

                    statTile(
                        title: "Heart Rate",
                        value: server.displayedStats.hr > 0 ? "\(server.displayedStats.hr) bpm" : "—",
                        icon: "heart.fill",
                        identifier: "heartRateMetric"
                    )

                    TimelineView(
                        .animation(
                            minimumInterval: 1.0 / 60.0,
                            paused: !server.displayedStats.running || server.displayedStats.paused
                        )
                    ) { context in
                        statTile(
                            title: "Elapsed",
                            value: server.renderedDisplayedElapsed(at: context.date),
                            icon: "timer",
                            identifier: "elapsedMetric"
                        )
                    }

                    statTile(
                        title: "Goal",
                        value: "\(server.displayedStats.goalMiles.formatted(.number.precision(.fractionLength(2)))) mi",
                        icon: "target",
                        identifier: "goalMetric"
                    )

                    statTile(
                        title: "Progress",
                        value: "\(Int((server.displayedStats.progress * 100).rounded()))%",
                        icon: "chart.bar.fill",
                        identifier: "progressMetric"
                    )
                }
            }
        }
    }

    private func statTile(title: String, value: String, icon: String, identifier: String) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(relayTheme.primaryColor)

                Text(title)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(value)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityIdentifier(identifier)
                .accessibilityLabel(Text(value))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(relayTheme.primaryColor.opacity(0.055), in: shape)
        .overlay {
            shape.stroke(relayTheme.primaryColor.opacity(0.12), lineWidth: 1)
        }
    }

    // MARK: - HUD Studio

    private var hudStudioCard: some View {
        dashboardCard {
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(relayTheme.primaryColor.opacity(0.14))
                        .frame(width: 48, height: 48)

                    Image(systemName: "paintpalette.fill")
                        .font(.title2)
                        .foregroundStyle(relayTheme.primaryColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("HUD Studio")
                        .font(.title3.weight(.semibold))

                    Text(
                        server.hudConfigurationMode == .followIPhone
                            ? "Currently following the HUD configuration from your iPhone."
                            : "This Mac is currently controlling the streaming HUD appearance."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    openWindow(id: "hud-studio")
                } label: {
                    Label("Customize HUD", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.borderedProminent)
                .tint(relayTheme.primaryColor)
                .accessibilityIdentifier("customizeHUDButton")
            }
        }
    }

    // MARK: - Server Controls

    private var serverControls: some View {
        dashboardCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Relay Controls", systemImage: "server.rack")
                    .font(.title3.weight(.semibold))

                HStack(spacing: 12) {
                    Button {
                        server.start()
                    } label: {
                        Label("Start Relay", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(relayTheme.primaryColor)
                    .disabled(server.isRunning)
                    .accessibilityIdentifier("startRelayButton")

                    Button {
                        server.stop()
                    } label: {
                        Label("Stop Relay", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!server.isRunning)
                    .accessibilityIdentifier("stopRelayButton")
                }

                Text("The relay starts automatically when NinjaPaceMac launches.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi")
            Text("Keep your Mac and iPhone on the same local network.")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.bottom, 8)
    }

    // MARK: - Card

    private func dashboardCard<Content: View>(
        isActive: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        let borderColor = isActive
            ? relayTheme.primaryColor.opacity(telemetryGlowPulse ? 0.42 : 0.20)
            : relayTheme.borderColor
        let shadowColor = isActive
            ? relayTheme.primaryColor.opacity(telemetryGlowPulse ? 0.42 : 0.18)
            : relayTheme.glowColor.opacity(0.40)
        let shadowRadius = isActive ? (telemetryGlowPulse ? 28.0 : 14.0) : 16.0

        return content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(relayTheme.cardTint)
                }
            }
            .overlay {
                shape.stroke(borderColor, lineWidth: isActive ? 1.25 : 1)
            }
            .shadow(color: shadowColor, radius: shadowRadius, y: 6)
            .animation(.easeInOut(duration: 0.35), value: relayTheme)
    }

    // MARK: - Helpers

    private func copyOBSURL() {
        guard let value = server.baseURLString else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func updateWorkoutAnimations(_ active: Bool) {
        if active {
            workoutPulse = false
            telemetryGlowPulse = false

            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                workoutPulse = true
            }

            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                telemetryGlowPulse = true
            }
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                workoutPulse = false
                telemetryGlowPulse = false
            }
        }
    }
}

// MARK: - Warrior Icon

private struct MacWarriorIcon: View {
    let theme: MacRelayTheme

    @ViewBuilder
    var body: some View {
        switch theme.icon {
        case .system(let name):
            Image(systemName: name)
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(theme.primaryColor)

        case .asset(let name):
            Image(name)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        }
    }
}

private struct MacAnimatedWarriorIcon: View {
    let theme: MacRelayTheme
    let isActive: Bool

    var body: some View {
        Group {
            if isActive {
                ActiveMacWarriorIcon(theme: theme)
            } else {
                MacWarriorIcon(theme: theme)
            }
        }
    }
}

private struct ActiveMacWarriorIcon: View {
    let theme: MacRelayTheme

    @State private var rotation: Double = 0
    @State private var isPulsing = false

    var body: some View {
        Group {
            switch theme.iconAnimation {
            case .spin:
                MacWarriorIcon(theme: theme)
                    .rotationEffect(.degrees(rotation))

            case .pulse:
                MacWarriorIcon(theme: theme)
                    .scaleEffect(isPulsing ? 1.16 : 0.94)
                    .opacity(isPulsing ? 1 : 0.72)
                    .shadow(
                        color: theme.primaryColor.opacity(isPulsing ? 0.85 : 0.20),
                        radius: isPulsing ? 7 : 2
                    )
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: theme) { _, _ in
            startAnimation()
        }
    }

    private func startAnimation() {
        rotation = 0
        isPulsing = false

        switch theme.iconAnimation {
        case .spin:
            withAnimation(
                .linear(duration: theme.iconAnimationDuration)
                    .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }

        case .pulse:
            withAnimation(
                .easeInOut(duration: theme.iconAnimationDuration)
                    .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

#if DEBUG

#Preview("🥷 Ninja") {
    ContentView(
        server: .preview(theme: "ninja", miles: 3.11, hr: 148, goalMiles: 6.21, progress: 0.50),
        startsServerAutomatically: false
    )
}

#Preview("🛡 Viking") {
    ContentView(
        server: .preview(theme: "viking", miles: 8.42, hr: 136, goalMiles: 13.11, progress: 0.64),
        startsServerAutomatically: false
    )
}

#Preview("⚔️ Knight") {
    ContentView(
        server: .preview(theme: "knight", miles: 5.74, hr: 152, goalMiles: 10, progress: 0.57),
        startsServerAutomatically: false
    )
}

#Preview("🏴‍☠️ Pirate") {
    ContentView(
        server: .preview(theme: "pirate", miles: 10.25, hr: 144, goalMiles: 13.11, progress: 0.78),
        startsServerAutomatically: false
    )
}

#Preview("🤖 Cyborg") {
    ContentView(
        server: .preview(theme: "cyborg", miles: 18.65, hr: 158, goalMiles: 26.22, progress: 0.71),
        startsServerAutomatically: false
    )
}

#Preview("🛡 Spartan") {
    ContentView(
        server: .preview(theme: "spartan", miles: 24.10, hr: 163, goalMiles: 26.22, progress: 0.92),
        startsServerAutomatically: false
    )
}

#endif
