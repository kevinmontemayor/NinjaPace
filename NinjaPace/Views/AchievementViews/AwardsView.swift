//
//  AwardsView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/7/26.
//

import SwiftData
import SwiftUI

struct AwardsView: View {
    
    @AppStorage("hasEarnedAchievementMastery") private var hasEarnedAchievementMastery = false
    @AppStorage("achievementMasteryCelebratedCount") private var achievementMasteryCelebratedCount = 0
    
    @EnvironmentObject private var themeStore: ThemeStore
    @State private var showMasteryCelebration = false
    @State private var selectedAchievement: Achievement?
    @ObservedObject private var monthlyChallengeStore = MonthlyChallengeStore.shared
    #if DEBUG
    @State private var debugAllAwardsCompleted = false
    #endif
    
    @Query(sort: \WorkoutRecord.startedAt, order: .reverse)
    
    private var workouts: [WorkoutRecord]
    
    private var achievementEngine: AchievementEngine {
        AchievementEngine(workouts: workouts)
    }
    
    private var unlockedAchievementCount: Int {
        #if DEBUG
        if debugAllAwardsCompleted { return totalAchievementCount }
        #endif
        return achievementEngine.unlockedAchievementCount
    }
    
    private var totalAchievementCount: Int {
        achievementEngine.totalAchievementCount
    }
    
    private var hasCurrentMastery: Bool {
        unlockedAchievementCount == totalAchievementCount && totalAchievementCount > 0
    }

    private var showsMastery: Bool {
        hasEarnedAchievementMastery || hasCurrentMastery
    }

    private func isUnlocked(_ achievement: Achievement) -> Bool {
        #if DEBUG
        if debugAllAwardsCompleted { return true }
        #endif
        return achievementEngine.isUnlocked(achievement)
    }

    private func progress(for achievement: Achievement) -> AchievementProgress {
        let progress = achievementEngine.progress(for: achievement)
        #if DEBUG
        if debugAllAwardsCompleted {
            return AchievementProgress(current: progress.target, target: progress.target)
        }
        #endif
        return progress
    }
    
    var body: some View {
        ZStack {
            WarriorBackgroundView()
            
            VStack(alignment: .leading, spacing: 0) {
                
                awardsHeader
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        #if DEBUG
                        if ProcessInfo.processInfo.environment["NINJAPACE_SCREENSHOT_DATA"] != "1" {
                            Toggle("All Awards Completed (Debug)", isOn: $debugAllAwardsCompleted)
                                .tint(themeStore.theme.tint)
                                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                                .onChange(of: debugAllAwardsCompleted) { _, enabled in
                                    showMasteryCelebration = enabled
                                }
                        }
                        #endif

                        if showsMastery {
                            masterySection
                        }
                        streakSection
                        milestoneSection
                        monthlyChallengesSection
                        badgesSection
                    }
                    .padding()
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { evaluateAchievementMastery() }
        .onChange(of: unlockedAchievementCount) { _, _ in evaluateAchievementMastery() }
        .fullScreenCover(isPresented: $showMasteryCelebration) {
            AchievementMasteryView(
                achievementCount: totalAchievementCount,
                dismiss: { showMasteryCelebration = false }
            )
            .environmentObject(themeStore)
        }
    }

    // MARK: - Mastery

    private var awardsHeader: some View {
        HStack(spacing: 10) {
            Text("Awards")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)

            if showsMastery {
                Label("GRANDMASTER", systemImage: "crown.fill")
                    .font(.caption2.bold())
                    .tracking(0.8)
                    .foregroundStyle(hasCurrentMastery ? .yellow : themeStore.theme.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        (hasCurrentMastery ? Color.yellow : themeStore.theme.tint).opacity(0.12),
                        in: Capsule()
                    )
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var masterySection: some View {
        VStack(spacing: 16) {
            ZStack {
                if hasCurrentMastery {
                    MasteryGlowView(tint: themeStore.theme.tint)
                }

                Circle()
                    .fill(Color.yellow.opacity(hasCurrentMastery ? 0.16 : 0.08))
                    .frame(width: 112, height: 112)
                
                Circle()
                    .stroke(
                        hasCurrentMastery ? Color.yellow : themeStore.theme.tint.opacity(0.65),
                        lineWidth: hasCurrentMastery ? 3 : 2
                    )
                    .frame(width: 112, height: 112)
                
                Image("achievement_grandmaster")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .saturation(hasCurrentMastery ? 1 : 0.7)
                    .opacity(hasCurrentMastery ? 1 : 0.72)
                    .shadow(
                        color: hasCurrentMastery
                            ? themeStore.theme.tint.opacity(0.5)
                            : themeStore.theme.tint.opacity(0.18),
                        radius: hasCurrentMastery ? 12 : 5
                    )
            }

            VStack(spacing: 6) {
                Text("NINJAPACE GRANDMASTER")
                    .font(.title2.bold())
                    .tracking(1)
                    .foregroundStyle(
                        hasCurrentMastery
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [.yellow, themeStore.theme.tint, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            : AnyShapeStyle(themeStore.theme.appPrimaryTextColor)
                    )
                    .multilineTextAlignment(.center)

                Text(
                    hasCurrentMastery
                        ? "Every challenge conquered. Every milestone claimed. Well done, Warrior!"
                        : "Grandmaster earned. New challenges await."
                )
                .font(.title3)
                .bold()
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Label(
                    "\(unlockedAchievementCount) / \(totalAchievementCount) Awards",
                    systemImage: "medal.fill"
                )

                Spacer()

                Text(hasCurrentMastery ? "100% COMPLETE" : "CURRENT COLLECTION")
                    .font(.caption2.bold())
                    .tracking(0.8)
                    .foregroundStyle(hasCurrentMastery ? .green : themeStore.theme.tint)
            }
            .font(.caption.bold())
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            themeStore.theme.hudEditorRowBackground,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: hasCurrentMastery
                            ? [.yellow.opacity(0.9), themeStore.theme.tint, .yellow.opacity(0.9)]
                            : [themeStore.theme.tint.opacity(0.45), themeStore.theme.tint.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: hasCurrentMastery ? 2 : 1
                )
        }
        .shadow(
            color: hasCurrentMastery ? themeStore.theme.tint.opacity(0.28) : .clear,
            radius: 18
        )
    }

    private func evaluateAchievementMastery() {
        // Only real workout history can persist mastery or mark its celebration as seen.
        guard achievementEngine.hasUnlockedAllAchievements else { return }

        hasEarnedAchievementMastery = true

        guard achievementMasteryCelebratedCount < totalAchievementCount else { return }
        achievementMasteryCelebratedCount = totalAchievementCount
        showMasteryCelebration = true
    }
    
    // MARK: - Monthly Challenges
    
    private var monthlyChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Monthly Challenges",
                systemImage: "calendar.badge.clock"
            )
            
            NavigationLink {
                MonthlyChallengesScreen()
            } label: {
                HStack(spacing: 16) {
                    // MARK: - Current Month Badge

                    if let challenge = MonthlyChallenge.current {
                        MonthlyChallengeBadgeView(
                            challenge: challenge,
                            unlocked: monthlyChallengeStore.reward(for: .now) != nil
                        )
                        .frame(width: 86, height: 86)
                    }
                    
                    // MARK: - Challenge Information

                    VStack(alignment: .leading, spacing: 8) {
                        Text(MonthlyChallenge.current?.title ?? "Monthly Challenge")
                        .font(.headline.bold())
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                        
                        Text(MonthlyChallenge.current?.description ?? "A new challenge awaits.")
                        .font(.subheadline)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                        
                        Label("View Monthly Challenges", systemImage: "trophy.fill")
                        .font(.caption.bold())
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    }
                    
                    Spacer(minLength: 0)
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline.bold())
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    themeStore.theme.hudEditorRowBackground,
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(themeStore.theme.tint.opacity(0.3), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("monthlyChallengesNavigation")
        }
    }

    // MARK: - Streak

    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Current Streak",
                systemImage: "flame.fill"
            )
            HStack(spacing: 14) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading) {
                    Text("\(currentGoalStreak)")
                        .font(.system(size: 36, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    
                    Text("Goals Completed")
                        .font(.subheadline)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }
                
                Spacer()
                
            }
            .padding()
            .background(
                themeStore.theme.hudEditorRowBackground,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
        }
    }
    
    // MARK: - Milestones
    
    private var milestoneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Milestones",
                systemImage: "flag.checkered"
            )
            HStack(spacing: 12) {
                milestone(value: totalMiles, label: "Miles")
                milestone(value: Double(workouts.count), label: "Workouts")
                milestone(value: Double(totalGoalsCompleted), label: "Goals")
            }
        }
    }
    
    // MARK: - Badges
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Badges",
                systemImage: "medal.fill"
            )
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 14
            ) {
                ForEach(Achievement.allCases) { achievement in
                    Button {
                        selectedAchievement = achievement
                    } label: {
                        AchievementCard(
                            achievement: achievement,
                            progress: progress(for: achievement),
                            unlocked: isUnlocked(achievement)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(achievement.title)
                    .accessibilityHint("Opens achievement details")
                    .accessibilityIdentifier("achievementBadge_\(achievement.rawValue)")
                }
                .sheet(item: $selectedAchievement) { achievement in
                    let nextAchievement = achievementEngine.nextLockedAchievement(
                        after: achievement
                    )
                    
                    AchievementDetailView(
                        achievement: achievement,
                        progress: progress(for: achievement),
                        nextAchievement: nextAchievement,
                        nextProgress: nextAchievement.map {
                            achievementEngine.progress(for: $0)
                        },
                        unlocked: isUnlocked(achievement),
                        earnedDate: achievementEngine.firstEarnedDate(
                            for: achievement
                        ),
                        qualifyingCount: achievementEngine.qualifyingCount(
                            for: achievement
                        )
                    )
                    .environmentObject(themeStore)
                }
            }
        }
    }

    private struct AchievementCard: View {
        @EnvironmentObject private var themeStore: ThemeStore

        let achievement: Achievement
        let progress: AchievementProgress
        let unlocked: Bool

        var body: some View {
            VStack(spacing: 10) {
                badgeImage

                Text(achievement.title)
                    .font(.headline)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .multilineTextAlignment(.center)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                Spacer(minLength: 4)

                ProgressView(value: progress.fraction)
                    .tint(unlocked ? themeStore.theme.tint : .secondary)
                
                Text(progressText)
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                
                Label(
                    unlocked ? "Unlocked" : "In Progress",
                    systemImage: unlocked ? "checkmark.circle.fill" : "lock.fill"
                )
                .font(.caption2)
                .foregroundStyle(
                    unlocked ? .green : themeStore.theme.appSecondaryTextColor
                )
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 235)
            .background(
                themeStore.theme.hudEditorRowBackground,
                in: RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
                .stroke(
                    unlocked
                        ? themeStore.theme.tint.opacity(0.32)
                        : Color.secondary.opacity(0.10),
                    lineWidth: 1
                )
            }
        }

        private var badgeImage: some View {
            ZStack {
                Circle()
                    .fill(
                        unlocked
                            ? themeStore.theme.tint.opacity(0.14)
                            : Color.secondary.opacity(0.05)
                    )
                    .frame(width: 82, height: 82)

                Circle()
                    .stroke(
                        unlocked
                            ? themeStore.theme.tint.opacity(0.55)
                            : Color.secondary.opacity(0.15),
                        lineWidth: 1.5
                    )
                    .frame(width: 82, height: 82)

                Image(achievement.badgeAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .saturation(unlocked ? 1 : 0)
                    .opacity(unlocked ? 1 : 0.36)
                    .shadow(
                        color: unlocked
                            ? themeStore.theme.tint.opacity(0.28)
                            : .clear,
                        radius: 8
                    )
            }
            .accessibilityHidden(true)
        }

        private var progressText: String {
            let current = progress.current.formatted(
                .number.precision(.fractionLength(1))
            )

            let target = progress.target.formatted(
                .number.precision(.fractionLength(1))
            )

            return "\(current) / \(target)"
        }
    }

    // MARK: - Components

    private func sectionHeader(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.title3.bold())
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
    }
    
    private func milestone(value: Double, label: String) -> some View {
        VStack(spacing: 6) {
            Text(
                value.formatted(
                    .number.precision(
                        .fractionLength(value.rounded() == value ? 0 : 1)
                    )
                )
            )
            .font(.title2.bold())
            .monospacedDigit()
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            themeStore.theme.hudEditorRowBackground,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }

    // MARK: - Calculations

    private var totalMiles: Double {
        workouts.reduce(0) { $0 + $1.completedMiles }
    }

    private var totalGoalsCompleted: Int {
        workouts.filter(\.wasGoalCompleted).count
    }

    private var currentGoalStreak: Int {
        totalGoalsCompleted
    }
}

private struct MasteryGlowView: View {
    let tint: Color
    
    @State private var glowing = false
    
    var body: some View {
        Circle()
            .fill(tint.opacity(glowing ? 0.22 : 0.08))
            .frame(width: 126, height: 126)
            .blur(radius: glowing ? 14 : 8)
            .scaleEffect(glowing ? 1.08 : 0.92)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
            .accessibilityHidden(true)
    }
}

#if DEBUG

@MainActor
private struct AwardsPreviewHost: View {
    enum Scenario: String {
        case none
        case some
        case all

        var workouts: [WorkoutRecord] {
            let distances: [Double]
            switch self {
            case .none:
                distances = []
            case .some:
                // Five completed goals and one unfinished goal, with badges still to earn.
                distances = [3.5, 4, 5, 6.3, 7, 2]
            case .all:
                // 100 goals, over 1,000 miles, a marathon, and twice a workout goal.
                distances = [26.3] + Array(repeating: 10, count: 99)
            }

            let referenceDate = Date(timeIntervalSince1970: 1_791_806_400)
            return distances.enumerated().map { index, miles in
                let startedAt = referenceDate.addingTimeInterval(-Double(index) * 86_400)
                let duration = miles * 12 * 60
                return WorkoutRecord(
                    startedAt: startedAt,
                    endedAt: startedAt.addingTimeInterval(duration),
                    goalMiles: self == .all ? 10 : 3.11,
                    completedMiles: miles,
                    steps: Int(miles * 2_000),
                    duration: duration
                )
            }
        }
    }

    private let container: ModelContainer
    private let defaults: UserDefaults
    @StateObject private var themeStore = ThemeStore()

    init(scenario: Scenario) {
        do {
            container = try ModelContainer(
                for: WorkoutRecord.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let workouts = scenario.workouts
            for workout in workouts {
                container.mainContext.insert(workout)
            }
            try container.mainContext.save()

            let suiteName = "AwardsPreview.\(scenario.rawValue)"
            guard let previewDefaults = UserDefaults(suiteName: suiteName) else {
                fatalError("Could not create Awards preview preferences")
            }
            defaults = previewDefaults
            let engine = AchievementEngine(workouts: workouts)
            defaults.set(engine.hasUnlockedAllAchievements, forKey: "hasEarnedAchievementMastery")
            // Keep the Awards screen visible; AchievementMasteryView has its own preview.
            defaults.set(
                engine.hasUnlockedAllAchievements ? Achievement.allCases.count : 0,
                forKey: "achievementMasteryCelebratedCount"
            )
        } catch {
            fatalError("Awards preview failed: \(error)")
        }
    }

    var body: some View {
        NavigationStack {
            AwardsView()
        }
        .modelContainer(container)
        .defaultAppStorage(defaults)
        .environmentObject(themeStore)
    }
}

#Preview("No Goals Completed") {
    AwardsPreviewHost(scenario: .none)
}

#Preview("Some Goals Completed") {
    AwardsPreviewHost(scenario: .some)
}

#Preview("All Goals Completed") {
    AwardsPreviewHost(scenario: .all)
}

#endif
