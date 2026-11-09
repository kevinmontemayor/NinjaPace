//
//  WarriorView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/27/26.
//

import SwiftUI

struct WarriorView: View {
    @AppStorage("hasSelectedWarrior")
    private var hasSelectedWarrior = false
    
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var healthStreamManager: HealthStreamManager
    @EnvironmentObject private var sensitiveInfoUnlockManager: SensitiveInfoUnlockManager
    
    var body: some View {
        Group {
            if hasSelectedWarrior {
                NinjaPaceMainView()
            } else {
                NavigationStack {
                    ThemeWelcomeView {
                        withAnimation(
                            .easeInOut(duration: 0.3)
                        ) {
                            hasSelectedWarrior = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    WarriorView()
        .environmentObject(ThemeStore())
        .environmentObject(HealthStreamManager())
        .environmentObject(SensitiveInfoUnlockManager())
        .environmentObject(AchievementUnlockManager())
}
