//
//  AchievementUnlockManager.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/7/26.
//

import Foundation
import Combine

@MainActor
final class AchievementUnlockManager: ObservableObject {
    @Published private(set) var currentAchievement: Achievement?
    
    private var pendingAchievements: [Achievement] = []
    
    var hasAchievementToPresent: Bool {
        currentAchievement != nil
    }
    
    func enqueue(_ achievements: [Achievement]) {
        guard !achievements.isEmpty else { return }
        
        pendingAchievements.append(
            contentsOf: achievements
        )
        
        presentNextIfNeeded()
    }
    
    func dismissCurrentAchievement() {
        currentAchievement = nil
        presentNextIfNeeded()
    }
    
    func clear() {
        currentAchievement = nil
        pendingAchievements.removeAll()
    }
    
    private func presentNextIfNeeded() {
        guard currentAchievement == nil, !pendingAchievements.isEmpty else { return }
        
        currentAchievement = pendingAchievements.removeFirst()
    }
}
