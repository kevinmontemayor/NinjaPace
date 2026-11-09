//
//  AchievementMasteryView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 10/12/26.
//

import SwiftUI

struct AchievementMasteryView: View {
    @AppStorage(GoalCelebrationSettings.enabledKey)
    private var celebrationsEnabled = true
    
    @EnvironmentObject private var themeStore: ThemeStore

    let achievementCount: Int
    let dismiss: () -> Void

    @State private var celebrating = false

    var body: some View {
        ZStack {
            WarriorBackgroundView()
            
            RadialGradient(
                colors: [
                    themeStore.theme.tint.opacity(celebrating ? 0.30 : 0.12),
                    Color.yellow.opacity(celebrating ? 0.16 : 0.06),
                    .clear
                ],
                center: .center,
                startRadius: 30,
                endRadius: 430
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)
            
            VStack(spacing: 22) {
                Spacer()
                
                Text("COLLECTION MASTERED")
                    .font(.caption.bold())
                    .tracking(3)
                    .foregroundStyle(.yellow)
                
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(celebrating ? 0.18 : 0.08))
                        .frame(width: 190, height: 190)
                        .scaleEffect(celebrating ? 1.08 : 0.92)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, themeStore.theme.tint, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(celebrating ? 360 : 0))
                    
                    Image("achievement_grandmaster")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 135, height: 135)
                        .shadow(
                            color: themeStore.theme.tint.opacity(0.65),
                            radius: celebrating ? 18 : 8
                        )
                }
                .accessibilityHidden(true)
                
                VStack(spacing: 10) {
                    Text("NINJAPACE GRANDMASTER")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .allowsTightening(true)
                        .frame(maxWidth: .infinity)
                        .layoutPriority(1)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, themeStore.theme.tint, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Every challenge conquered. Every milestone claimed. Well done, Warrior!")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                }
                
                Label(
                    "\(achievementCount) / \(achievementCount) Awards Unlocked",
                    systemImage: "trophy.fill"
                )
                .font(.headline.bold())
                .foregroundStyle(themeStore.theme.tint)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(themeStore.theme.tint.opacity(0.12), in: Capsule())
                
                Text("100% COMPLETE")
                    .font(.caption.bold())
                    .tracking(2)
                    .foregroundStyle(.green)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Label("Enter the Hall of Legends", systemImage: "sparkles")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(themeStore.theme.tint)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            
            GoalCelebrationView(
                theme: themeStore.theme,
                seed: 47,
                style: .grandmaster
            )
            .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                celebrating = true
            }
        }
        .task {
            guard celebrationsEnabled else { return }
            
            GoalCelebrationSoundPlayer.shared.play(
                assetName: "achievement_grandmaster"
            )
        }
    }
}

#Preview {
    AchievementMasteryView(achievementCount: Achievement.allCases.count, dismiss: {})
        .environmentObject(ThemeStore())
}
