//
//  WatchWarriorArtworkView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import SwiftUI

struct WatchWarriorArtworkView: View {
    let theme: WatchTheme
    let warriorLevel: WarriorProgressionLevel?
    let running: Bool
    let paused: Bool
    var identifier = "warriorArtwork"

    private var artwork: String {
        warriorLevel?.assetName(forThemeKey: theme.rawValue)
            ?? theme.heroAssetName
    }

    var body: some View {
        Image(artwork)
            .resizable()
            .scaledToFit()
            .accessibilityLabel(
                warriorLevel == nil
                    ? "\(theme.displayName) warrior. Progression awaiting iPhone sync"
                    : "\(theme.displayName) warrior"
            )
            .accessibilityValue(artwork)
            .accessibilityIdentifier(identifier)
    }
}

struct WatchDashboardBackground: View {
    let theme: WatchTheme

    var body: some View {
        RadialGradient(colors: [theme.tint.opacity(0.24), .black],
                       center: .topLeading, startRadius: 0, endRadius: 230)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

struct WatchWorkoutStatusView: View {
    @ObservedObject var manager: WatchWorkoutManager
    let theme: WatchTheme
    var compact = false

    var body: some View {
        Text(manager.running ? (manager.paused ? "PAUSED" : "LIVE") : "READY")
            .font(.system(size: compact ? 10 : 12, weight: .bold, design: .rounded))
            .foregroundStyle(manager.running ? (manager.paused ? Color.yellow : .green) : theme.secondaryTextColor)
            .accessibilityIdentifier("workoutStatus")
    }
}

#if DEBUG
private struct WatchWarriorArtworkPreview: View {
    let theme: WatchTheme
    let level: WarriorProgressionLevel?
    let running: Bool
    let paused: Bool

    var body: some View {
        ZStack {
            WatchDashboardBackground(theme: theme)

            WatchWarriorArtworkView(
                theme: theme,
                warriorLevel: level,
                running: running,
                paused: paused
            )
            .frame(width: 150, height: 110)
            .padding()
        }
    }
}

#Preview("🥷 Ninja — Awaiting Sync") {
    WatchWarriorArtworkPreview(
        theme: .ninja,
        level: nil,
        running: false,
        paused: false
    )
}

#Preview("🥷 Ninja — Shinobi") {
    WatchWarriorArtworkPreview(
        theme: .ninja,
        level: .level1,
        running: false,
        paused: false
    )
}

#Preview("🥷 Ninja — Sensei") {
    WatchWarriorArtworkPreview(
        theme: .ninja,
        level: .level2,
        running: true,
        paused: false
    )
}

#Preview("🥷 Ninja — Shinobi no Mono") {
    WatchWarriorArtworkPreview(
        theme: .ninja,
        level: .level3,
        running: true,
        paused: true
    )
}

#Preview("🥷 Ninja — Tatsujin") {
    WatchWarriorArtworkPreview(
        theme: .ninja,
        level: .level4,
        running: true,
        paused: false
    )
}

#Preview("🪓 Viking — Jarl") {
    WatchWarriorArtworkPreview(
        theme: .viking,
        level: .level4,
        running: true,
        paused: false
    )
}

#Preview("⚔️ Knight — Paladin") {
    WatchWarriorArtworkPreview(
        theme: .knight,
        level: .level4,
        running: true,
        paused: false
    )
}

#Preview("🏴‍☠️ Pirate — Captain") {
    WatchWarriorArtworkPreview(
        theme: .pirate,
        level: .level3,
        running: true,
        paused: false
    )
}

#Preview("🤖 Cyborg — Vanguard") {
    WatchWarriorArtworkPreview(
        theme: .cyborg,
        level: .level3,
        running: true,
        paused: false
    )
}

#Preview("🛡️ Spartan — Strategos") {
    WatchWarriorArtworkPreview(
        theme: .spartan,
        level: .level4,
        running: true,
        paused: false
    )
}
#endif
