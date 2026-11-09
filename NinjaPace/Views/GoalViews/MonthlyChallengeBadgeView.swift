//
//  MonthlyChallengeBadgeView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 9/19/26.
//

import SwiftData
import SwiftUI

struct MonthlyChallengeBadgeView: View {
    let challenge: MonthlyChallenge
    let unlocked: Bool
    var body: some View {
        ZStack {
            if UIImage(named: challenge.badgeAsset) != nil {
                Image(challenge.badgeAsset).resizable().scaledToFit()
            } else {
                ZStack {
                    Circle().fill(.yellow.gradient)
                    Circle().strokeBorder(.white.opacity(0.7), lineWidth: 5).padding(8)
                    VStack(spacing: 6) {
                        Image(systemName: "shield.lefthalf.filled").font(.largeTitle)
                        Text(Calendar.current.monthSymbols[challenge.month - 1].uppercased())
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.black.opacity(0.8))
                }
                .padding(12)
            }
        }
        .saturation(unlocked ? 1 : 0)
        .opacity(unlocked ? 1 : 0.45)
        .overlay {
            if !unlocked {
                Image(systemName: "lock.shield.fill")
                    .font(.largeTitle).foregroundStyle(.white).shadow(color: .black, radius: 8)
            }
        }
        .accessibilityHidden(true)
    }
}

struct MonthlyChallengeView: View {
    let date: Date
    var celebrate = false
#if DEBUG
var previewUnlocked: Bool? = nil
#endif
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @Query private var workouts: [WorkoutRecord]
    @ObservedObject private var store = MonthlyChallengeStore.shared
    @AppStorage(GoalCelebrationSettings.enabledKey) private var celebrationsEnabled = true
    @State private var showsCelebration = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let calendar = Calendar.autoupdatingCurrent
            let challenge = MonthlyChallenge.challenge(for: calendar.component(.month, from: date))!
            let reward = store.reward(for: date)
            let progress = MonthlyChallengeEngine(workouts: workouts).progress(for: date, now: timeline.date)
#if DEBUG
            let unlocked = previewUnlocked ?? (reward != nil)
#else
            let unlocked = reward != nil
#endif
            let end = calendar.dateInterval(of: .month, for: date)!.end
            ZStack {
                WarriorBackgroundView()
                ScrollView {
                    VStack(spacing: 20) {
                        Text(date.formatted(.dateTime.month(.wide).year())).font(.headline)
                        
                        MonthlyChallengeBadgeView(challenge: challenge, unlocked: unlocked)
                            .frame(width: 260, height: 260)
                            .shadow(color: themeStore.theme.tint.opacity(unlocked ? 0.5 : 0.15), radius: 20)
                        
                        Text(challenge.title).font(.largeTitle.bold())
                        
                        Text(challenge.description).font(.title3)
                        
                        Label(unlocked ? "ACHIEVEMENT UNLOCKED" : "ACHIEVEMENT LOCKED",
                              systemImage: unlocked ? "checkmark.seal.fill" : "lock.fill")
                        ProgressView(value: unlocked ? 1 : progress.fraction)
                        
                        Text((unlocked ? 1.0 : progress.fraction).formatted(.percent.precision(.fractionLength(0))) + " complete")
                            .font(.caption.bold())
                        
                        Text(progressLabel(challenge: challenge, current: unlocked ? max(progress.current, challenge.target) : progress.current))
                            .monospacedDigit()
                        
                        if let reward {
                            Text("Earned \(reward.completedAt.formatted(date: .abbreviated, time: .omitted))")
                            Text("Saved to your Monthly Hall of Legends.")
                        } else if timeline.date >= end {
                            Text("This challenge has ended.")
                        } else if date > timeline.date && !calendar.isDate(date, equalTo: timeline.date, toGranularity: .month) {
                            Text("Opens on the first day of the month.")
                        } else {
                            Text("\(max(1, calendar.dateComponents([.day], from: calendar.startOfDay(for: timeline.date), to: end).day ?? 0)) days remaining")
                            Text("Complete your mission before \(end.formatted(date: .abbreviated, time: .omitted)) to claim this reward.")
                        }
                        
                        Button("Continue Training") { dismiss() }
                            .buttonStyle(.borderedProminent)
                            .foregroundStyle(.white)
                    }
                    .multilineTextAlignment(.center).padding(28)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                }
                if showsCelebration {
                    GoalCelebrationView(
                        theme: themeStore.theme,
                        seed: 12,
                        style: .monthlyChallenge
                    )
                    .allowsHitTesting(false)
                }
            }
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
                
                ToolbarItem(placement: .principal) {
                    Text(celebrate ? "MONTHLY CHALLENGE CONQUERED!" : "MONTHLY CHALLENGE")
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                }
            }
        }
        .tint(themeStore.theme.tint)
        .task {
            guard celebrate, celebrationsEnabled else {
                return
            }
            
            withAnimation(.easeOut(duration: 0.14)) {
                showsCelebration = true
            }
            
            GoalCelebrationSoundPlayer.shared.play(
                assetName: "monthly_challenge_complete"
            )
            
            try? await Task.sleep(
                for: .seconds(2.6)
            )
            
            guard !Task.isCancelled else {
                return
            }
            
            withAnimation(.easeOut(duration: 0.22)) {
                showsCelebration = false
            }
        }
    }

    private func progressLabel(challenge: MonthlyChallenge, current: Double) -> String {
        if challenge.metric == .workouts { return "\(Int(current)) / \(Int(challenge.target)) workouts" }
        return "\(current.formatted(.number.precision(.fractionLength(2)))) / \(challenge.target.formatted(.number.precision(.fractionLength(2)))) miles"
    }
    
    private func navigateBack() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            dismiss()
        }
    }
}

struct MonthlyChallengeVault: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject private var store = MonthlyChallengeStore.shared

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            VStack(alignment: .leading, spacing: 12) {
                NavigationLink {
                    MonthlyChallengeView(date: timeline.date)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("THIS MONTH · \(MonthlyChallenge.current?.title ?? "Challenge")").bold()
                        Text(MonthlyChallenge.current?.description ?? "")
                        Label("View Challenge Details", systemImage: "arrow.up.right.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding()
                    .background(themeStore.theme.hudEditorRowBackground, in: RoundedRectangle(cornerRadius: 16))
                }
                .accessibilityIdentifier("currentMonthlyChallenge")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                    ForEach(MonthlyChallenge.all) { challenge in
                        let date = monthDate(challenge.month, year: Calendar.current.component(.year, from: timeline.date))
                        NavigationLink {
                            MonthlyChallengeView(date: date)
                        } label: {
                            VStack {
                                MonthlyChallengeBadgeView(challenge: challenge, unlocked: store.reward(for: date) != nil)
                                    .frame(height: 90)
                                Text(date.formatted(.dateTime.month(.abbreviated))).font(.caption.bold())
                            }
                        }
                        .accessibilityLabel("\(challenge.title), \(store.reward(for: date) == nil ? "locked" : "earned")")
                    }
                }
                if !store.rewards.isEmpty {
                    Text("Monthly Hall of Legends").font(.headline)
                    ForEach(store.rewards.sorted { $0.id > $1.id }) { reward in
                        NavigationLink {
                            MonthlyChallengeView(date: monthDate(reward.month, year: reward.year))
                        } label: {
                            Label("\(MonthlyChallenge.challenge(for: reward.month)?.title ?? "Challenge") · \(String(reward.year))",
                                  systemImage: "medal.fill")
                        }
                    }
                }
                if let error = store.schedulingError { Text(error).font(.caption) }
            }
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
    }

    private func monthDate(_ month: Int, year: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))!
    }
}

// MARK: - SwiftUI Previews

#if DEBUG

@MainActor
private struct MonthlyChallengePreviewHost: View {
    
    enum PreviewMode {
        case vault
        case locked
        case unlocked
    }
    
    let mode: PreviewMode
    @StateObject private var themeStore = ThemeStore()
    private let container: ModelContainer

    init(mode: PreviewMode) {
        self.mode = mode
        do {
            container = try ModelContainer(
                for: WorkoutRecord.self,
                configurations: ModelConfiguration(
                    isStoredInMemoryOnly: true
                )
            )
        } catch {
            fatalError("Monthly Challenge Preview failed: \(error)")
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .vault:
                    ScrollView { MonthlyChallengeVault().padding() }
                case .locked:
                    MonthlyChallengeView(
                        date: previewDate,
                        celebrate: false,
                        previewUnlocked: false
                    )
                case .unlocked:
                    MonthlyChallengeView(
                        date: previewDate,
                        celebrate: false,
                        previewUnlocked: true
                    )
                }
            }
        }
        .modelContainer(container)
        .environmentObject(themeStore)
    }

    private var previewDate: Date {
        Calendar.current.date(
            from: DateComponents(
                year: 2026,
                month: 11,
                day: 15
            )
        ) ?? .now
    }
}

// MARK: - Preview: Complete Monthly Collection

#Preview("Monthly Challenge Vault") {
    MonthlyChallengePreviewHost(
        mode: .vault
    )
}


// MARK: - Preview: Locked Achievement

#Preview("Monthly Challenge - Locked") {

    MonthlyChallengePreviewHost(
        mode: .locked
    )
}


// MARK: - Preview: Unlocked Achievement

#Preview("Monthly Challenge - Unlocked") {

    MonthlyChallengePreviewHost(
        mode: .unlocked
    )
}


// MARK: - Preview: All 12 Badge Images

#Preview("All Monthly Badges") {

    ScrollView {

        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 20
        ) {

            ForEach(MonthlyChallenge.all) { challenge in

                VStack(spacing: 8) {

                    MonthlyChallengeBadgeView(
                        challenge: challenge,
                        unlocked: true
                    )
                    .frame(width: 100, height: 100)

                    Text(challenge.title)
                        .font(.caption.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
    }
    .background(Color.black)
}


// MARK: - Preview: Locked Badge Collection

#Preview("All Monthly Badges - Locked") {

    ScrollView {

        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: 20
        ) {

            ForEach(MonthlyChallenge.all) { challenge in

                VStack(spacing: 8) {

                    MonthlyChallengeBadgeView(
                        challenge: challenge,
                        unlocked: false
                    )
                    .frame(width: 100, height: 100)

                    Text(challenge.title)
                        .font(.caption.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
    }
    .background(Color.black)
}

#endif
