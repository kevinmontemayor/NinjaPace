//
//  WatchDashboardSettingsView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import SwiftUI

struct WatchDashboardSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: WatchWorkoutManager
    var onActivity: () -> Void = {}
    var onInteractionChanged: (Bool) -> Void = { _ in }
    private var preferences = WatchDashboardPreferences()
    private var theme: WatchTheme { WatchTheme.from(manager.themeKey) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Warrior") {
                    NavigationLink {
                        warriorPicker
                    } label: {
                        Label {
                            Text(theme.displayName)
                        } icon: {
                            WatchAnimatedThemeIconView(
                                theme: theme,
                                tint: theme.tint,
                                size: 22,
                                isActive: true
                            )
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)
                        }
                    }
                    .modifier(WatchSettingsRowStyle(theme: theme))
                    .accessibilityIdentifier("chooseWarriorButton")
                }
                Section("Watch Home") {
                    Toggle("Show Current Time", isOn: preferences.$showCurrentTime)
                        .modifier(WatchSettingsRowStyle(theme: theme))
                        .accessibilityIdentifier("showCurrentTimeToggle")

                    if preferences.showCurrentTime {
                        NavigationLink {
                            idleClockStylePicker
                        } label: {
                            VStack(alignment: .leading) {
                                Text("Clock Style")
                                Text(preferences.idleClockStyle.title)
                                    .font(.caption2)
                                    .foregroundStyle(theme.secondaryTextColor)
                            }
                        }
                        .modifier(WatchSettingsRowStyle(theme: theme))
                        .accessibilityIdentifier("idleClockStylePicker")
                    }
                    
                    Toggle("Show Overview", isOn: preferences.$showOverview)
                        .modifier(WatchSettingsRowStyle(theme: theme))
                        .accessibilityIdentifier("showOverviewToggle")
                    
                    NavigationLink {
                        WatchFeaturedMetricPicker(theme: theme, onActivity: onActivity)
                            .modifier(activityTracking)
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Featured Metric")
                            Text(preferences.featuredMetric.title)
                                .font(.caption2)
                                .foregroundStyle(theme.secondaryTextColor)
                        }
                    }
                    .modifier(WatchSettingsRowStyle(theme: theme))
                    .accessibilityIdentifier("featuredMetricPicker")
                }
                Section("Expanded Pages") {
                    ForEach(WatchFocusMetric.allCases) { metric in
                        Toggle(metric.title, isOn: preferences.enabledBinding(for: metric))
                            .modifier(WatchSettingsRowStyle(theme: theme))
                            .accessibilityIdentifier("metricToggle." + metric.rawValue)
                    }
                }
            }
            .modifier(activityTracking)
            .onChange(of: preferences.showCurrentTime) { _, _ in onActivity() }
            .onChange(of: preferences.showOverview) { _, _ in onActivity() }
            .onChange(of: preferences.metricsRaw) { _, _ in onActivity() }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("dashboardSettingsDone")
                }
            }
        }
        .tint(theme.tint)
    }

    private var warriorPicker: some View {
        List {
            ForEach(WatchTheme.allCases, id: \.rawValue) { warrior in
                Button {
                    onActivity()
                    // Use the manager's existing persisted theme; phone synchronization stays intact.
                    manager.themeKey = warrior.rawValue
                } label: {
                    HStack {
                        Image(warrior.heroAssetName).resizable().scaledToFit().frame(width: 42, height: 48)
                            .accessibilityHidden(true)
                        Text(warrior.displayName)
                        Spacer(minLength: 0)
                        if theme == warrior {
                            Image(systemName: "checkmark").foregroundStyle(theme.tint)
                        }
                    }
                }
                .modifier(WatchSettingsRowStyle(theme: theme))
                .accessibilityIdentifier("warriorChoice." + warrior.rawValue)
                .accessibilityValue(theme == warrior ? "Selected" : "Not selected")
            }
            Text("Your iPhone can also update your warrior.")
                .font(.footnote).foregroundStyle(theme.secondaryTextColor)
                .listRowBackground(Color.clear)
        }
        .modifier(activityTracking)
        .navigationTitle("Choose Warrior")
    }

    private var idleClockStylePicker: some View {
        WatchIdleClockStylePicker(theme: theme, onActivity: onActivity)
            .modifier(activityTracking)
    }

    private var activityTracking: WatchIdleActivityTracking {
        WatchIdleActivityTracking(onActivity: onActivity,
            onInteractionChanged: onInteractionChanged, tracksTouches: false)
    }
}

private struct WatchIdleClockStylePicker: View {
    @Environment(\.dismiss) private var dismiss
    let theme: WatchTheme
    let onActivity: () -> Void
    private var preferences = WatchDashboardPreferences()

    var body: some View {
        List(WatchIdleClockStyle.allCases) { style in
            Button {
                onActivity()
                preferences.idleClockStyleRaw = style.rawValue
                dismiss()
            } label: {
                HStack {
                    Text(style.title)
                    Spacer(minLength: 0)
                    if preferences.idleClockStyle == style {
                        Image(systemName: "checkmark").foregroundStyle(theme.tint)
                    }
                }
            }
            .modifier(WatchSettingsRowStyle(theme: theme))
            .accessibilityIdentifier("idleClockStyleChoice." + style.rawValue)
            .accessibilityValue(preferences.idleClockStyle == style ? "Selected" : "Not selected")
        }
        .navigationTitle("Clock Style")
    }
}

private struct WatchFeaturedMetricPicker: View {
    @Environment(\.dismiss) private var dismiss
    let theme: WatchTheme
    let onActivity: () -> Void
    private var preferences = WatchDashboardPreferences()

    var body: some View {
        List(WatchFocusMetric.allCases) { metric in
            Button {
                onActivity()
                preferences.featuredMetricRaw = metric.rawValue
                dismiss()
            } label: {
                HStack {
                    Label(metric.title, systemImage: metric.systemImage)
                    Spacer(minLength: 0)
                    if preferences.featuredMetric == metric {
                        Image(systemName: "checkmark").foregroundStyle(theme.tint)
                    }
                }
            }
            .modifier(WatchSettingsRowStyle(theme: theme))
            .accessibilityIdentifier("featuredChoice." + metric.rawValue)
        }
        .navigationTitle("Featured Metric")
    }
}

private struct WatchSettingsRowStyle: ViewModifier {
    let theme: WatchTheme

    func body(content: Content) -> some View {
        content
            .tint(theme.tint)
            .foregroundStyle(theme.primaryTextColor)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.surfaceColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(theme.tint.opacity(0.3), lineWidth: 1)
                    }
            )
    }
}

#if DEBUG
@MainActor
private struct WatchDashboardSettingsPreviewHost: View {
    @StateObject private var manager: WatchWorkoutManager

    init(
        theme: WatchTheme = .ninja,
        configure: (WatchWorkoutManager) -> Void = { _ in }
    ) {
        let manager = WatchWorkoutManager()
        manager.themeKey = theme.rawValue
        configure(manager)

        _manager = StateObject(wrappedValue: manager)
    }

    var body: some View {
        WatchDashboardSettingsView(manager: manager)
    }
}

#Preview("🥷 Dashboard Settings — Ninja") {
    WatchDashboardSettingsPreviewHost(
        theme: .ninja
    )
}

#Preview("🪓 Dashboard Settings — Viking") {
    WatchDashboardSettingsPreviewHost(
        theme: .viking
    )
}

#Preview("🤖 Dashboard Settings — Cyborg") {
    WatchDashboardSettingsPreviewHost(
        theme: .cyborg
    )
}

#Preview("🏴‍☠️ Dashboard Settings — Pirate") {
    WatchDashboardSettingsPreviewHost(
        theme: .pirate
    )
}
#endif
