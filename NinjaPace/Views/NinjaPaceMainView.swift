//
//  NinjaPaceMainView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/7/26.
//

import SwiftUI
import SwiftData

struct NinjaPaceMainView: View {

    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var achievementUnlockManager: AchievementUnlockManager
    @EnvironmentObject private var health: HealthStreamManager
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(GoalCelebrationSettings.enabledKey)
    private var goalCelebrationsEnabled = true

    @Query private var monthlyWorkouts: [WorkoutRecord]
    @ObservedObject private var monthlyChallenges = MonthlyChallengeStore.shared

    @State private var showsGoalCelebration = false
    @State private var hasCelebratedCurrentGoal = false
    @State private var goalCelebrationSeed = 0
    @State private var celebrationDismissTask: Task<Void, Never>?
    @State private var selectedTab: NinjaPaceTab = .today

    var body: some View {
        ZStack {
            WarriorBackgroundView()

            TabView(selection: $selectedTab) {
                NavigationStack {
                #if DEBUG
                    TrainingHomeView(
                        debugGoalCelebrationTrigger: {
                            triggerDebugGoalCelebration()
                        }
                    )
                #else
                    TrainingHomeView()
                #endif
                }
                .tabItem {
                    Label("Today", systemImage: "figure.run")
                }
                .tag(NinjaPaceTab.today)

                NavigationStack {
                    WorkoutHistoryView()
                }
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(NinjaPaceTab.history)

                NavigationStack {
                    AwardsView()
                }
                .tabItem {
                    Label("Awards", systemImage: "trophy.fill")
                }
                .tag(NinjaPaceTab.awards)
            }
            if showsGoalCelebration {
                GoalCelebrationView(
                    theme: themeStore.theme,
                    seed: goalCelebrationSeed
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
        .tint(themeStore.theme.tint)
        .sheet(isPresented: achievementSheetPresented) {
            if let achievement = achievementUnlockManager.currentAchievement {
                AchievementUnlockedView(achievement: achievement) {
                    achievementUnlockManager.dismissCurrentAchievement()
                }
            } else if let date = monthlyChallenges.presentedMonth {
                MonthlyChallengeView(date: date, celebrate: monthlyChallenges.isCelebrating)
            }
        }
        .task {
            refreshMonthlyProgress()
            await monthlyChallenges.refreshNotifications()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshMonthlyProgress()
            Task { await monthlyChallenges.refreshNotifications() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            refreshMonthlyProgress()
        }
        .onChange(of: monthlyWorkouts.map { "\($0.id)|\($0.endedAt)|\($0.completedMiles)|\($0.duration)" }) { _, _ in
            refreshMonthlyProgress()
        }
        .onChange(of: health.progress) { oldProgress, newProgress in
            handleGoalProgressChange(
                from: oldProgress,
                to: newProgress
            )
        }
        .onChange(of: health.isWorkoutRunning) { _, isRunning in
            if !isRunning {
                hasCelebratedCurrentGoal = false
                dismissGoalCelebration()
            }
        }
        .onDisappear {
            celebrationDismissTask?.cancel()
        }
        .sensoryFeedback(
            .success,
            trigger: goalCelebrationSeed
        )
    }
    
    private var achievementSheetPresented: Binding<Bool> {
        Binding(
            get: {
                achievementUnlockManager.currentAchievement != nil || monthlyChallenges.presentedMonth != nil
            },
            set: { isPresented in
                if !isPresented {
                    if achievementUnlockManager.currentAchievement != nil {
                        achievementUnlockManager.dismissCurrentAchievement()
                    } else {
                        monthlyChallenges.dismissPresentation()
                    }
                }
            }
        )
    }
    
    private func refreshMonthlyProgress() {
        monthlyChallenges.evaluate(workouts: monthlyWorkouts)
    }

    private func handleGoalProgressChange(from oldProgress: Double, to newProgress: Double) {
        if newProgress < 1 {
            // This also intentionally re-arms celebrations if the user
            // raises the goal after completing an earlier target.
            hasCelebratedCurrentGoal = false
            return
        }
        
        guard oldProgress < 1, newProgress >= 1, !hasCelebratedCurrentGoal, health.goalMiles > 0.001 else { return }
        
        // Consume the transition even if animation is disabled/backgrounded,
        // so we never replay a stale celebration later.
        hasCelebratedCurrentGoal = true
        
        guard goalCelebrationsEnabled, health.isWorkoutRunning, scenePhase == .active else { return }
        
        presentGoalCelebration()
    }

    private func dismissGoalCelebration() {
        celebrationDismissTask?.cancel()
        celebrationDismissTask = nil

        withAnimation(.easeOut(duration: 0.18)) {
            showsGoalCelebration = false
        }
    }
    
    private func presentGoalCelebration() {
        celebrationDismissTask?.cancel()
        goalCelebrationSeed += 1

        GoalCelebrationSoundPlayer.shared.play(
            assetName: themeStore.theme.celebrationSoundAsset
        )

        let achievementNotification = themeStore.theme.goalAchievementNotification(
                goalMiles: health.goalMiles
            )

        Task {
            await GoalReminderManager.shared.sendGoalAchievedNotification(
                title: achievementNotification.title,
                body: achievementNotification.body
            )
        }

        withAnimation(.easeOut(duration: 0.14)) {
            showsGoalCelebration = true
        }
        
        celebrationDismissTask = Task { @MainActor in
            try? await Task.sleep(
                for: .seconds(2.15)
            )

            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.22)) {
                showsGoalCelebration = false
            }
        }
    }
    
#if DEBUG
    private func triggerDebugGoalCelebration() {
        presentGoalCelebration()
    }
#endif
}

private enum NinjaPaceTab: Hashable {
    case today
    case history
    case awards
}

#Preview {
    NinjaPaceMainView()
        .environmentObject(ThemeStore())
        .environmentObject(HealthStreamManager())
        .environmentObject(SensitiveInfoUnlockManager())
        .environmentObject(AchievementUnlockManager())
}
