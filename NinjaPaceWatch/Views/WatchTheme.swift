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

    /// Existing initiate artwork, also bundled into the Watch asset catalog.
    var heroAssetName: String {
        switch self {
        case .ninja: return "ninja_lvl1"
        case .viking: return "viking_lvl1"
        case .pirate: return "pirate_lvl1"
        case .knight: return "knight_lvl1"
        case .cyborg: return "cyborg_lvl1"
        case .spartan: return "spartan_lvl1"
        }
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

extension WatchTheme {
    // Keep these roles identical to AppTheme+HUDPreset.swift.
    // Watch tint remains independent (including its existing yellow Spartan accent).
    var primaryTextColor: Color {
        switch self {
        case .ninja: return Color(red: 0.85, green: 0.05, blue: 0.08)
        case .viking, .knight, .pirate, .cyborg: return .white
        case .spartan: return Color(red: 0.98, green: 0.95, blue: 0.86)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .ninja: return Color(red: 0.72, green: 0.08, blue: 0.10).opacity(0.88)
        case .viking: return .white.opacity(0.76)
        case .knight, .pirate: return .white.opacity(0.74)
        case .cyborg: return .white.opacity(0.72)
        case .spartan: return Color(red: 0.88, green: 0.82, blue: 0.68).opacity(0.88)
        }
    }

    var surfaceColor: Color {
        switch self {
        case .ninja: return .black.opacity(0.5)
        case .viking: return .orange.opacity(0.6)
        case .knight: return .blue.opacity(0.4)
        case .pirate: return .brown.opacity(0.6)
        case .cyborg: return .green.opacity(0.4)
        case .spartan: return Color(red: 0.28, green: 0.10, blue: 0.07).opacity(0.72)
        }
    }

    var homeTitle: String {
        switch self {
        case .ninja: return "FROM THE SHADOWS"
        case .viking: return "TO VALHALLA"
        case .pirate: return "HOIST THE SAILS"
        case .knight: return "HOLD THE LINE"
        case .cyborg: return "SYSTEMS ONLINE"
        case .spartan: return "SHIELDS UP"
        }
    }
}

#Preview("WatchTheme sample") {
    let theme: WatchTheme = .ninja
    return Text(theme.headerTitle)
        .font(.headline)
        .foregroundStyle(theme.tint)
}
