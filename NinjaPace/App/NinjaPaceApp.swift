//
//  NinjaPaceApp.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/4/26.
//

import SwiftData
import SwiftUI
import UserNotifications

struct GoalAchievementNotification {
    let title: String
    let body: String
}

@main
@MainActor
struct NinjaPaceApp: App {
    @StateObject private var themeStore: ThemeStore
    @StateObject private var health: HealthStreamManager
    @StateObject private var sensitiveInfoUnlock: SensitiveInfoUnlockManager
    @StateObject private var achievementUnlockManager: AchievementUnlockManager
    
    private let sharedModelContainer: ModelContainer
    private let notificationDelegate = NotificationDelegate()
    
#if DEBUG
    private let uiTestState: String?
#endif

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
#if DEBUG
        let testState = ProcessInfo.processInfo.environment["NINJAPACE_IPHONE_UI_TEST_STATE"]
        let isUITesting = testState != nil
        uiTestState = testState
#else
        let isUITesting = false
#endif

        let schema = Schema([WorkoutRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let achievements = AchievementUnlockManager()
            let historyStore = WorkoutHistoryStore(
                modelContext: container.mainContext,
                achievementUnlockManager: achievements
            )

            let themeManager = ThemeStore()
            let healthManager = HealthStreamManager()
            healthManager.workoutHistoryStore = historyStore

#if DEBUG
            if let testState {
                themeManager.theme = .ninja
                healthManager.configureUITestState(testState)
                if ProcessInfo.processInfo.environment["NINJAPACE_SCREENSHOT_DATA"] == "1" {
                    if let themeName = ProcessInfo.processInfo.environment["NINJAPACE_SCREENSHOT_THEME"],
                       let captureTheme = AppTheme(rawValue: themeName) {
                        themeManager.theme = captureTheme
                        healthManager.themeKey = captureTheme.rawValue
                        healthManager.hudConfiguration = captureTheme.hudPreset
                    }
                    try Self.seedScreenshotHistory(in: container.mainContext)
                    if ProcessInfo.processInfo.environment["NINJAPACE_SCREENSHOT_SCREEN"] == "celebration" {
                        healthManager.goalMiles = 3.11
                    }
                    let isScheduleCapture = ProcessInfo.processInfo.environment["NINJAPACE_SCREENSHOT_SCREEN"] == "schedule"
                    healthManager.scheduleStore.schedule = GoalSchedule(
                        milesByWeekday: [1: 0, 2: 3.11, 3: 5, 4: 0, 5: 3.11, 6: isScheduleCapture ? 4.5 : 2, 7: 6.22],
                        useScheduleDefaults: false
                    )
                }
            }
#endif

            sharedModelContainer = container
            _themeStore = StateObject(wrappedValue: themeManager)
            _health = StateObject(wrappedValue: healthManager)
            _sensitiveInfoUnlock = StateObject(wrappedValue: SensitiveInfoUnlockManager())
            _achievementUnlockManager = StateObject(wrappedValue: achievements)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
#if DEBUG
            if let uiTestState {
                NinjaPaceUITestRoot(initialState: uiTestState)
                    .environmentObject(themeStore)
                    .environmentObject(health)
                    .environmentObject(sensitiveInfoUnlock)
                    .environmentObject(achievementUnlockManager)
                    .tint(themeStore.theme.tint)
            } else {
                WarriorView()
                    .environmentObject(themeStore)
                    .environmentObject(health)
                    .environmentObject(sensitiveInfoUnlock)
                    .environmentObject(achievementUnlockManager)
                    .tint(themeStore.theme.tint)
                    .task {
                        health.bootstrapGoalForTodayIfNeeded()
                        health.refreshGoalNudges()
                    }
            }
#else
            WarriorView()
                .environmentObject(themeStore)
                .environmentObject(health)
                .environmentObject(sensitiveInfoUnlock)
                .environmentObject(achievementUnlockManager)
                .tint(themeStore.theme.tint)
                .task {
                    health.bootstrapGoalForTodayIfNeeded()
                    health.refreshGoalNudges()
                }
#endif
        }
        .modelContainer(sharedModelContainer)
    }
}

#if DEBUG

extension NinjaPaceApp {
    /// Opt-in documentation data. Only called with the in-memory UI-test container.
    private static func seedScreenshotHistory(in context: ModelContext) throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sampleDistances: [Double] = [3.14, 5.02, 3.25, 6.22, 2.10, 3.50, 5.10, 3.14, 6.30, 3.20]
        // Fifty completed goals plus one incomplete workout, all in memory.
        let isMaxLevelCapture = ProcessInfo.processInfo.environment["NINJAPACE_SCREENSHOT_PROFILE"] == "max-level"
        let distances = isMaxLevelCapture
            ? (0..<51).map { sampleDistances[$0 % sampleDistances.count] }
            : sampleDistances
        for (index, miles) in distances.enumerated() {
            let day = calendar.date(byAdding: .day, value: -(index + 1), to: today)!
            let start = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: day)!
            let duration = index == 0 ? 1_690.0 : miles * 550
            let splits = (0..<Int(ceil(miles))).map { split in
                let distance = min(1, miles - Double(split))
                return WorkoutSplit(splitNumber: split + 1, distanceMiles: distance,
                                    duration: duration * distance / miles,
                                    averageHeartRate: 142, averageCadenceSPM: 174)
            }
            context.insert(WorkoutRecord(
                startedAt: start, endedAt: start.addingTimeInterval(duration),
                goalMiles: index == 0 ? 5 : floor(miles), completedMiles: miles,
                steps: index == 0 ? 6_240 : Int(miles * 1_987),
                averageHeartRate: 142, peakHeartRate: 162,
                activeCalories: index == 0 ? 418 : miles * 133,
                totalCalories: index == 0 ? 518 : miles * 165,
                averageCadenceSPM: 174, elevationGainFeet: 85,
                duration: duration, pausedDuration: 0,
                averagePaceSecondsPerMile: duration / miles,
                averageSpeedMPH: miles / duration * 3_600, peakSpeedMPH: 7.8,
                workoutLocationRawValue: "outdoor", source: "NinjaPace Demo",
                splits: splits,
                heartRateZones: [
                    HeartRateZoneSummary(zone: 1, minimumBPM: 90, maximumBPM: 110, duration: duration * 0.05),
                    HeartRateZoneSummary(zone: 2, minimumBPM: 110, maximumBPM: 130, duration: duration * 0.20),
                    HeartRateZoneSummary(zone: 3, minimumBPM: 130, maximumBPM: 150, duration: duration * 0.60),
                    HeartRateZoneSummary(zone: 4, minimumBPM: 150, maximumBPM: 170, duration: duration * 0.15)
                ]
            ))
        }
        try context.save()
    }
}

struct NinjaPaceUITestRoot: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var health: HealthStreamManager

    private var screenshotScreen: String? {
        guard ProcessInfo.processInfo.environment["NINJAPACE_SCREENSHOT_DATA"] == "1" else { return nil }
        return ProcessInfo.processInfo.environment["NINJAPACE_SCREENSHOT_SCREEN"]
    }
    @State private var showsWelcome: Bool

    init(initialState: String) {
        _showsWelcome = State(
            initialValue: initialState == "welcome"
        )
    }
    
    var body: some View {
        Group {
            if screenshotScreen == "warriors" {
                NavigationStack { WarriorSelectionView() }
            } else if screenshotScreen == "hud" {
                NavigationStack { HUDCustomizationView(configuration: $health.hudConfiguration) }
            } else if screenshotScreen == "mastery" {
                AchievementMasteryView(achievementCount: Achievement.allCases.count, dismiss: {})
            } else if screenshotScreen == "celebration" {
                NinjaPaceMainView()
                    .overlay { GoalCelebrationView(theme: themeStore.theme, seed: 1) }
            } else if showsWelcome {
                NavigationStack {
                    ThemeWelcomeView {
                        showsWelcome = false
                    }
                }
            } else {
                NinjaPaceMainView()
            }
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
    }
}

#endif

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              response.notification.request.content.userInfo["destination"] as? String == "monthlyChallenge" else { return }
        // Retain the destination until the main view is ready, including cold launches.
        // Old announcements deliberately open the current month's mission.
        await MainActor.run { MonthlyChallengeStore.shared.openCurrentChallenge() }
    }


    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
