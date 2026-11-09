//
//  MacRelayTheme.swift
//  NinjaPaceMac
//
//  Created by Kevin Montemayor on 8/23/26.
//

import SwiftUI

enum MacRelayIcon: Equatable {
    case system(String)
    case asset(String)
}

enum MacRelayIconAnimation {
    case spin
    case pulse
}

enum MacRelayTheme: String, Equatable {

    case ninja
    case viking
    case knight
    case pirate
    case cyborg
    case spartan

    init(themeKey: String?) {

        guard let themeKey else {
            self = .ninja
            return
        }

        let key = themeKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch key {

        case "viking":
            self = .viking

        case "knight":
            self = .knight

        case "pirate":
            self = .pirate

        case "cyborg":
            self = .cyborg

        case "spartan":
            self = .spartan

        case "ninja":
            self = .ninja

        default:
            self = .ninja
        }
    }
    
    var displayName: String {

        switch self {

        case .ninja:
            return "Ninja"

        case .viking:
            return "Viking"

        case .knight:
            return "Knight"

        case .pirate:
            return "Pirate"

        case .cyborg:
            return "Cyborg"

        case .spartan:
            return "Spartan"
        }
    }

    var icon: MacRelayIcon {
        switch self {

        case .ninja:
            return .asset("shuriken")

        case .viking:
            return .asset("viking_axes")

        case .knight:
            return .asset("knight_sword")

        case .pirate:
            return .asset("pirate_blunderbuss")

        case .cyborg:
            return .asset("cyborg_blaster")

        case .spartan:
            return .asset("spartan_spear")
        }
    }
    
    var primaryColor: Color {

        switch self {

        case .ninja:
            return .red

        case .viking:
            return .white

        case .knight:
            return .blue

        case .pirate:
            return .orange

        case .cyborg:
            return .cyan

        case .spartan:
            return .yellow
        }
    }

    var secondaryColor: Color {

        switch self {

        case .ninja:
            return .black

        case .viking:
            return .blue

        case .knight:
            return .indigo

        case .pirate:
            return .brown

        case .cyborg:
            return .purple

        case .spartan:
            return .orange
        }
    }

    var backgroundGradient: [Color] {

        switch self {

        case .ninja:
            return [
                .black,
                .red.opacity(0.22),
                .cyan.opacity(0.10)
            ]

        case .viking:
            return [
                .black,
                .gray.opacity(0.28),
                .blue.opacity(0.08)
            ]

        case .knight:
            return [
                .black,
                .blue.opacity(0.22),
                .indigo.opacity(0.14)
            ]

        case .pirate:
            return [
                .black,
                .brown.opacity(0.30),
                .orange.opacity(0.14)
            ]

        case .cyborg:
            return [
                .black,
                .green.opacity(0.22),
                .cyan.opacity(0.16)
            ]

        case .spartan:
            return [
                .black,
                .red.opacity(0.25),
                .yellow.opacity(0.12)
            ]
        }
    }

    var glowColor: Color {
        primaryColor.opacity(0.28)
    }

    var cardTint: Color {
        primaryColor.opacity(0.055)
    }

    var borderColor: Color {
        primaryColor.opacity(0.22)
    }
    
    var iconAnimation: MacRelayIconAnimation {
        switch self {
        case .ninja:
            return .spin
        case .viking, .knight, .pirate, .cyborg, .spartan:
            return .pulse
        }
    }

    var iconAnimationDuration: Double {
        switch self {
        case .cyborg:
            return 0.75
        case .pirate:
            return 1.15
        case .knight:
            return 1.1
        case .spartan:
            return 1.35
        case .ninja:
            return 1.25
        case .viking:
            return 1.75
        }
    }
}

#if DEBUG

#Preview("🥷 Ninja") {
    ContentView(
        server: .preview(theme: "ninja"),
        startsServerAutomatically: false
    )
}

#Preview("🛡️ Viking") {
    ContentView(
        server: .preview(theme: "viking"),
        startsServerAutomatically: false
    )
}

#Preview("⚔️ Knight") {
    ContentView(
        server: .preview(theme: "knight"),
        startsServerAutomatically: false
    )
}

#Preview("🏴‍☠️ Pirate") {
    ContentView(
        server: .preview(theme: "pirate"),
        startsServerAutomatically: false
    )
}

#Preview("🤖 Cyborg") {
    ContentView(
        server: .preview(theme: "cyborg"),
        startsServerAutomatically: false
    )
}

#Preview("🛡️ Spartan") {
    ContentView(
        server: .preview(theme: "spartan"),
        startsServerAutomatically: false
    )
}

@MainActor
extension MacRelayServer {

    static func preview(
        theme: String,
        miles: Double = 4.82,
        steps: Int = 10_542,
        hr: Int = 142,
        elapsed: String = "00:48:32",
        goalMiles: Double = 6.21,
        progress: Double = 0.78,
        running: Bool = true
    ) -> MacRelayServer {

        let server = MacRelayServer()

        server.configurePreview(
            theme: theme,
            miles: miles,
            steps: steps,
            hr: hr,
            elapsed: elapsed,
            goalMiles: goalMiles,
            progress: progress,
            running: running
        )

        return server
    }
}

#endif
