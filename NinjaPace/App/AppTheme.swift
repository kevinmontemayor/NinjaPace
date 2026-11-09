//
//  AppTheme.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/27/26.
//

import Foundation
import SwiftUI

enum ThemeToolbarAnimation {
    case spin, pulse
}

struct ThemeToolbarIcon {
    let systemName: String?
    let assetName: String?
    
    static func system(_ name: String) -> Self {
        .init(systemName: name, assetName: nil)
    }
    
    static func asset(_ name: String) -> Self {
        .init(systemName: nil, assetName: name)
    }
}

enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case ninja, viking, knight, pirate, cyborg, spartan
    
    var celebrationSoundAsset: String {
        switch self {
        case .ninja: return "goal_complete_ninja"
        case .viking: return "goal_complete_viking"
        case .knight: return "goal_complete_knight"
        case .pirate: return "goal_complete_pirate"
        case .cyborg: return "goal_complete_cyborg"
        case .spartan: return "goal_complete_spartan"
        }
    }
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .ninja: return "Ninja"
        case .viking: return "Viking"
        case .knight: return "Knight"
        case .pirate: return "Pirate"
        case .cyborg: return "Cyborg"
        case .spartan: return "Spartan"
        }
    }

    var launchPadTitle: String {
        switch self {
        case .ninja: return "Ninja Dojo"
        case .viking: return "Viking Longhouse"
        case .knight: return "Knight Command"
        case .pirate: return "Pirate Deck"
        case .cyborg: return "Cyborg Control"
        case .spartan: return "Spartan Arena"
        }
    }

    var toolbarIcon: ThemeToolbarIcon {
        switch self {
        case .ninja: return .asset("shuriken")
        case .viking: return .asset("viking_axes")
        case .knight: return .asset("knight_sword")
        case .pirate: return .asset("pirate_blunderbuss")
        case .cyborg: return .asset("cyborg_blaster")
        case .spartan: return .asset("spartan_spear")
        }
    }

    var tint: Color {
        switch self {
        case .ninja, .spartan: return .red
        case .viking: return .orange
        case .knight: return .blue
        case .pirate: return .brown
        case .cyborg: return .green
        }
    }

    var badgeFill: Color {
        tint.opacity(0.9)
    }

    var cardArtAsset: String {
        "icon-\(rawValue)"
    }

    var homeBackgroundAsset: String {
        switch self {
        case .ninja: return "ninja-dojo"
        case .viking: return "viking-fjord"
        case .knight: return "knight-castle"
        case .pirate: return "pirate-boathouse"
        case .cyborg: return "cyborg-lab"
        case .spartan: return "spartan-courtyard"
        }
    }

    var toolbarAnimation: ThemeToolbarAnimation {
        self == .ninja ? .spin : .pulse
    }

    var toolbarAnimationDuration: Double {
        switch self {
        case .cyborg: return 0.75
        case .pirate: return 1.15
        case .knight: return 1.1
        case .spartan: return 1.35
        case .ninja: return 1.25
        case .viking: return 1.75
        }
    }
    
    var celebrationPrimaryIcon: ThemeToolbarIcon {
        switch self {
        case .ninja:
            return .asset("shuriken")

        case .viking:
            return .asset("viking_axe")

        case .knight:
            return .asset("knight_sword")

        case .pirate:
            return .asset("pirate_cannonball")

        case .cyborg:
            return .asset("cyborg_microchip")

        case .spartan:
            return .asset("spartan_spear")
        }
    }

    var celebrationSecondaryIcon: ThemeToolbarIcon {
        switch self {
        case .ninja:
            return .asset("ninja_kunai")

        case .viking:
            return .asset("viking_shield")

        case .knight:
            return .asset("knight_shield")

        case .pirate:
            return .asset("pirate_flag")

        case .cyborg:
            return .asset("cyborg_energy_bolt")

        case .spartan:
            return .asset("spartan_shield")
        }
    }

    func warriorAsset(for level: WarriorProgressionLevel) -> String {
        let suffix: String

        switch level {
        case .level1: suffix = "initiate"
        case .level2: suffix = "charged"
        case .level3: suffix = "armored"
        case .level4: suffix = "legendary"
        }

        return "\(rawValue)_\(suffix)"
    }

    func progressionTitle(for level: WarriorProgressionLevel) -> String {
        switch (self, level) {
        case (.ninja, .level1): return "Shinobi"
        case (.ninja, .level2): return "Shinobi no Sensei"
        case (.ninja, .level3): return "Shinobi no Mono"
        case (.ninja, .level4): return "Tatsujin"

        case (.viking, .level1): return "Drengr"
        case (.viking, .level2): return "Raider"
        case (.viking, .level3): return "Hersir"
        case (.viking, .level4): return "Jarl"

        case (.knight, .level1): return "Squire"
        case (.knight, .level2): return "Knight"
        case (.knight, .level3): return "Champion"
        case (.knight, .level4): return "Paladin"

        case (.pirate, .level1): return "Deckhand"
        case (.pirate, .level2): return "Corsair"
        case (.pirate, .level3): return "Captain"
        case (.pirate, .level4): return "Pirate Lord"

        case (.cyborg, .level1): return "Prototype"
        case (.cyborg, .level2): return "Augmented"
        case (.cyborg, .level3): return "Vanguard"
        case (.cyborg, .level4): return "Apex"

        case (.spartan, .level1): return "Agōgē"
        case (.spartan, .level2): return "Hoplite"
        case (.spartan, .level3): return "Lochagos"
        case (.spartan, .level4): return "Strategos"
        }
    }
    
    func goalAchievementNotification(goalMiles: Double) -> GoalAchievementNotification {
        let miles = goalMiles.formatted(
            .number.precision(.fractionLength(0...2))
        )

        switch self {
        case .ninja:
            return GoalAchievementNotification(
                title: "MISSION COMPLETE 🥷",
                body: "\(miles) miles conquered. Your target has fallen. The dojo approves."
            )

        case .viking:
            return GoalAchievementNotification(
                title: "CONQUEST COMPLETE 🪓",
                body: "\(miles) miles conquered. The longhouse roars. Valhalla has taken notice."
            )

        case .knight:
            return GoalAchievementNotification(
                title: "QUEST COMPLETE ⚔️",
                body: "\(miles) miles completed. Victory is yours, champion. Return to the castle in glory."
            )

        case .pirate:
            return GoalAchievementNotification(
                title: "TREASURE CLAIMED 🏴‍☠️",
                body: "\(miles) miles plundered. The course is conquered and the crew demands a celebration."
            )

        case .cyborg:
            return GoalAchievementNotification(
                title: "OBJECTIVE COMPLETE 🤖",
                body: "\(miles) MI TARGET ACHIEVED. PERFORMANCE: OPTIMAL. HUMAN LIMITATIONS: QUESTIONABLE."
            )

        case .spartan:
            return GoalAchievementNotification(
                title: "VICTORY 🛡️",
                body: "\(miles) miles conquered. The agōgē is satisfied. Return with your shield."
            )
        }
    }
}

#if DEBUG

private struct AnimatedThemePreviewIcon: View {
    let theme: AppTheme

    @State private var rotation: Double = 0
    @State private var isPulsing = false

    var body: some View {
        Group {
            switch theme.toolbarAnimation {
            case .spin:
                icon.rotationEffect(.degrees(rotation))

            case .pulse:
                icon
                    .scaleEffect(isPulsing ? 1.18 : 0.94)
                    .opacity(isPulsing ? 1 : 0.72)
                    .shadow(
                        color: theme.appPrimaryTextColor.opacity(isPulsing ? 0.85 : 0.20),
                        radius: isPulsing ? 7 : 2
                    )
            }
        }
        .frame(width: 32, height: 32)
        .onAppear {
            startAnimation()
        }
    }

    private var icon: some View {
        ThemeIconView(icon: theme.toolbarIcon, tint: theme.appPrimaryTextColor, size: 26)
    }

    private func startAnimation() {
        switch theme.toolbarAnimation {
        case .spin:
            rotation = 0
            withAnimation(.linear(duration: theme.toolbarAnimationDuration).repeatForever(autoreverses: false)) {
                rotation = 360
            }

        case .pulse:
            isPulsing = false
            withAnimation(.easeInOut(duration: theme.toolbarAnimationDuration).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#Preview("AppTheme Sample") {
    VStack(spacing: 12) {
        ForEach(AppTheme.allCases) { theme in
            HStack(spacing: 12) {
                AnimatedThemePreviewIcon(theme: theme)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.headline)
                        .foregroundStyle(theme.appPrimaryTextColor)

                    Text(theme.launchPadTitle)
                        .font(.caption)
                        .foregroundStyle(theme.appSecondaryTextColor)

                    Text(animationDescription(for: theme))
                        .font(.caption2)
                        .foregroundStyle(theme.appSecondaryTextColor)
                }

                Spacer()

                Circle()
                    .fill(theme.badgeFill)
                    .frame(width: 16, height: 16)
            }
            .padding(8)
            .background(
                theme.hudEditorRowBackground,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
    }
    .padding()
}

private func animationDescription(for theme: AppTheme) -> String {
    let name = theme.toolbarAnimation == .spin ? "Spin" : "Pulse"
    return "\(name) • \(theme.toolbarAnimationDuration, default: "%.2f") sec"
}

#endif
