//
//  WarriorProgressView+PiratePreviews.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/26/26.
//

import SwiftUI

#Preview("🏴‍☠️ Pirate — Initiate") {
    WarriorProgressView(
        theme: .pirate,
        completedGoals: 2,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🏴‍☠️ Pirate — Charged") {
    WarriorProgressView(
        theme: .pirate,
        completedGoals: 10,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🏴‍☠️ Pirate — Armored") {
    WarriorProgressView(
        theme: .pirate,
        completedGoals: 25,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}

#Preview("🏴‍☠️ Pirate — Legendary") {
    WarriorProgressView(
        theme: .pirate,
        completedGoals: 50,
        isWorkoutRunning: true
    )
    .padding()
    .background(.black)
}
