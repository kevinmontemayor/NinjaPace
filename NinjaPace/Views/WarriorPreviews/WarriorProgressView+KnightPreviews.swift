//
//  WarriorProgressView+KnightPreviews.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/26/26.
//

import SwiftUI

#Preview("⚔️ Knight — Level 1") {
    WarriorProgressView(
        theme: .knight,
        completedGoals: 2,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("⚔️ Knight — Level 2") {
    WarriorProgressView(
        theme: .knight,
        completedGoals: 10,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("⚔️ Knight — Level 3") {
    WarriorProgressView(
        theme: .knight,
        completedGoals: 25,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("⚔️ Knight — Level 4") {
    WarriorProgressView(
        theme: .knight,
        completedGoals: 50,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}
