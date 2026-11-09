//
//  WarriorProgressView+VikingPreviews.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/26/26.
//

import SwiftUI

#Preview("🪓 Viking — Level 1") {
    WarriorProgressView(
        theme: .viking,
        completedGoals: 2,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🪓 Viking — Level 2") {
    WarriorProgressView(
        theme: .viking,
        completedGoals: 10,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🪓 Viking — Level 3") {
    WarriorProgressView(
        theme: .viking,
        completedGoals: 25,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🪓 Viking — Level 4") {
    WarriorProgressView(
        theme: .viking,
        completedGoals: 50,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}
