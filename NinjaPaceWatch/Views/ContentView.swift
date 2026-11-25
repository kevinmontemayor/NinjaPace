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
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var manager = WatchWorkoutManager()
    @State private var confirmAction: ConfirmAction?
    @State private var hasCelebratedCurrentGoal = false
    @State private var selectedPage: WatchDashboardPage = .home
    @State private var dashboardSelection: WatchDashboardPage = .home
    @State private var showsSettings = false
    @State private var idleClockDismissed = false
    @State private var idleActivityGeneration = 0
    @State private var dashboardIsInteracting = false
    @State private var settingsIsInteracting = false
    @State private var idleNavigationPageEnabled = false
    private var preferences = WatchDashboardPreferences()
    static let idleClockTimeout: TimeInterval = 60
    
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

            if let rawPage = ProcessInfo.processInfo.environment["NINJAPACE_UI_TEST_PAGE"],
               let page = WatchDashboardPage(rawValue: rawPage) {
                _selectedPage = State(initialValue: page)
                _dashboardSelection = State(initialValue: page)
            }
        }
    #endif

        _manager = StateObject(wrappedValue: instance)
    }

    var body: some View {
        ZStack {
            // The native vertical page indicator is drawn outside TabView's opacity.
            // Keep its selection in ContentView, but unmount its chrome during idle.
            if !shouldShowIdleClock {
                TabView(selection: $dashboardSelection) {
                    if canOfferIdleClock && idleNavigationPageEnabled {
                        WatchIdleWarriorClockView(
                            manager: manager,
                            theme: theme,
                            clockStyle: preferences.idleClockStyle,
                            dismiss: {},
                            isNavigationPreview: true
                        )
                        .tag(WatchDashboardPage.idleClock)
                    }
                    ForEach(preferences.visiblePages) { page in
                        dashboardPage(page)
                            .background(WatchDashboardBackground(theme: theme))
                            .onGeometryChange(for: Int.self) { proxy in
                                Int(proxy.frame(in: .global).minY.rounded())
                            } action: { _ in
                                // Crown motion can precede a selected-page change.
                                if selectedPage == page { recordDashboardActivity() }
                            }
                            // Keep the selection tag on the outermost page wrapper.
                            .tag(page)
                    }
                }
                .tabViewStyle(.verticalPage)
                .modifier(WatchIdleActivityTracking(onActivity: recordDashboardActivity,
                    onInteractionChanged: { dashboardIsInteracting = $0 }))
                .onAppear {
                    armIdleNavigationPage()
                }
            }

            if shouldShowIdleClock {
                WatchIdleWarriorClockView(manager: manager, theme: theme,
                    clockStyle: preferences.idleClockStyle,
                    dismiss: dismissIdleClock)
            }
        }
        .task(id: idleCountdownToken) {
            guard let token = idleCountdownToken else { return }
            do {
                try await Task.sleep(for: .seconds(idleClockDelay))
            } catch {
                return
            }
            guard !Task.isCancelled, idleCountdownToken == token else { return }
            idleNavigationPageEnabled = false
            showsSettings = false
            selectedPage = .home
            dashboardSelection = .home
            idleClockDismissed = false
        }
        .persistentSystemOverlays(shouldShowIdleClock ? .hidden : .automatic)
        .sheet(
            isPresented: $showsSettings,
            onDismiss: {
                recordDashboardActivity()
                if !preferences.visiblePages.contains(selectedPage) {
                    selectedPage = .home
                    dashboardSelection = .home
                }
            }
        ) {
            WatchDashboardSettingsView(manager: manager,
                onActivity: recordDashboardActivity,
                onInteractionChanged: { settingsIsInteracting = $0 })
        }
        .onChange(of: dashboardSelection) { _, page in
            recordDashboardActivity()
            if page == .idleClock {
                idleNavigationPageEnabled = false
                selectedPage = .home
                dashboardSelection = .home
                if canOfferIdleClock {
                    idleClockDismissed = false
                }
                return
            }
            selectedPage = page
        }
        .onChange(of: manager.running) { wasRunning, running in
            // Do not reinsert a previously armed preview while Stop is routing Home.
            idleNavigationPageEnabled = false
            if wasRunning && !running {
                idleClockDismissed = false
                if preferences.showCurrentTime {
                    selectedPage = .home
                    dashboardSelection = .home
                }
            }
        }
        .onChange(of: preferences.showCurrentTime) { _, enabled in
            if enabled { idleClockDismissed = false }
        }
        .onChange(of: preferences.idleClockStyle) { _, _ in
            idleClockDismissed = false
        }
        .onChange(of: preferences.visiblePages) { _, pages in
            guard !pages.contains(selectedPage) else { return }
            selectedPage = .home
            dashboardSelection = .home
        }
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

    private var shouldShowIdleClock: Bool {
        canOfferIdleClock && dashboardSelection == .home && !idleClockDismissed
    }

    private var canOfferIdleClock: Bool {
        preferences.showCurrentTime && !manager.running && !showsSettings
    }

    private var idleCountdownToken: Int? {
        preferences.showCurrentTime && !manager.running && !shouldShowIdleClock
            && scenePhase == .active && !dashboardIsInteracting && !settingsIsInteracting
            ? idleActivityGeneration : nil
    }

    private var idleClockDelay: TimeInterval {
#if DEBUG
        if isUITesting,
           let raw = ProcessInfo.processInfo.environment["NINJAPACE_UI_TEST_IDLE_TIMEOUT"],
           let seconds = Double(raw), seconds.isFinite, seconds > 0 {
            return seconds
        }
#endif
        return Self.idleClockTimeout
    }

    private func recordDashboardActivity() {
        idleActivityGeneration &+= 1
    }

    private func dismissIdleClock() {
        idleNavigationPageEnabled = false
        idleClockDismissed = true
        selectedPage = .home
        dashboardSelection = .home
        dashboardIsInteracting = false
        settingsIsInteracting = false
        recordDashboardActivity()
    }

    @ViewBuilder
    private func dashboardPage(_ page: WatchDashboardPage) -> some View {
        switch page {
        case .home:
            WatchWarriorHomeView(manager: manager, theme: theme,
                featuredMetric: preferences.featuredMetric,
                isVisible: dashboardSelection == .home && !shouldShowIdleClock && !showsSettings, primaryAction: primaryAction,
                showSettings: { showsSettings = true })
                .accessibilityAction(named: "Show warrior clock") {
                    if canOfferIdleClock { idleClockDismissed = false }
                }
        case .overview:
            WatchWorkoutOverviewView(manager: manager, theme: theme, isVisible: dashboardSelection == .overview)
        case .controls:
            WatchWorkoutControlsView(manager: manager, theme: theme, isVisible: dashboardSelection == .controls,
                primaryAction: primaryAction, stopAction: { confirmAction = .stop })
        default:
            if let metric = page.metric {
                WatchFocusMetricView(metric: metric, manager: manager, theme: theme)
            }
        }
    }

    private func primaryAction() {
        if manager.running && !manager.paused {
            confirmAction = .pause
        } else if manager.paused {
            manager.resume()
        } else {
#if DEBUG
            if isUITesting {
                // Exercise idle/workout presentation transitions without starting HealthKit.
                manager.running = true
                manager.paused = false
                return
            }
#endif
            manager.start()
        }
    }
    
    private func armIdleNavigationPage() {
        idleNavigationPageEnabled = false
        Task { @MainActor in
            await Task.yield()
            guard !shouldShowIdleClock else { return }
            idleNavigationPageEnabled = canOfferIdleClock
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

        let environment = ProcessInfo.processInfo.environment
        if environment["NINJAPACE_UI_TEST_RESET_DASHBOARD"] != "0" {
            for key in ["showCurrentTime", "idleClockStyle", "featuredMetric", "showOverview", "metrics"] {
                UserDefaults.standard.removeObject(forKey: "watchDashboard." + key)
            }
        }
        if let showTime = environment["NINJAPACE_UI_TEST_SHOW_TIME"] {
            UserDefaults.standard.set(showTime == "1", forKey: "watchDashboard.showCurrentTime")
        }
        if let style = environment["NINJAPACE_UI_TEST_CLOCK_STYLE"] {
            UserDefaults.standard.set(style, forKey: "watchDashboard.idleClockStyle")
        }
        manager.warriorLevel = Int(environment["NINJAPACE_UI_TEST_WARRIOR_LEVEL"] ?? "1")
            .flatMap(WarriorProgressionLevel.init(rawValue:))
        manager.themeKey = environment["NINJAPACE_UI_TEST_THEME"] ?? "ninja"
        manager.goalMiles = Double(environment["NINJAPACE_UI_TEST_GOAL"] ?? "5") ?? 5

        switch rawState {
        case "live":
            manager.miles = 3.14
            manager.steps = 6_240
            manager.hr = 142
            manager.activeCalories = 418
            manager.totalCalories = 510
            manager.averageHeartRate = 138
            manager.peakHeartRate = 156
            manager.elapsedSeconds = 28 * 60 + 10
            manager.elapsedMilliseconds = manager.elapsedSeconds * 1_000
            manager.running = true
            manager.paused = false

        case "paused":
            manager.miles = 3.14
            manager.steps = 6_240
            manager.hr = 142
            manager.activeCalories = 418
            manager.totalCalories = 510
            manager.averageHeartRate = 138
            manager.peakHeartRate = 156
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
