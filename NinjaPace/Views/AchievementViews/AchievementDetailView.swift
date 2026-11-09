//
//  AchievementDetailView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 9/29/26.
//

import SwiftUI

struct AchievementDetailView: View {

    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss

    let achievement: Achievement
    let progress: AchievementProgress
    let nextAchievement: Achievement?
    let nextProgress: AchievementProgress?
    let unlocked: Bool
    let earnedDate: Date?
    let qualifyingCount: Int?
    
    var body: some View {
        ZStack {
            WarriorBackgroundView()

            ScrollView {
                VStack(spacing: 22) {
                    
                    header
                    badge
                    titleSection
                    
                    if unlocked {
                        unlockedStats
                    } else {
                        lockedProgress
                    }
                    
                    nextTargetCard
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Return to Awards")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(
                        themeStore.theme.tint,
                        in: RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                    )
                    .accessibilityIdentifier("achievementDetailReturn")
                }
                .padding(24)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            Text(unlocked ? "ACHIEVEMENT UNLOCKED" : "ACHIEVEMENT LOCKED")
            .font(.caption.bold())
            .tracking(1.5)
            .foregroundStyle(unlocked ? themeStore.theme.tint : themeStore.theme.appSecondaryTextColor)
            .accessibilityIdentifier("achievementDetailStatus")
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }
            .buttonStyle(.plain)
        }
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(unlocked ? themeStore.theme.tint.opacity(0.14) : Color.secondary.opacity(0.06))
                .frame(width: 310, height: 310)
            
            Circle()
                .stroke(unlocked ? themeStore.theme.tint.opacity(0.75) : Color.secondary.opacity(0.18), lineWidth: 2.5)
                .frame(width: 280, height: 280)

            if unlocked {
                Circle()
                    .fill(themeStore.theme.tint.opacity(0.20))
                    .frame(width: 220, height: 220)
                    .blur(radius: 28)
            }

            Image(achievement.badgeAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 275, height: 275)
                .saturation(unlocked ? 1 : 0)
                .opacity(unlocked ? 1 : 0.35)
                .shadow(color: unlocked ? themeStore.theme.tint.opacity(0.50) : .clear, radius: 20)
                .accessibilityIdentifier("achievementDetailBadge")
        }
        .padding(.vertical, 8)
    }

    private var titleSection: some View {
        VStack(spacing: 7) {
            Text(achievement.title)
                .font(.largeTitle.bold())
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("achievementDetailTitle")
            
            Text(achievement.description)
                .font(.body)
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                .multilineTextAlignment(.center)
            
            Label(
                unlocked ? "Unlocked" : "In Progress",
                systemImage: unlocked ? "checkmark.seal.fill" : "lock.fill"
            )
            .font(.subheadline.bold())
            .foregroundStyle(unlocked ? .green : themeStore.theme.appSecondaryTextColor)
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var unlockedStats: some View {
        HStack(spacing: 12) {
            statCard(title: "FIRST EARNED", value: earnedDateText, systemImage: "calendar")
            
            if let qualifyingCount {
                statCard(title: occurrenceTitle, value: qualifyingCount.formatted(), systemImage: "repeat")
            } else {
                statCard(title: "CURRENT", value: currentProgressText, systemImage: "chart.bar.fill")
            }
        }
    }

    private var lockedProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("PROGRESS", systemImage: "scope")
                .font(.caption.bold())
                .tracking(0.8)
                .foregroundStyle(themeStore.theme.tint)
                
                Spacer()
                
                Text(progressPercentage)
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
            }
            
            ProgressView(value: progress.fraction)
                .tint(themeStore.theme.tint)
            
            Text(currentProgressText)
                .font(.headline.monospacedDigit())
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
        .padding(16)
        .background(
            themeStore.theme.hudEditorRowBackground,
            in: RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }

    @ViewBuilder
    private var nextTargetCard: some View {
        if let nextAchievement,
           let nextProgress {

            HStack(spacing: 14) {
                Image(nextAchievement.badgeAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 62, height: 62)
                    .saturation(0.35)
                    .opacity(0.72)

                VStack(alignment: .leading, spacing: 5) {
                    Label("NEXT TARGET", systemImage: "scope")
                    .font(.caption.bold())
                    .tracking(0.8)
                    .foregroundStyle(themeStore.theme.tint)
                    .accessibilityIdentifier("achievementDetailNextTarget")
                    
                    Text(nextAchievement.title)
                        .font(.headline.bold())
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    
                    Text(remainingText(for: nextAchievement, progress: nextProgress))
                    .font(.subheadline)
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                themeStore.theme.hudEditorRowBackground,
                in: RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
        } else {
            masteryCard
        }
    }
    
    private func statCard(title: String, value: String, systemImage: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(themeStore.theme.tint)
            
            Text(value)
                .font(.headline.bold())
                .monospacedDigit()
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
            
            Text(title)
                .font(.caption2.bold())
                .tracking(0.5)
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 105)
        .padding(12)
        .background(themeStore.theme.hudEditorRowBackground,
                    in: RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
        )
    }
    
    private var earnedDateText: String {
        guard let earnedDate else {
            return "Earned"
        }
        
        return earnedDate.formatted(.dateTime.month(.abbreviated).day().year())
    }
    
    private var occurrenceTitle: String {
        switch achievement {
        case .marathon:
            return "MARATHONS"
            
        case .halfMarathon:
            return "HALF MARATHONS"
            
        case .fiveK:
            return "5K+ RUNS"
            
        case .tenK:
            return "10K+ RUNS"
            
        case .overAchiever:
            return "OVERACHIEVERS"
            
        case .doubleGoal:
            return "DOUBLE GOALS"
            
        default:
            return "TIMES EARNED"
        }
    }
    
    private var currentProgressText: String {
        let current = progress.current.formatted(.number.precision(.fractionLength(0...2)))
        let target = progress.target.formatted(.number.precision(.fractionLength(0...2)))
        
        return "\(current) / \(target)"
    }

    private var progressPercentage: String {
        "\(Int((progress.fraction * 100).rounded()))%"
    }
    
    private var masteryCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.title2.bold())
                .foregroundStyle(themeStore.theme.tint)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("LEGEND STATUS")
                    .font(.caption.bold())
                    .tracking(0.8)
                    .foregroundStyle(themeStore.theme.tint)
                    .accessibilityIdentifier("achievementDetailLegendStatus")
                
                Text(legendMessage)
                    .font(.headline)
                    .foregroundStyle(
                        themeStore.theme.appPrimaryTextColor
                    )
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            themeStore.theme.hudEditorRowBackground,
            in: RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }
    
    // MARK: - Helpers
    
    private func remainingText(for achievement: Achievement, progress: AchievementProgress) -> String {
        let remaining = max(0, progress.target - progress.current)
        
        switch achievement {
        case .fiveK,
             .tenK,
             .halfMarathon,
             .marathon,
             .twentyFiveMiles,
             .fiftyMiles,
             .hundredMiles,
             .twoHundredFiftyMiles,
             .fiveHundredMiles,
             .thousandMiles:
            
            let miles = remaining.formatted(.number.precision(.fractionLength(0...2)))
            
            return "\(miles) miles remaining"
        case .fiveWorkouts,
             .tenWorkouts,
             .twentyFiveWorkouts,
             .fiftyWorkouts,
             .hundredWorkouts:

            return "\(Int(remaining.rounded(.up))) workouts remaining"
        case .firstGoal,
             .fiveGoals,
             .tenGoals,
             .twentyFiveGoals,
             .fiftyGoals,
             .hundredGoals:

            return "\(Int(remaining.rounded(.up))) goals remaining"
        default:
            return "Keep pushing."
        }
    }
    
    private var legendMessage: String {
        if let qualifyingCount {
            switch achievement {
            case .marathon:
                return "\(qualifyingCount) marathons completed. Keep stacking them."

            case .halfMarathon:
                return "\(qualifyingCount) half marathons completed. Keep going."

            case .tenK:
                return "\(qualifyingCount) 10K+ runs completed."

            case .fiveK:
                return "\(qualifyingCount) 5K+ runs completed."

            case .overAchiever:
                return "\(qualifyingCount) goals beaten by at least 25%."

            case .doubleGoal:
                return "\(qualifyingCount) double-goal performances completed."

            default:
                break
            }
        }

        return "This progression is mastered. Keep building the legend."
    }
}

#if DEBUG

@MainActor
private struct AchievementDetailPreviewHost: View {
    
    enum Scenario: String, CaseIterable, Identifiable {
        case marathonUnlocked
        case marathonLocked
        case fiftyMilesUnlocked
        case thousandMilesUnlocked
        case doubleGoalUnlocked
        case goalMasterLocked
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .marathonUnlocked:
                return "Marathon — Unlocked"
                
            case .marathonLocked:
                return "Marathon — Locked"
                
            case .fiftyMilesUnlocked:
                return "50 Miles — Next Target"
                
            case .thousandMilesUnlocked:
                return "1,000 Miles — Unlocked"
                
            case .doubleGoalUnlocked:
                return "Double Goal — Unlocked"
                
            case .goalMasterLocked:
                return "Goal Master — Locked"
            }
        }
        
        var achievement: Achievement {
            switch self {
            case .marathonUnlocked,
                    .marathonLocked:
                return .marathon
                
            case .fiftyMilesUnlocked:
                return .fiftyMiles
                
            case .thousandMilesUnlocked:
                return .thousandMiles
                
            case .doubleGoalUnlocked:
                return .doubleGoal
                
            case .goalMasterLocked:
                return .hundredGoals
            }
        }
        
        var progress: AchievementProgress {
            switch self {
            case .marathonUnlocked:
                return AchievementProgress(
                    current: 31.4,
                    target: 26.2188
                )
                
            case .marathonLocked:
                return AchievementProgress(
                    current: 21.0,
                    target: 26.2188
                )
                
            case .fiftyMilesUnlocked:
                return AchievementProgress(
                    current: 87.4,
                    target: 50
                )
                
            case .thousandMilesUnlocked:
                return AchievementProgress(
                    current: 1_284.7,
                    target: 1_000
                )
                
            case .doubleGoalUnlocked:
                return AchievementProgress(
                    current: 2.18,
                    target: 2
                )
                
            case .goalMasterLocked:
                return AchievementProgress(
                    current: 64,
                    target: 100
                )
            }
        }
        
        var unlocked: Bool {
            switch self {
            case .marathonUnlocked,
                    .thousandMilesUnlocked,
                    .doubleGoalUnlocked:
                return true
                
            case .fiftyMilesUnlocked:
                return true
                
            case .marathonLocked,
                    .goalMasterLocked:
                return false
            }
        }
        
        var earnedDate: Date? {
            switch self {
            case .marathonUnlocked:
                return Calendar.current.date(
                    from: DateComponents(
                        year: 2026,
                        month: 8,
                        day: 16,
                        hour: 10,
                        minute: 42
                    )
                )
                
            case .fiftyMilesUnlocked:
                return Calendar.current.date(
                    from: DateComponents(
                        year: 2026,
                        month: 5,
                        day: 14,
                        hour: 7,
                        minute: 20
                    )
                )
                
            case .thousandMilesUnlocked:
                return Calendar.current.date(
                    from: DateComponents(
                        year: 2026,
                        month: 10,
                        day: 12,
                        hour: 7,
                        minute: 18
                    )
                )
                
            case .doubleGoalUnlocked:
                return Calendar.current.date(
                    from: DateComponents(
                        year: 2026,
                        month: 9,
                        day: 28,
                        hour: 18,
                        minute: 5
                    )
                )
                
            case .marathonLocked,
                    .goalMasterLocked:
                return nil
            }
        }
        
        var qualifyingCount: Int? {
            switch self {
            case .marathonUnlocked:
                return 3
                
            case .doubleGoalUnlocked:
                return 7
                
            case .fiftyMilesUnlocked:
                return nil
                
            case .marathonLocked,
                    .thousandMilesUnlocked,
                    .goalMasterLocked:
                return nil
            }
        }
        
        var nextProgress: AchievementProgress? {
            switch self {
            case .fiftyMilesUnlocked:
                return AchievementProgress(
                    current: 87.4,
                    target: 100
                )
                
            case .marathonUnlocked,
                    .marathonLocked,
                    .thousandMilesUnlocked,
                    .doubleGoalUnlocked,
                    .goalMasterLocked:
                return nil
            }
        }
        
        var nextAchievement: Achievement? {
            switch self {
            case .fiftyMilesUnlocked:
                return .hundredMiles
                
            case .marathonUnlocked,
                    .marathonLocked,
                    .thousandMilesUnlocked,
                    .doubleGoalUnlocked,
                    .goalMasterLocked:
                return nil
            }
        }
    }
    
    let scenario: Scenario
    
    @StateObject private var themeStore = ThemeStore()
    
    var body: some View {
        AchievementDetailView(
            achievement: scenario.achievement,
            progress: scenario.progress,
            nextAchievement: scenario.nextAchievement,
            nextProgress: scenario.nextProgress,
            unlocked: scenario.unlocked,
            earnedDate: scenario.earnedDate,
            qualifyingCount: scenario.qualifyingCount
        )
        .environmentObject(themeStore)
    }
}

#Preview("Marathon — Unlocked") {
    AchievementDetailPreviewHost(
        scenario: .marathonUnlocked
    )
}

#Preview("Marathon — Locked") {
    AchievementDetailPreviewHost(
        scenario: .marathonLocked
    )
}

#Preview("50 Miles — Next Target") {
    AchievementDetailPreviewHost(
        scenario: .fiftyMilesUnlocked
    )
}

#Preview("1,000 Miles — Unlocked") {
    AchievementDetailPreviewHost(
        scenario: .thousandMilesUnlocked
    )
}

#Preview("Double Goal — Unlocked") {
    AchievementDetailPreviewHost(
        scenario: .doubleGoalUnlocked
    )
}

#Preview("Goal Master — Locked") {
    AchievementDetailPreviewHost(
        scenario: .goalMasterLocked
    )
}

#Preview("Half Marathon — Text Stress") {
    AchievementDetailView(
        achievement: .halfMarathon,
        progress: AchievementProgress(
            current: 14.2,
            target: 13.1094
        ),
        nextAchievement: .marathon,
        nextProgress: AchievementProgress(
            current: 14.2,
            target: 26.2188
        ),
        unlocked: true,
        earnedDate: Calendar.current.date(
            from: DateComponents(
                year: 2026,
                month: 7,
                day: 4
            )
        ),
        qualifyingCount: 5
    )
    .environmentObject(ThemeStore())
}
#endif
