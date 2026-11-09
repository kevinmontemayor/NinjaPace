//
//  WarriorProgressView+CyborgPreviews.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/26/26.
//

import SwiftUI

#Preview("🤖 Cyborg — Level 1") {
    WarriorProgressView(
        theme: .cyborg,
        completedGoals: 2,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🤖 Cyborg — Level 2") {
    WarriorProgressView(
        theme: .cyborg,
        completedGoals: 10,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🤖 Cyborg — Level 3") {
    WarriorProgressView(
        theme: .cyborg,
        completedGoals: 25,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🤖 Cyborg — Level 4") {
    WarriorProgressView(
        theme: .cyborg,
        completedGoals: 50,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}
