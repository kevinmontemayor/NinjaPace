//
//  AchievementUnlockedView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/7/26.
//

import SwiftUI

struct AchievementUnlockedView: View {
    
    @EnvironmentObject private var themeStore: ThemeStore
    
    let achievement: Achievement
    let dismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("ACHIEVEMENT UNLOCKED")
                .font(.caption.bold())
                .tracking(2)
                .foregroundStyle(.secondary)
            
            Image(achievement.badgeAsset)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)
                .accessibilityHidden(true)
            
            VStack(spacing: 8) {
                Text(achievement.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Label("Added to Awards", systemImage: "trophy.fill")
                .font(.subheadline.bold())
                .foregroundStyle(themeStore.theme.tint)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Continue Training")
                    .frame(maxWidth: .infinity)
            }
            .backgroundStyle(themeStore.theme.tint)
            .foregroundStyle(.white)
        }
        .padding(28)
        .presentationDetents([.medium])
    }
}

#Preview {
    AchievementUnlockedView(
        achievement: .hundredGoals,
        dismiss: {}
    )
    .environmentObject(ThemeStore())
}
