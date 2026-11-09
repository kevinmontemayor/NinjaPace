//
//  WarriorSelectionView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/10/26.
//

import SwiftUI

struct WarriorSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ThemeWelcomeView {
            dismiss()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WarriorSelectionView()
            .environmentObject(ThemeStore())
            .environmentObject(HealthStreamManager())
            .environmentObject(SensitiveInfoUnlockManager())
            .environmentObject(AchievementUnlockManager())
    }
}
