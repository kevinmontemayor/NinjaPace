//
//  WarriorProgressView+SpartanPreviews.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/26/26.
//

import SwiftUI

#Preview("🏛 Spartan — Level 1") {
    WarriorProgressView(
        theme: .spartan,
        completedGoals: 2,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🏛 Spartan — Level 2") {
    WarriorProgressView(
        theme: .spartan,
        completedGoals: 10,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🏛 Spartan — Level 3") {
    WarriorProgressView(
        theme: .spartan,
        completedGoals: 25,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🏛 Spartan — Level 4") {
    WarriorProgressView(
        theme: .spartan,
        completedGoals: 1505,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}
