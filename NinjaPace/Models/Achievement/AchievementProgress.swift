//
//  AchievementProgress.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/7/26.
//

import Foundation

struct AchievementProgress {
    let current: Double
    let target: Double
    
    var fraction: Double {
        guard target > 0 else {
            return 0
        }
        
        return min(current / target, 1)
    }
    
    var isComplete: Bool {
        current >= target
    }
}
