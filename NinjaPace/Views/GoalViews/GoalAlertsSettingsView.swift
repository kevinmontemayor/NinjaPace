//
//  GoalAlertsSettingsView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 9/19/26.
//

import SwiftUI
import UIKit
import UserNotifications

struct GoalAlertsSettingsView: View {
    @EnvironmentObject private var healthManager: HealthStreamManager
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(MonthlyChallengePreferences.enabledKey)
    private var monthlyChallengesEnabled = false
    
    @AppStorage(MonthlyChallengePreferences.reminderMinutesKey)
    private var monthlyReminderMinutes = MonthlyChallengePreferences.defaultReminderMinutes
    
    @AppStorage(GoalReminderPreferences.enabledKey)
    private var isEnabled = false

    @AppStorage(GoalReminderPreferences.reminderMinutesKey)
    private var reminderMinutes = GoalReminderPreferences.defaultReminderMinutes

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var isChangingAuthorization = false
    @State private var showsAuthorizationError = false

#if DEBUG
    @State private var testNudgeScheduled = false
#endif

    var body: some View {
        ZStack {
            WarriorBackgroundView()

            Form {
                Section {
                    Toggle("Daily Goal Reminder", isOn: enabledBinding)
                        .disabled(isChangingAuthorization)
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                        .accessibilityIdentifier("dailyGoalReminderToggle")
                    
                    DatePicker(
                        "Reminder Time",
                        selection: reminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!isEnabled)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .accessibilityIdentifier("goalReminderTimePicker")
                } header: {
                    Label("Daily Alerts", systemImage: "bell.badge.fill")
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                } footer: {
                    Text("NinjaPace schedules local reminders ahead of time. Completing your goal cancels that day's alert. Rest days are skipped.")
                        .foregroundStyle(.white)
                        .bold()
                }
                .listRowBackground(themeStore.theme.hudEditorRowBackground)

                // MARK: - Monthly Challenge Alerts

                Section {
                    Toggle("Monthly Challenge Alerts", isOn: monthlyChallengeBinding)
                    .disabled(isChangingAuthorization)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .accessibilityIdentifier("monthlyChallengeAlertsToggle")
                    .bold()
                    
                    HStack {
                        Label("Challenge Announcement", systemImage: "calendar")
                            .bold()
                        
                        Spacer()
                        
                        Text("1st of Every Month")
                            .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    }
                    .font(.subheadline)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    
                    DatePicker(
                        "Notification Time",
                        selection: monthlyReminderTimeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .disabled(!monthlyChallengesEnabled || isChangingAuthorization)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .accessibilityIdentifier("monthlyChallengeTimePicker")
                } header: {
                    Label("Monthly Alerts", systemImage: "shield.lefthalf.filled")
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                } footer: {
                    Text(
                        "Receive a new warrior challenge on the first " +
                        "day of every month at your selected time. " +
                        "Complete the challenge before the month ends " +
                        "to unlock an exclusive achievement."
                    )
                    .foregroundStyle(.white)
                    .bold()
                }
                .listRowBackground(themeStore.theme.hudEditorRowBackground)
                
                if authorizationStatus == .denied {
                    Section {
                        Button("Open iOS Notification Settings") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                                return
                            }
                            openURL(url)
                        }
                    } footer: {
                        Text("Notifications are currently disabled for NinjaPace in iOS Settings.")
                            .foregroundStyle(.white)
                            .bold()
                    }
                    .listRowBackground(themeStore.theme.hudEditorRowBackground)
                }
#if DEBUG
                Section("Testing") {
                    Button("Send Test Alert in 5 Seconds") {
                        Task {
                            testNudgeScheduled = await GoalReminderManager.shared.scheduleTestNudge(
                                goalMiles: healthManager.goalMiles
                            )
                        }
                    }
                    .disabled(!isEnabled || authorizationStatus == .denied)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    if testNudgeScheduled {
                        Text("Test scheduled. Put NinjaPace in the background to see the banner.")
                            .font(.caption)
                            .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    }
                }
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                .listRowBackground(themeStore.theme.hudEditorRowBackground)
#endif
            }
            .scrollContentBackground(.hidden)
            .tint(themeStore.theme.tint)
        }
        .navigationTitle("Goal Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigateBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .task {
            await reloadAuthorizationStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await reloadAuthorizationStatus() }
            }
        }
        .alert("Notifications Unavailable", isPresented: $showsAuthorizationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("NinjaPace couldn't enable notifications. You can check notification access in iOS Settings.")
        }
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { isEnabled },
            set: { newValue in
                Task {
                    await setGoalNudgesEnabled(newValue)
                }
            }
        )
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                let calendar = Calendar.autoupdatingCurrent
                let hour = reminderMinutes / 60
                let minute = reminderMinutes % 60

                return calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { newValue in
                let components = Calendar.autoupdatingCurrent.dateComponents(
                    [.hour, .minute],
                    from: newValue
                )

                reminderMinutes = (components.hour ?? 18) * 60 + (components.minute ?? 0)

                guard isEnabled else { return }
                healthManager.refreshGoalNudges()
            }
        )
    }
    
    // MARK: - Monthly Challenge Time Binding

    private var monthlyReminderTimeBinding: Binding<Date> {

        Binding(

            get: {

                let calendar = Calendar.autoupdatingCurrent

                let minutes = min(
                    max(monthlyReminderMinutes, 0),
                    1439
                )

                let hour = minutes / 60
                let minute = minutes % 60

                return calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: .now
                ) ?? .now
            },

            set: { newValue in
                
                let components =
                    Calendar.autoupdatingCurrent.dateComponents(
                        [.hour, .minute],
                        from: newValue
                    )
                
                let hour = components.hour ?? 9
                let minute = components.minute ?? 0

                // Persist the new time.
                monthlyReminderMinutes =
                    hour * 60 + minute

                // Don't schedule anything when disabled.
                guard monthlyChallengesEnabled else {
                    return
                }

                // Reschedule all twelve monthly notifications
                // using the newly selected time.
                Task {
                    await MonthlyChallengeStore.shared
                        .refreshNotifications()
                }
            }
        )
    }
    
    @MainActor
    private func setGoalNudgesEnabled(_ enabled: Bool) async {
        isChangingAuthorization = true
        defer { isChangingAuthorization = false }

        if !enabled {
            isEnabled = false
            await GoalReminderManager.shared.removeAllGoalNudges()
            await reloadAuthorizationStatus()
            return
        }

        let currentStatus = await GoalReminderManager.shared.authorizationStatus()
        let granted: Bool

        switch currentStatus {
        case .authorized, .provisional, .ephemeral:
            granted = true
        case .notDetermined:
            granted = await GoalReminderManager.shared.requestAuthorization()
        case .denied:
            granted = false
        @unknown default:
            granted = false
        }

        guard granted else {
            isEnabled = false
            showsAuthorizationError = true
            await reloadAuthorizationStatus()
            return
        }

        isEnabled = true
        await reloadAuthorizationStatus()
        healthManager.refreshGoalNudges()
    }

    private var monthlyChallengeBinding: Binding<Bool> {

        Binding(
            get: {
                monthlyChallengesEnabled
            },
            set: { newValue in

                Task {
                    await setMonthlyChallengesEnabled(newValue)
                }
            }
        )
    }

    @MainActor
    private func setMonthlyChallengesEnabled(_ enabled: Bool) async {
        isChangingAuthorization = true
        defer {
            isChangingAuthorization = false
        }
        
        if !enabled {
            monthlyChallengesEnabled = false
            await MonthlyChallengeManager.shared.removeNotifications()
            return
        }
        
        let status = await GoalReminderManager.shared.authorizationStatus()
        let granted: Bool
        
        switch status {
        case .authorized, .provisional, .ephemeral:
            granted = true
        case .notDetermined:
            granted = await GoalReminderManager.shared.requestAuthorization()
        case .denied:
            granted = false
        @unknown default:
            granted = false
        }
        
        guard granted else {
            monthlyChallengesEnabled = false
            showsAuthorizationError = true
            await reloadAuthorizationStatus()
            return
        }
        
        monthlyChallengesEnabled = true
        
        do {
            try await MonthlyChallengeManager.shared.scheduleNotifications()
        } catch {
            monthlyChallengesEnabled = false
            await MonthlyChallengeManager.shared.removeNotifications()
            showsAuthorizationError = true
        }
        
        await reloadAuthorizationStatus()
    }
    
    @MainActor
    private func reloadAuthorizationStatus() async {
        authorizationStatus = await GoalReminderManager.shared.authorizationStatus()
    }
    
    private func navigateBack() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            dismiss()
        }
    }
}

#if DEBUG
#Preview("Goal Nudges") {
    NavigationStack {
        GoalAlertsSettingsView()
    }
    .environmentObject(HealthStreamManager())
    .environmentObject(ThemeStore())
}
#endif
