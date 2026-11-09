//
//  HUDCustomizationView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/24/26.
//

import SwiftUI

struct HUDCustomizationView: View {

    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var health: HealthStreamManager
    @Environment(\.dismiss) private var dismiss

    @Binding var configuration: HUDConfiguration

    @State private var previewState: HUDPreviewState = .live
    @State private var expandedSection: ExpandedEditorSection?
    @State private var isPreviewCollapsed = false
    @State private var isResetConfirmationPresented = false

    var body: some View {
        ZStack {
            WarriorBackgroundView()

            VStack(spacing: 0) {
                stickyPreview

                Form {
                    identitySection
                    colorsSection
                    appearanceSection
                    metricsSection
                    resetSection
                }
                .scrollContentBackground(.hidden)
            }
        }
        .tint(themeStore.theme.tint)
        .navigationTitle("Customize HUD")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                }
            }
        }
        .onChange(of: configuration) { _, _ in
            health.saveHUDConfiguration()
        }
    }

    // MARK: - Sticky Preview

    private var stickyPreview: some View {
        VStack(spacing: 10) {
            HStack {
                Label {
                    Text("Preview")
                        .fontWeight(.semibold)
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                } icon: {
                    Text(themeStore.theme.hudEditorSectionIcon)
                }

                Spacer()

                if isPreviewCollapsed {
                    Text(previewState.statusText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(previewStateColor.opacity(0.85))
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        isPreviewCollapsed.toggle()
                    }
                } label: {
                    Image(
                        systemName: isPreviewCollapsed
                            ? "chevron.down"
                            : "chevron.up"
                    )
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isPreviewCollapsed
                        ? "Expand HUD Preview"
                        : "Collapse HUD Preview"
                )
            }

            if !isPreviewCollapsed {
                HUDLivePreview(
                    configuration: configuration,
                    state: previewState
                )
                .frame(maxWidth: .infinity)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(
                            with: .scale(scale: 0.985, anchor: .top)
                        ),
                        removal: .opacity
                    )
                )

                HStack(spacing: 0) {
                    ForEach(HUDPreviewState.allCases) { state in
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                previewState = state
                            }
                        } label: {
                            Text(state.title)
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background {
                                    if previewState == state {
                                        RoundedRectangle(
                                            cornerRadius: 8,
                                            style: .continuous
                                        )
                                        .fill(
                                            themeStore.theme == .ninja
                                                ? themeStore.theme.tint.opacity(0.2)
                                                : themeStore.theme.tint
                                        )
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(
                    themeStore.theme.hudEditorRowBackground,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, isPreviewCollapsed ? 10 : 12)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .zIndex(10)
        .animation(.easeInOut(duration: 0.22), value: isPreviewCollapsed)
    }

    // MARK: - Sections

    private var identitySection: some View {
        Section {
            ThemedDisclosureGroup(
                isExpanded: expansionBinding(for: .identity)
            ) {
                collapsibleHeader(
                    title: "Identity",
                    systemImage: "person.text.rectangle"
                )
            } content: {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("HUD Title", text: $configuration.title)

                    TextField(
                        "Subtitle",
                        text: Binding(
                            get: { configuration.subtitle ?? "" },
                            set: {
                                configuration.subtitle = $0.isEmpty ? nil : $0
                            }
                        )
                    )
                }
            }
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
    }

    private var colorsSection: some View {
        Section {
            ThemedDisclosureGroup(isExpanded: expansionBinding(for: .colors)) {
                collapsibleHeader(title: "Colors", systemImage: "paintpalette.fill")
            } content: {
                VStack(alignment: .leading, spacing: 12) {
                    HUDColorPicker(title: "Live", hex: $configuration.liveColor)
                    HUDColorPicker(title: "Paused", hex: $configuration.pausedColor)
                    HUDColorPicker(title: "Idle", hex: $configuration.idleColor)
                    HUDColorPicker(title: "Goal Complete", hex: $configuration.goalColor)
                    
                    Divider()

                    Text("State Backgrounds")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)

                    HUDColorPicker(title: "Live Background", hex: $configuration.liveBackgroundColor)
                    
                    HUDSliderRow(
                        value: $configuration.liveBackgroundOpacity,
                        title: "Live Opacity",
                        range: 0...1,
                        formattedValue: percentage
                    )
                    
                    HUDColorPicker(title: "Paused Background", hex: $configuration.pausedBackgroundColor)
                    
                    HUDSliderRow(
                        value: $configuration.pausedBackgroundOpacity,
                        title: "Paused Opacity",
                        range: 0...1,
                        formattedValue: percentage
                    )
                    
                    HUDColorPicker(title: "Idle Background", hex: $configuration.idleBackgroundColor)
                    
                    HUDSliderRow(
                        value: $configuration.idleBackgroundOpacity,
                        title: "Idle Opacity",
                        range: 0...1,
                        formattedValue: percentage
                    )
                    
                    HUDColorPicker(title: "Goal Background", hex: $configuration.goalBackgroundColor)
                    
                    HUDSliderRow(
                        value: $configuration.goalBackgroundOpacity,
                        title: "Goal Opacity",
                        range: 0...1,
                        formattedValue: percentage
                    )
                }
            }
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
    }

    private var appearanceSection: some View {
        Section {
            ThemedDisclosureGroup(isExpanded: expansionBinding(for: .appearance)) {
                collapsibleHeader(title: "Appearance", systemImage: "slider.horizontal.3")
            } content: {
                VStack(alignment: .leading, spacing: 12) {
                    HUDSliderRow(
                        value: $configuration.textScale,
                        title: "Text Size",
                        range: 0.85...1.5,
                        formattedValue: { String(format: "%.2fx", $0) }
                    )
                    
                    HUDSliderRow(
                        value: Binding(
                            get: { Double(configuration.textWeight) },
                            set: {
                                configuration.textWeight = Int($0.rounded())
                            }
                        ),
                        title: "Text Weight",
                        range: 600...950,
                        step: 50,
                        formattedValue: { "\(Int($0.rounded()))" }
                    )
                    
                    HUDSliderRow(
                        value: $configuration.textOutline,
                        title: "Text Outline",
                        range: 0...1,
                        formattedValue: percentage
                    )
                    
                    HUDSliderRow(
                        value: $configuration.glowIntensity,
                        title: "Glow Intensity",
                        range: 0...1,
                        formattedValue: percentage
                    )
                    
                    Toggle("HUD Border", isOn: $configuration.borderEnabled)
                    
                    HUDSliderRow(
                        value: $configuration.borderWidth,
                        title: "Border Width",
                        range: 0.5...6.0,
                        step: 0.25,
                        formattedValue: {
                            String(format: "%.2f pt", $0)
                        }
                    )
                    .disabled(!configuration.borderEnabled)
                    .opacity(configuration.borderEnabled ? 1 : 0.45)
                    
                    HUDSliderRow(
                        value: $configuration.scale,
                        title: "HUD Scale",
                        range: 0.75...1.5,
                        formattedValue: {
                            String(format: "%.2fx", $0)
                        }
                    )
                }
            }
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
    }

    private var metricsSection: some View {
        Section {
            ThemedDisclosureGroup(isExpanded: expansionBinding(for: .metrics)) {
                collapsibleHeader(title: "Visible Metrics", systemImage: "list.bullet.rectangle")
            } content: {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Miles", isOn: $configuration.showMiles)
                    Toggle("Steps", isOn: $configuration.showSteps)
                    Toggle("Heart Rate", isOn: $configuration.showHeartRate)
                    Toggle("Calories", isOn: $configuration.showCalories)
                    Toggle("Elapsed Time", isOn: $configuration.showElapsed)
                    Toggle("Pace", isOn: $configuration.showPace)
                    Toggle("Goal Progress", isOn: $configuration.showGoal)
                }
            }
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
    }

    private var resetSection: some View {
        Section {
            Button {
                isResetConfirmationPresented = true
            } label: {
                Label(
                    "Reset To \(themeStore.theme.displayName) Default Preset",
                    systemImage: "wand.and.stars"
                )
                .foregroundStyle(themeStore.theme == .ninja ? Color.white : Color.black)
                .fontWeight(.semibold)
            }
            .confirmationDialog(
                "Reset HUD Settings?",
                isPresented: $isResetConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button(
                    "Reset to \(themeStore.theme.displayName) Defaults",
                    role: .destructive
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        configuration = themeStore.theme.hudPreset
                        previewState = .live
                    }
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "This will replace your current HUD customization with the default \(themeStore.theme.displayName) preset."
                )
            }
        }
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
    }

    // MARK: - Helpers

    private func collapsibleHeader(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .fontWeight(.semibold)
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
    }

    private func expansionBinding(for section: ExpandedEditorSection) -> Binding<Bool> {
        Binding(
            get: {
                expandedSection == section
            },
            set: { isExpanded in
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedSection = isExpanded ? section : nil
                }
            }
        )
    }

    private func percentage(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private var previewStateColor: Color {
        switch previewState {
        case .live:
            return Color(hex: configuration.liveColor)
        case .paused:
            return Color(hex: configuration.pausedColor)
        case .idle:
            return Color(hex: configuration.idleColor)
        case .goal:
            return Color(hex: configuration.goalColor)
        }
    }
}

private struct HUDSliderRow: View {
    
    @EnvironmentObject private var themeStore: ThemeStore
    
    @Binding var value: Double
    
    let title: String
    let range: ClosedRange<Double>
    var step: Double = 0.01
    let formattedValue: (Double) -> String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                
                Spacer()
                
                Text(formattedValue(value))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }
            
            Slider(value: $value, in: range, step: step)
        }
        .padding(.vertical, 3)
    }
}

struct HUDColorPicker: View {
    
    @EnvironmentObject private var themeStore: ThemeStore
    
    let title: String
    @Binding var hex: String
    
    private var selectedColor: Color {
        Color(hex: hex)
    }
    
    private var colorBinding: Binding<Color> {
        Binding(
            get: {
                selectedColor
            },
            set: { newColor in
                if let newHex = newColor.hexString() {
                    hex = newHex
                }
            }
        )
    }
    
    var body: some View {
        ColorPicker(selection: colorBinding, supportsOpacity: false) {
            HStack(spacing: 8) {
                Circle()
                    .fill(selectedColor)
                    .frame(width: 10, height: 10)
                    .overlay {
                        Circle()
                            .stroke(
                                themeStore.theme.appPrimaryTextColor.opacity(0.35),
                                lineWidth: 1
                            )
                    }
                
                Text(title)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(hex.uppercased())
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }
        }
    }
}

private enum HUDPreviewState: String, CaseIterable, Identifiable {
    case live
    case paused
    case idle
    case goal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: return "Live"
        case .paused: return "Paused"
        case .idle: return "Idle"
        case .goal: return "Goal"
        }
    }

    var statusText: String {
        switch self {
        case .live: return "LIVE ✅"
        case .paused: return "PAUSED ⏸️"
        case .idle: return "IDLE ⏳"
        case .goal: return "GOAL 🟢"
        }
    }
}

private struct HUDLivePreview: View {

    let configuration: HUDConfiguration
    let state: HUDPreviewState

    private var activeColor: Color {
        switch state {
        case .live:
            return Color(hex: configuration.liveColor)
        case .paused:
            return Color(hex: configuration.pausedColor)
        case .idle:
            return Color(hex: configuration.idleColor)
        case .goal:
            return Color(hex: configuration.goalColor)
        }
    }

    private var progress: Double {
        state == .goal ? 1 : 0.63
    }

    private var previewScale: CGFloat {
        let normalizedScale = min(
            max(configuration.scale, 0.75),
            1.5
        )

        /*
         Keep the editor preview compact while still reflecting
         the user's scale selection.
         */
        return CGFloat(normalizedScale * 0.78)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 5) {
                titleRow

                if configuration.showMiles {
                    metricRow(label: "Miles", value: "3.14")
                }

                if configuration.showSteps {
                    metricRow(label: "Steps", value: "6,240")
                }

                if configuration.showHeartRate {
                    metricRow(label: "Heart Rate", value: "142 bpm")
                }

                if configuration.showCalories {
                    metricRow(label: "Calories", value: "418 kcal")
                }

                if configuration.showElapsed {
                    metricRow(label: "Elapsed", value: "00:28:10")
                }

                if configuration.showPace {
                    metricRow(label: "Pace", value: "8:58")
                }

                if configuration.showGoal {
                    goalSection
                }
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 11)
            .background(backgroundColor)
            .clipShape(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay {
                if configuration.borderEnabled {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            activeColor.opacity(0.9),
                            lineWidth: configuration.borderWidth
                        )
                }
            }
            .shadow(
                color: activeColor.opacity(
                    0.18 + configuration.glowIntensity * 0.55
                ),
                radius: 6 + configuration.glowIntensity * 14
            )
            .foregroundStyle(activeColor)
            .scaleEffect(previewScale)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: previewHeight
        )
        .background {
            HUDTransparencyPreviewBackground()
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .animation(.easeInOut(duration: 0.2), value: configuration)
        .animation(.easeInOut(duration: 0.2), value: state)
    }

    private var previewHeight: CGFloat {
        var visibleRows = 0

        if configuration.showMiles { visibleRows += 1 }
        if configuration.showSteps { visibleRows += 1 }
        if configuration.showHeartRate { visibleRows += 1 }
        if configuration.showCalories { visibleRows += 1 }
        if configuration.showElapsed { visibleRows += 1 }
        if configuration.showPace { visibleRows += 1 }
        if configuration.showGoal { visibleRows += 2 }

        let height = 85 + CGFloat(visibleRows * 26)
        return min(max(height * previewScale, 135), 225)
    }

    private var titleRow: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(configuration.title.isEmpty ? "NinjaPace HUD" : configuration.title)
                .font(
                    .system(
                        size: 12 * previewTextScale,
                        weight: previewFontWeight,
                        design: .monospaced
                    )
                )
                .lineLimit(1)
                .minimumScaleFactor(0.65)

                if let subtitle = configuration.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(
                            .system(
                                size: 10 * previewTextScale,
                                weight: previewFontWeight,
                                design: .monospaced
                            )
                        )
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 5)

            Text(state.statusText)
                .font(
                    .system(
                        size: 12 * previewTextScale,
                        weight: previewFontWeight,
                        design: .monospaced
                    )
                )
                .shadow(
                    color: .black.opacity(
                        configuration.textOutline > 0 ? 0.95 : 0
                    ),
                    radius: configuration.textOutline * 1.5
                )
                .lineLimit(1)
        }
    }

    private func metricRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(
                    .system(
                        size: 12 * previewTextScale,
                        weight: previewFontWeight,
                        design: .monospaced
                    )
                )
            
            Spacer()

            Text(value)
                .font(
                    .system(
                        size: 15 * previewTextScale,
                        weight: previewFontWeight,
                        design: .monospaced
                    )
                )
        }
    }

    private var goalSection: some View {
        VStack(spacing: 5) {
            goalMetricRow

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(activeColor.opacity(0.18))

                    Capsule()
                        .fill(activeColor)
                        .frame(
                            width: geometry.size.width * progress
                        )
                }
            }
            .frame(height: 7 * previewTextScale)

            Text(state == .goal ? "COMPLETED" : "\(Int(progress * 100))%")
            .font(
                .system(
                    size: 17 * previewTextScale,
                    weight: previewFontWeight,
                    design: .monospaced
                )
            )
            .foregroundStyle(activeColor)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var goalMetricRow: some View {
        HStack {
            Text("Goal")
                .font(
                    .system(
                        size: 14 * previewTextScale,
                        weight: previewFontWeight,
                        design: .monospaced
                    )
                )
            
            Spacer()

            Text(state == .goal ? "5.00 / 5.00" : "3.14 / 5.00")
            .font(
                .system(
                    size: 18 * previewTextScale,
                    weight: previewFontWeight,
                    design: .monospaced
                )
            )
        }
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

    private var previewTextScale: CGFloat {
        CGFloat(
            min(
                max(configuration.textScale, 0.85),
                1.5
            )
        )
    }

    private var stateBackgroundHex: String {
        switch state {
        case .live: return configuration.liveBackgroundColor
        case .paused: return configuration.pausedBackgroundColor
        case .idle: return configuration.idleBackgroundColor
        case .goal: return configuration.goalBackgroundColor
        }
    }

    private var stateBackgroundOpacity: Double {
        switch state {
        case .live: return configuration.liveBackgroundOpacity
        case .paused: return configuration.pausedBackgroundOpacity
        case .idle: return configuration.idleBackgroundOpacity
        case .goal: return configuration.goalBackgroundOpacity
        }
    }

    private var backgroundColor: Color {
        Color(hex: stateBackgroundHex)
            .opacity(min(max(stateBackgroundOpacity, 0), 1))
    }
}

private struct HUDTransparencyPreviewBackground: View {

    private let size: CGFloat = 14

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

                    let isAlternate = (row + column).isMultiple(of: 2)

                    context.fill(
                        Path(rect),
                        with: .color(isAlternate ? Color.gray.opacity(0.22) : Color.gray.opacity(0.08))
                    )
                }
            }
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }
}

@MainActor
private struct HUDCustomizationPreviewHost: View {

    @StateObject private var themeStore = ThemeStore()
    @StateObject private var health = HealthStreamManager()
    @State private var configuration: HUDConfiguration

    private let theme: AppTheme

    init(theme: AppTheme = .ninja) {
        self.theme = theme
        _configuration = State(initialValue: theme.hudPreset)
    }

    var body: some View {
        NavigationStack {
            HUDCustomizationView(
                configuration: $configuration
            )
        }
        .environmentObject(themeStore)
        .environmentObject(health)
        .tint(theme.tint)
        .onAppear {
            themeStore.theme = theme
        }
    }
}

#Preview("Ninja HUD Editor") {
    HUDCustomizationPreviewHost(theme: .ninja)
}

#Preview("Viking HUD Editor") {
    HUDCustomizationPreviewHost(theme: .viking)
}

#Preview("Knight HUD Editor") {
    HUDCustomizationPreviewHost(theme: .knight)
}

#Preview("Pirate HUD Editor") {
    HUDCustomizationPreviewHost(theme: .pirate)
}

#Preview("Cyborg HUD Editor") {
    HUDCustomizationPreviewHost(theme: .cyborg)
}

#Preview("Spartan HUD Editor") {
    HUDCustomizationPreviewHost(theme: .spartan)
}
