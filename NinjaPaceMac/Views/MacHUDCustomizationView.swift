//
//  MacHUDCustomizationView.swift
//  NinjaPaceMac
//
//  Created by Kevin Montemayor on 8/22/26.
//

import Foundation
import SwiftUI

@MainActor
struct MacHUDCustomizationView: View {

    @ObservedObject var server: MacRelayServer
    @State private var previewState: MacHUDPreviewState = .current

    private var relayTheme: MacRelayTheme {
        MacRelayTheme(themeKey: server.displayedStats.theme ?? server.lastKnownThemeKey)
    }

    private var isEditingLocally: Bool {
        server.hudConfigurationMode == .localOverride
    }

    private var isFollowingIPhone: Bool {
        server.hudConfigurationMode == .followIPhone
    }

    private var configuration: Binding<HUDConfiguration> {
        Binding(
            get: { server.effectiveHUDConfiguration },
            set: { newValue in
                guard server.hudConfigurationMode == .localOverride else { return }
                server.localHUDConfiguration = newValue
            }
        )
    }

    private var configurationMode: Binding<MacHUDConfigurationMode> {
        Binding(
            get: { server.hudConfigurationMode },
            set: { mode in
                guard mode != server.hudConfigurationMode else { return }

                Task { @MainActor in
                    await Task.yield()

                    switch mode {
                    case .followIPhone: server.followIPhoneHUDConfiguration()
                    case .localOverride: server.beginLocalHUDCustomization()
                    }
                }
            }
        )
    }

    private var subtitleBinding: Binding<String> {
        Binding(
            get: { configuration.wrappedValue.subtitle ?? "" },
            set: { newValue in
                var value = configuration.wrappedValue
                value.subtitle = newValue.isEmpty ? nil : newValue
                configuration.wrappedValue = value
            }
        )
    }

    private var textWeightBinding: Binding<Double> {
        Binding(
            get: { Double(configuration.wrappedValue.textWeight) },
            set: { newValue in
                var value = configuration.wrappedValue
                value.textWeight = Int(newValue.rounded())
                configuration.wrappedValue = value
            }
        )
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            LinearGradient(
                colors: relayTheme.backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HSplitView {
                previewPane

                inspector
                    .frame(minWidth: 340, idealWidth: 385, maxWidth: 430)
            }
        }
        .frame(minWidth: 900, minHeight: 620)
    }

    // MARK: - Preview

    private var previewPane: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("HUD Studio")
                        .font(.system(size: 26, weight: .bold, design: .rounded))

                    Text("Live streaming HUD preview")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("hudStudioWindowMarker")
                }

                Spacer()
                sourceBadge
            }

            Picker("Preview", selection: $previewState) {
                ForEach(MacHUDPreviewState.allCases) { state in
                    Text(state.displayName)
                        .tag(state)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            MacHUDPreview(
                server: server,
                configuration: server.effectiveHUDConfiguration,
                previewState: previewState
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(
                previewState == .current
                    ? "Current uses live relay telemetry when available."
                    : "Preview mode simulates this HUD state without changing your workout."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 520)
    }

    private var sourceBadge: some View {
        Text(isFollowingIPhone ? "FOLLOWING IPHONE" : "MAC OVERRIDE")
            .font(.system(.caption, design: .monospaced).weight(.bold))
            .foregroundStyle(isFollowingIPhone ? .secondary : relayTheme.primaryColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(relayTheme.primaryColor.opacity(0.12), in: Capsule())
    }

    // MARK: - Inspector

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                sourceSection
                Divider()
                identitySection
                Divider()
                colorSection
                Divider()
                appearanceSection
                Divider()
                metricsSection
                Divider()
                resetSection
            }
            .padding(20)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Source

    private var sourceSection: some View {
        inspectorSection(title: "HUD Source", systemImage: "arrow.triangle.branch") {
            Picker("Source", selection: configurationMode) {
                ForEach(MacHUDConfigurationMode.allCases) { mode in
                    Text(mode.displayName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text(
                isFollowingIPhone
                    ? "The Mac uses the HUD settings received from NinjaPace on your iPhone."
                    : "Workout telemetry still comes from the iPhone, but this Mac controls how the OBS HUD looks."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Identity

    private var identitySection: some View {
        inspectorSection(title: "Identity", systemImage: "person.text.rectangle") {
            TextField("HUD Title", text: configuration.title)
            TextField("Subtitle", text: subtitleBinding)
        }
        .disabled(!isEditingLocally)
    }

    // MARK: - Colors

    private var colorSection: some View {
        inspectorSection(title: "Colors", systemImage: "paintpalette.fill") {
            MacHUDColorRow(title: "Live", hex: configuration.liveColor)
            MacHUDColorRow(title: "Paused", hex: configuration.pausedColor)
            MacHUDColorRow(title: "Idle", hex: configuration.idleColor)
            MacHUDColorRow(title: "Goal Complete", hex: configuration.goalColor)

            Text("State Backgrounds")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            MacHUDBackgroundEditor(
                title: "Live",
                color: configuration.liveBackgroundColor,
                opacity: configuration.liveBackgroundOpacity
            )
            MacHUDBackgroundEditor(
                title: "Paused",
                color: configuration.pausedBackgroundColor,
                opacity: configuration.pausedBackgroundOpacity
            )
            MacHUDBackgroundEditor(
                title: "Idle",
                color: configuration.idleBackgroundColor,
                opacity: configuration.idleBackgroundOpacity
            )
            MacHUDBackgroundEditor(
                title: "Goal",
                color: configuration.goalBackgroundColor,
                opacity: configuration.goalBackgroundOpacity
            )
        }
        .disabled(!isEditingLocally)
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        inspectorSection(title: "Appearance", systemImage: "slider.horizontal.3") {
            MacHUDSlider(
                title: "Text Size",
                value: configuration.textScale,
                range: 0.85...1.5,
                formatted: { String(format: "%.2fx", $0) }
            )

            MacHUDSlider(
                title: "Text Weight",
                value: textWeightBinding,
                range: 600...950,
                step: 50,
                formatted: { "\(Int($0))" }
            )

            MacHUDSlider(
                title: "Text Outline",
                value: configuration.textOutline,
                range: 0...1,
                formatted: percentage
            )

            MacHUDSlider(
                title: "Glow",
                value: configuration.glowIntensity,
                range: 0...1,
                formatted: percentage
            )

            Toggle("HUD Border", isOn: configuration.borderEnabled)

            MacHUDSlider(
                title: "Border Width",
                value: configuration.borderWidth,
                range: 0.5...6,
                step: 0.25,
                formatted: { String(format: "%.2f pt", $0) }
            )
            .disabled(!configuration.wrappedValue.borderEnabled)
            .opacity(configuration.wrappedValue.borderEnabled ? 1 : 0.45)

            MacHUDSlider(
                title: "HUD Scale",
                value: configuration.scale,
                range: 0.75...1.5,
                formatted: { String(format: "%.2fx", $0) }
            )
        }
        .disabled(!isEditingLocally)
    }

    // MARK: - Metrics

    private var metricsSection: some View {
        inspectorSection(title: "Visible Metrics", systemImage: "list.bullet.rectangle") {
            Toggle("Miles", isOn: configuration.showMiles)
            Toggle("Steps", isOn: configuration.showSteps)
            Toggle("Heart Rate", isOn: configuration.showHeartRate)
            Toggle("Calories", isOn: configuration.showCalories)
            Toggle("Elapsed Time", isOn: configuration.showElapsed)
            Toggle("Pace", isOn: configuration.showPace)
            Toggle("Goal Progress", isOn: configuration.showGoal)
        }
        .disabled(!isEditingLocally)
    }

    // MARK: - Reset

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                server.resetLocalHUDToIncoming()
            } label: {
                Label("Reset Mac HUD to iPhone Configuration", systemImage: "arrow.counterclockwise")
            }
            .disabled(!isEditingLocally)

            Text("Your Mac customization is saved locally. Switching back to Follow iPhone does not delete it.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func percentage(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func inspectorSection<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(relayTheme.primaryColor)

            content()
        }
    }
}

private enum MacHUDPreviewState: String, CaseIterable, Identifiable {
    case current, live, paused, idle, goal

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

private struct MacHUDSlider: View {

    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 0.01
    let formatted: (Double) -> String

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(formatted(value))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Slider(value: $value, in: range, step: step)
        }
    }
}

private struct MacHUDColorRow: View {

    let title: String
    @Binding var hex: String

    private var colorBinding: Binding<Color> {
        Binding(
            get: { Color(hudHex: hex) },
            set: { color in
                guard let converted = color.hudHexString() else { return }
                hex = converted
            }
        )
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()

            Text(hex.uppercased())
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            ColorPicker(title, selection: colorBinding, supportsOpacity: false)
                .labelsHidden()
        }
    }
}

private struct MacHUDBackgroundEditor: View {

    let title: String
    @Binding var color: String
    @Binding var opacity: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            MacHUDColorRow(title: "\(title) Background", hex: $color)

            HStack {
                Text("\(title) Opacity")
                    .font(.caption)

                Spacer()

                Text("\(Int((opacity * 100).rounded()))%")
                    .font(.system(.caption, design: .monospaced))

                Slider(value: $opacity, in: 0...1)
                    .frame(width: 130)
            }
        }
    }
}

@MainActor
private struct MacHUDPreview: View {

    @ObservedObject var server: MacRelayServer

    let configuration: HUDConfiguration
    let previewState: MacHUDPreviewState

    private var visualState: MacHUDVisualState {
        switch previewState {
        case .current:
            if server.displayedStats.goalMiles > 0, server.displayedStats.progress >= 1 { return .goal }
            if server.displayedStats.paused { return .paused }
            if server.displayedStats.running { return .live }
            return .idle

        case .live: return .live
        case .paused: return .paused
        case .idle: return .idle
        case .goal: return .goal
        }
    }

    private var stateStyle: (foreground: String, background: String, opacity: Double) {
        switch visualState {
        case .live:
            return (
                configuration.liveColor,
                configuration.liveBackgroundColor,
                configuration.liveBackgroundOpacity
            )
        case .paused:
            return (
                configuration.pausedColor,
                configuration.pausedBackgroundColor,
                configuration.pausedBackgroundOpacity
            )
        case .idle:
            return (
                configuration.idleColor,
                configuration.idleBackgroundColor,
                configuration.idleBackgroundOpacity
            )
        case .goal:
            return (
                configuration.goalColor,
                configuration.goalBackgroundColor,
                configuration.goalBackgroundOpacity
            )
        }
    }

    private var activeColor: Color {
        Color(hudHex: stateStyle.foreground)
    }

    private var backgroundColor: Color {
        Color(hudHex: stateStyle.background)
            .opacity(min(max(stateStyle.opacity, 0), 1))
    }

    var body: some View {
        ZStack {
            MacHUDCheckerboard()

            TimelineView(
                .animation(
                    minimumInterval: 1.0 / 30.0,
                    paused: previewState != .current ||
                        !server.displayedStats.running ||
                        server.displayedStats.paused
                )
            ) { context in
                hud(at: context.date)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.10))
        }
    }

    private func hud(at date: Date) -> some View {
        VStack(spacing: 9) {
            HStack {
                VStack(alignment: .leading) {
                    Text(configuration.title.isEmpty ? "NinjaPace HUD" : configuration.title)

                    if let subtitle = configuration.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .opacity(0.72)
                    }
                }

                Spacer()
                Text(visualState.statusText)
            }
            .fontWeight(previewFontWeight)

            if configuration.showMiles {
                metric("Miles", value: displayedMiles)
            }

            if configuration.showSteps {
                metric("Steps", value: displayedSteps)
            }

            if configuration.showHeartRate {
                metric("Heart Rate", value: displayedHeartRate)
            }

            if configuration.showCalories {
                metric("Calories", value: displayedCalories)
            }

            if configuration.showElapsed {
                metric("Elapsed", value: displayedElapsed(at: date))
            }

            if configuration.showPace {
                metric("Pace", value: displayedPace)
            }

            if configuration.showGoal {
                Divider()
                    .overlay(activeColor.opacity(0.25))

                metric("Goal", value: displayedGoal)

                ProgressView(value: displayedProgress)
                    .tint(activeColor)

                Text(
                    visualState == .goal
                        ? "COMPLETED"
                        : "\(Int((displayedProgress * 100).rounded()))%"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(
            .system(
                size: 16 * configuration.textScale,
                weight: previewFontWeight,
                design: .monospaced
            )
        )
        .foregroundStyle(activeColor)
        .padding(22)
        .frame(width: 390)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            if configuration.borderEnabled {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        activeColor.opacity(0.9),
                        lineWidth: min(max(configuration.borderWidth, 0.5), 6)
                    )
            }
        }
        .shadow(
            color: activeColor.opacity(0.18 + configuration.glowIntensity * 0.55),
            radius: 8 + configuration.glowIntensity * 18
        )
        .scaleEffect(configuration.scale)
    }

    private func metric(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .opacity(0.78)
            Spacer()
            Text(value)
        }
    }

    private var usesLiveStats: Bool {
        previewState == .current
    }

    private var displayedMiles: String {
        usesLiveStats
            ? server.displayedStats.miles.formatted(.number.precision(.fractionLength(2)))
            : "3.14"
    }

    private var displayedSteps: String {
        usesLiveStats ? server.displayedStats.steps.formatted() : "6,240"
    }

    private var displayedHeartRate: String {
        guard usesLiveStats else { return "142 bpm" }
        return server.displayedStats.hr > 0 ? "\(server.displayedStats.hr) bpm" : "—"
    }

    private var displayedCalories: String {
        usesLiveStats ? "\(Int(server.displayedStats.activeCalories.rounded())) kcal" : "418 kcal"
    }

    private func displayedElapsed(at date: Date) -> String {
        usesLiveStats ? server.renderedDisplayedElapsed(at: date) : "00:28:10.42"
    }

    private var displayedPace: String {
        usesLiveStats ? server.displayedStats.pace : "8:58"
    }

    private var displayedGoal: String {
        guard usesLiveStats else {
            return visualState == .goal ? "5.00 / 5.00" : "3.14 / 5.00"
        }

        let goal = server.displayedStats.goalMiles.formatted(.number.precision(.fractionLength(2)))
        return "\(displayedMiles) / \(goal)"
    }

    private var displayedProgress: Double {
        guard usesLiveStats else { return visualState == .goal ? 1 : 0.63 }
        return min(max(server.displayedStats.progress, 0), 1)
    }

    private var previewFontWeight: Font.Weight {
        switch configuration.textWeight {
        case 900...: return .black
        case 800..<900: return .heavy
        case 700..<800: return .bold
        case 600..<700: return .semibold
        default: return .regular
        }
    }
}

private enum MacHUDVisualState {
    case live, paused, idle, goal

    var statusText: String {
        switch self {
        case .live: return "LIVE ✅"
        case .paused: return "PAUSED ⏸️"
        case .idle: return "IDLE ⏳"
        case .goal: return "GOAL 🟢"
        }
    }
}

private struct MacHUDCheckerboard: View {

    private let size: CGFloat = 18

    var body: some View {
        Canvas { context, canvasSize in
            let columns = Int(ceil(canvasSize.width / size))
            let rows = Int(ceil(canvasSize.height / size))

            for row in 0..<rows {
                for column in 0..<columns {
                    let rect = CGRect(
                        x: CGFloat(column) * size,
                        y: CGFloat(row) * size,
                        width: size,
                        height: size
                    )
                    let alternate = (row + column).isMultiple(of: 2)
                    context.fill(
                        Path(rect),
                        with: .color(alternate ? .gray.opacity(0.18) : .gray.opacity(0.07))
                    )
                }
            }
        }
    }
}

#if DEBUG

@MainActor
private struct MacHUDCustomizationPreviewHost: View {

    @StateObject private var server = MacRelayServer.preview(
        theme: "ninja",
        miles: 3.14,
        steps: 6_240,
        hr: 142,
        elapsed: "00:28:10",
        goalMiles: 5,
        progress: 0.63,
        running: true
    )

    var body: some View {
        MacHUDCustomizationView(server: server)
            .frame(width: 1_100, height: 760)
    }
}

#Preview("🥷 Ninja HUD Studio") {
    MacHUDCustomizationPreviewHost()
}

#endif
