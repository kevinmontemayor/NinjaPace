//
//  WarriorProgressView+NinjaPreviews.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/26/26.
//

import SwiftUI

#Preview("🥷 Ninja - Level 1") {
    WarriorProgressView(
        theme: .ninja,
        completedGoals: 2,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🥷 Ninja - Level 2") {
    WarriorProgressView(
        theme: .ninja,
        completedGoals: 10,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🥷 Ninja - Level 3") {
    WarriorProgressView(
        theme: .ninja,
        completedGoals: 25,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🥷 Ninja - Level 4") {
    WarriorProgressView(
        theme: .ninja,
        completedGoals: 50,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}
