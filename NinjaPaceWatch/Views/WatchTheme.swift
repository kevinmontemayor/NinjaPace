//
//  WatchTheme.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 2/28/26.
//

import SwiftUI

enum WatchThemeIcon: Equatable {
    case system(String)
    case asset(String)
}

enum WatchTheme: String, CaseIterable {
    case ninja
    case viking
    case pirate
    case knight
    case cyborg
    case spartan

    var displayName: String {
        switch self {
        case .ninja:
            return "Ninja"

        case .viking:
            return "Viking"

        case .pirate:
            return "Pirate"

        case .knight:
            return "Knight"

        case .cyborg:
            return "Cyborg"

        case .spartan:
            return "Spartan"
        }
    }

    var headerTitle: String {
        displayName
    }

    var emoji: String {
        switch self {
        case .ninja:
            return "🥷"

        case .viking:
            return "🪓"

        case .pirate:
            return "🏴‍☠️"

        case .knight:
            return "🛡️"

        case .cyborg:
            return "🤖"

        case .spartan:
            return "🏛️"
        }
    }

    var tint: Color {
        switch self {
        case .ninja:
            return .red

        case .viking:
            return .orange

        case .pirate:
            return .brown

        case .knight:
            return .blue

        case .cyborg:
            return .green

        case .spartan:
            return .yellow
        }
    }

    var icon: WatchThemeIcon {
        switch self {
        case .ninja:
            return .asset("shuriken")

        case .viking:
            return .asset("viking_axes")

        case .pirate:
            return .asset("pirate_blunderbuss")

        case .knight:
            return .asset("knight_sword")

        case .cyborg:
            return .asset("cyborg_blaster")

        case .spartan:
            return .asset("spartan_spear")
        }
    }

    static func from(_ key: String) -> WatchTheme {
        WatchTheme(
            rawValue:
                key
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .lowercased()
        ) ?? .ninja
    }
    
    var iconAnimation: WatchThemeIconAnimation {
        switch self {
            
        case .ninja:
            return .spin
            
        case .knight,
                .viking,
                .pirate,
                .cyborg,
                .spartan:
            return .pulse
        }
    }

    var iconAnimationDuration: Double {
        switch self {

        case .cyborg:
            return 0.65

        case .pirate:
            return 1.15

        case .knight:
            return 1.25

        case .spartan:
            return 1.35

        case .ninja:
            return 2.2

        case .viking:
            return 2.2
        }
    }
    
    var celebrationSoundAsset: String {
        switch self {
        case .ninja:
            return "goal_complete_ninja_watch"

        case .viking:
            return "goal_complete_viking_watch"

        case .pirate:
            return "goal_complete_pirate_watch"

        case .knight:
            return "goal_complete_knight_watch"

        case .cyborg:
            return "goal_complete_cyborg_watch"

        case .spartan:
            return "goal_complete_spartan_watch"
        }
    }
}

#Preview("WatchTheme sample") {
    let theme: WatchTheme = .ninja
    return Text(theme.headerTitle)
        .font(.headline)
        .foregroundStyle(theme.tint)
}
