//
//  TrainingHomeView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/27/26.
//

import SwiftUI
import SwiftData

private enum TrainingHomeSection {
    case server
    case goal
    case telemetry
}

struct TrainingHomeView: View {

    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var sensitiveInfoUnlockManager: SensitiveInfoUnlockManager
    @EnvironmentObject private var health: HealthStreamManager
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var web = WebServerManager()

    @State private var expandedSection: TrainingHomeSection?
    @State private var showTrainingSchedule = false
    @State private var isIPhoneStreamURLRevealed = false
    @State private var isMacRelayRevealed = false
    @State private var lastRelayFailureMessage: String?

    private var isUITesting: Bool {
#if DEBUG
        ProcessInfo.processInfo.environment["NINJAPACE_IPHONE_UI_TEST_STATE"] != nil
#else
        false
#endif
    }

#if DEBUG
    @State private var debugWarriorLevel: WarriorProgressionLevel?
#endif
    
#if DEBUG
    private let debugGoalCelebrationTrigger: (() -> Void)?
#endif
    
    @Query(sort: \WorkoutRecord.startedAt, order: .reverse)
    private var workouts: [WorkoutRecord]

    private var completedGoalCount: Int {
        workouts.filter(\.wasGoalCompleted).count
    }

    private var displayedCompletedGoalCount: Int {
#if DEBUG
        if let debugWarriorLevel {
            return debugWarriorLevel.requiredGoals
        }
#endif
        return completedGoalCount
    }

    private var displayedWarriorLevel: WarriorProgressionLevel {
        .level(for: displayedCompletedGoalCount)
    }

    private var macRelayAddress: String {
        health.pushClient.macBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var watchConnectionText: String {
        if health.watchTelemetryActive { return "Watch: Streaming" }
        if health.isWorkoutRunning { return "Watch: Waiting for telemetry" }
        if health.watchReachable { return "Watch: Ready to start workout" }
        return "Watch: App Not Opened"
    }

    private var watchConnectionColor: Color {
        if health.watchTelemetryActive { return .green }
        if health.isWorkoutRunning { return .orange }
        if health.watchReachable { return .green }
        return themeStore.theme.appSecondaryTextColor
    }
    
#if DEBUG
    init(debugGoalCelebrationTrigger: (() -> Void)? = nil) {
        self.debugGoalCelebrationTrigger = debugGoalCelebrationTrigger
    }
#endif

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                WarriorBackgroundView()

                if geometry.size.height < 600 {
                    compactTrainingLayout(availableHeight: geometry.size.height)
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        trainingTitle
                        trainingForm
                    }
                    .overlay(alignment: .bottom) {
                        if expandedSection == nil {
                            warriorProgressFooter
                                .transition(.opacity)
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showTrainingSchedule) {
            TrainingScheduleSettingsView(store: health.scheduleStore)
        }
        .toolbar {
            trainingScheduleToolbarItem
            customizationToolbarItem
            relaySettingsToolbarItem
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            if !isUITesting {
                await onTask()
            }
        }
        .onChange(of: completedGoalCount) { _, _ in
#if DEBUG
            debugWarriorLevel = nil
#endif
        }
        .onChange(of: health.goalMiles) { _, _ in
            onGoalMilesChanged()
            health.scheduleSettingsSyncToWatch()
            health.pushCurrentStateToMac()
        }
        .onAppear {
            syncTheme(themeStore.theme)
        }
        .onChange(of: themeStore.theme) { _, newTheme in
            syncTheme(newTheme)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                hideSensitiveAddresses()
            } else {
                health.requestCurrentWatchState()
            }
        }
        .onChange(of: health.pushClient.macBaseURL) { _, newAddress in
            health.startPushingToMac(macBaseURL: newAddress)
        }
        .onChange(of: health.pushClient.status) { _, status in
            guard case .failed(let message) = status else { return }
            guard lastRelayFailureMessage != message else { return }

            lastRelayFailureMessage = message
            health.userAlert = .relayConnectionFailed
        }
        .alert(item: $health.userAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var trainingTitle: some View {
        Text(themeStore.theme.launchPadTitle)
            .font(.largeTitle.bold())
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .accessibilityIdentifier("trainingHomeTitle")
    }

    private var trainingForm: some View {
        Form {
            goalSection
            telemetrySection
            serverControlsSection
        }
        .tint(themeStore.theme.appPrimaryTextColor)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 20, for: .scrollContent)
        .contentMargins(.bottom, 180, for: .scrollContent)
    }

    /// Short windows use one icon row; the warrior occupies separate scrollable space.
    private func compactTrainingLayout(availableHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            trainingTitle
            HStack(spacing: 16) {
                compactSectionButton(.goal, title: "Today's Goal", icon: "target")
                compactSectionButton(.telemetry, title: "Telemetry", icon: "waveform.path.ecg")
                compactSectionButton(.server, title: "Server Controls", icon: "dot.radiowaves.left.and.right")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)

            if let expandedSection {
                Form {
                    switch expandedSection {
                    case .goal: goalSection
                    case .telemetry: telemetrySection
                    case .server: serverControlsSection
                    }
                }
                .tint(themeStore.theme.appPrimaryTextColor)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, 8, for: .scrollContent)
            } else {
                ScrollView {
                    warriorProgressFooter
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: max(0, availableHeight - 140), alignment: .bottom)
                }
            }
        }
    }

    private func compactSectionButton(_ section: TrainingHomeSection, title: String, icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                expandedSection = expandedSection == section ? nil : section
            }
        } label: {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .frame(width: 48, height: 48)
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                .background(themeStore.theme.hudEditorRowBackground, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(themeStore.theme.appPrimaryTextColor.opacity(expandedSection == section ? 1 : 0), lineWidth: 2)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(expandedSection == section ? "Expanded" : "Collapsed")
        .accessibilityHint("Show or hide this section")
        .accessibilityIdentifier("compactSection_\(section)")
    }

    // MARK: - Sections

    private var goalSection: some View {
        Section {
            Button {
                withAnimation(.easeInOut(duration: 0.28)) {
                    expandedSection = expandedSection == .goal ? nil : .goal
                }
            } label: {
                HStack {
                    collapsibleHeader(
                        title: "Today's Goal",
                        systemImage: "target"
                    )

                    Spacer()

                    Image(
                        systemName: expandedSection == .goal
                            ? "chevron.up"
                            : "chevron.down"
                    )
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .animation(
                        .easeInOut(duration: 0.28),
                        value: expandedSection == .goal
                    )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("goalSectionButton")
            .listRowSeparator(.hidden)

            if expandedSection == .goal {
                GoalLaunchPadView(
                    goalMiles: $health.goalMiles,
                    useScheduleDefault: Binding(
                        get: { health.useScheduleDefault },
                        set: { health.setUseScheduleDefault($0) }
                    ),
                    applyScheduleDefault: {
                        health.applyScheduleDefaultForToday()
                    },
                    markManualOverride: {
                        health.userManuallySetGoalToday()
                    }
                )
                .padding(.vertical, 6)
                .transition(
                    .opacity.combined(
                        with: .move(edge: .top)
                    )
                )
            }
        }
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
    }

    private var telemetrySection: some View {
        Section {
            ThemedDisclosureGroup(
                isExpanded: expansionBinding(for: .telemetry)
            ) {
                collapsibleHeader(
                    title: "Telemetry",
                    systemImage: "waveform.path.ecg"
                )
            } content: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Live Stats from Watch")
                        .font(.footnote)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)

                    telemetryRow(
                        label: "Miles",
                        value: health.miles.formatted(
                            .number.precision(.fractionLength(2))
                        ),
                        identifier: "milesMetric"
                    )

                    telemetryRow(
                        label: "Steps",
                        value: health.steps.formatted(),
                        identifier: "stepsMetric"
                    )

                    telemetryRow(
                        label: "Heart Rate",
                        value: health.heartRateBpm > 0
                            ? "\(health.heartRateBpm) bpm"
                            : "—",
                        identifier: "heartRateMetric"
                    )

                    telemetryRow(
                        label: "Elapsed",
                        value: health.elapsedString,
                        identifier: "elapsedMetric"
                    )

                    telemetryRow(
                        label: "Progress",
                        value: "\(Int((health.progress * 100).rounded()))%",
                        identifier: "progressMetric"
                    )

                    telemetryRow(
                        label: "Goal",
                        value: "\(health.goalMiles.formatted(.number.precision(.fractionLength(2)))) mi",
                        identifier: "goalMetric"
                    )
                }
                .font(.system(.body, design: .monospaced))
                .padding(.vertical, 6)
            }
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
    }

    private var serverControlsSection: some View {
        Section {
            ThemedDisclosureGroup(
                isExpanded: expansionBinding(for: .server)
            ) {
                collapsibleHeader(
                    title: "Server Controls",
                    systemImage: "antenna.radiowaves.left.and.right"
                )
            } content: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        workoutButton
                        serverButton
                    }
                    .frame(maxWidth: .infinity)

                    if let url = web.serverURLString {
                        sensitiveAddressRow(
                            title: "iPhone Stream URL",
                            url: url,
                            isRevealed: $isIPhoneStreamURLRevealed
                        )
                    }

                    if !macRelayAddress.isEmpty {
                        sensitiveAddressRow(
                            title: "Mac Relay",
                            url: macRelayAddress,
                            isRevealed: $isMacRelayRevealed
                        )
                    }

                    Label {
                        Text(watchConnectionText)
                    } icon: {
                        Image(
                            systemName: health.watchTelemetryActive
                                ? "applewatch.radiowaves.left.and.right"
                                : "applewatch.slash"
                        )
                    }
                    .font(.footnote)
                    .foregroundStyle(watchConnectionColor)
                }
                .padding(.vertical, 6)
            }
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
        .listRowBackground(themeStore.theme.hudEditorRowBackground)
        .alert(item: $web.userAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Controls

    private var workoutButton: some View {
        let title = health.isWorkoutRunning
            ? "Stop Workout"
            : "Start Workout"

        return Button(title) {
            Task {
                if health.isWorkoutRunning {
                    await health.stopWorkout()
                } else {
                    await health.startWorkout()
                }
            }
        }
        .buttonStyle(
            TrainingControlButtonStyle(
                backgroundColor: themeStore.theme.hudEditorRowBackground,
                foregroundColor: themeStore.theme.appPrimaryTextColor
            )
        )
    }

    private var serverButton: some View {
        let title = web.isRunning
            ? "Stop Server"
            : "Start Server"

        return Button(title) {
            if web.isRunning {
                web.stop()
            } else {
                web.start(health: health)
            }
        }
        .buttonStyle(
            TrainingControlButtonStyle(
                backgroundColor: themeStore.theme.hudEditorRowBackground,
                foregroundColor: themeStore.theme.appPrimaryTextColor
            )
        )
    }

    // MARK: - Toolbar

    private var customizationToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                NavigationLink {
                    WarriorSelectionView()
                } label: {
                    Label(
                        "Change Warrior",
                        systemImage: "figure.martial.arts"
                    )
                }

                NavigationLink {
                    HUDCustomizationView(
                        configuration: $health.hudConfiguration
                    )
                } label: {
                    Label(
                        "Customize HUD",
                        systemImage: "paintpalette.fill"
                    )
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
            }
            .accessibilityLabel("Customize NinjaPace")
            .accessibilityIdentifier("customizeNinjaPaceButton")
        }
    }

    private var trainingScheduleToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showTrainingSchedule = true
            } label: {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .frame(width: 34, height: 34)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Training Schedule")
            .accessibilityIdentifier("trainingScheduleButton")
        }
    }

    private var relaySettingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                SettingsView(pushClient: health.pushClient)
            } label: {
                SettingsToolbarIconView(pushClient: health.pushClient)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Relay Settings")
            .accessibilityIdentifier("relaySettingsButton")
        }
    }

    // MARK: - Helpers

    private func collapsibleHeader(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .fontWeight(.semibold)
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
    }

    private func expansionBinding(for section: TrainingHomeSection) -> Binding<Bool> {
        Binding(
            get: {
                expandedSection == section
            },
            set: { isExpanded in
                expandedSection = isExpanded ? section : nil
            }
        )
    }

    private func telemetryRow(label: String, value: String, identifier: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                .accessibilityIdentifier(identifier)
        }
    }

    private func syncTheme(_ theme: AppTheme) {
        let key = theme.rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        web.themeKey = key
        health.themeKey = key
        health.syncCurrentSettingsToWatch()
        health.pushCurrentStateToMac()
    }

    private func hideSensitiveAddresses() {
        isIPhoneStreamURLRevealed = false
        isMacRelayRevealed = false
        sensitiveInfoUnlockManager.lock()
    }

    // MARK: - Lifecycle

    private func onTask() async {
        await health.requestAuthorization()
        web.start(health: health)
        health.bootstrapGoalForTodayIfNeeded()
        syncTheme(themeStore.theme)
        health.requestCurrentWatchState()
        health.startPushingToMac(
            macBaseURL: health.pushClient.macBaseURL
        )
    }

    private func onGoalMilesChanged() {
        if health.useScheduleDefault {
            health.userManuallySetGoalToday()
        }
    }

    // MARK: - Security

    private func sensitiveAddressRow(
        title: String,
        url: String,
        isRevealed: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(
                    systemName: isRevealed.wrappedValue
                        ? "lock.open.fill"
                        : "lock.fill"
                )
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)

                    if isRevealed.wrappedValue {
                        Text(url)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                            .privacySensitive()
                            .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    } else {
                        Text(maskedAddress(from: url))
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    }
                }

                Spacer()

                Button {
                    toggleAddressVisibility(isRevealed)
                } label: {
                    Image(
                        systemName: isRevealed.wrappedValue
                            ? "eye.slash.fill"
                            : "eye.fill"
                    )
                    .frame(width: 30, height: 30)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(
                    isRevealed.wrappedValue
                        ? "Hide \(title)"
                        : "Reveal \(title)"
                )
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }

            if let errorMessage = sensitiveInfoUnlockManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func toggleAddressVisibility(_ isRevealed: Binding<Bool>) {
        if isRevealed.wrappedValue {
            isRevealed.wrappedValue = false
            return
        }

        Task {
            let authenticated = await sensitiveInfoUnlockManager.unlock()

            if authenticated {
                isRevealed.wrappedValue = true
            }
        }
    }

    private func maskedAddress(from rawValue: String) -> String {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "Not configured" }

        let lowercased = value.lowercased()
        let normalized =
            lowercased.hasPrefix("http://") ||
            lowercased.hasPrefix("https://")
            ? value
            : "http://\(value)"

        guard let components = URLComponents(string: normalized) else {
            return "•••.•••.•••.•••:••••"
        }

        let schemePrefix: String

        if lowercased.hasPrefix("http://") {
            schemePrefix = "http://"
        } else if lowercased.hasPrefix("https://") {
            schemePrefix = "https://"
        } else {
            schemePrefix = ""
        }

        if let port = components.port {
            return "\(schemePrefix)•••.•••.•••.•••:\(port)"
        }

        return "\(schemePrefix)•••.•••.•••.•••"
    }

    // MARK: - Warrior Progression

    private var warriorProgressFooter: some View {
        WarriorProgressView(
            theme: themeStore.theme,
            completedGoals: displayedCompletedGoalCount,
            isWorkoutRunning:
                health.isWorkoutRunning &&
                !health.isWorkoutPaused
        )
        .id(displayedWarriorLevel)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityIdentifier("warriorProgressFooter")
#if DEBUG
        .contentShape(Rectangle())
        .gesture(
            ExclusiveGesture(
                TapGesture(count: 2),
                TapGesture(count: 1)
            )
            .onEnded { value in
                switch value {
                case .first(_):
                    debugGoalCelebrationTrigger?()

                case .second(_):
                    cycleDebugWarriorLevel()
                }
            }
        )
        .onLongPressGesture {
            withAnimation(.snappy) {
                debugWarriorLevel = nil
            }
        }
#endif
    }

#if DEBUG
    private func cycleDebugWarriorLevel() {
        let currentLevel =
            debugWarriorLevel ??
            WarriorProgressionLevel.level(for: completedGoalCount)

        withAnimation(.snappy) {
            debugWarriorLevel = currentLevel.nextLevel ?? .level1
        }
    }
#endif
}

#Preview("iPhone – TrainingHomeView - Dark") {
    NavigationStack {
        TrainingHomeView()
            .environmentObject(ThemeStore())
            .environmentObject(HealthStreamManager())
            .environmentObject(SensitiveInfoUnlockManager())
    }
}

#Preview("iPhone – TrainingHomeView – Light") {
    NavigationStack {
        TrainingHomeView()
            .environmentObject(ThemeStore())
            .environmentObject(HealthStreamManager())
            .environmentObject(SensitiveInfoUnlockManager())
    }
    .preferredColorScheme(.light)
}
