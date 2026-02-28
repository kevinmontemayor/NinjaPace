//
//  WatchTheme.swift
//  NinjaPaceWatch Watch App
//
//  Created by Kevin Montemayor on 2/28/26.
//

import SwiftUI

enum WatchTheme: String, CaseIterable {
    case ninja, viking, pirate, knight, cyborg, spartan

    var displayName: String {
        switch self {
        case .ninja: return "Ninja"
        case .viking: return "Viking"
        case .pirate: return "Pirate"
        case .knight: return "Knight"
        case .cyborg: return "Cyborg"
        case .spartan: return "Spartan"
        }
    }

    var headerTitle: String {
        "\(displayName)"
    }

    var emoji: String {
        switch self {
        case .ninja: return "🥷"
        case .viking: return "🪓"
        case .pirate: return "🏴‍☠️"
        case .knight: return "🛡️"
        case .cyborg: return "🤖"
        case .spartan: return "🏛️"
        }
    }

    var tint: Color {
        switch self {
        case .ninja: return .red
        case .viking: return .orange
        case .pirate: return .brown
        case .knight: return .blue
        case .cyborg: return .green
        case .spartan: return .yellow
        }
    }
    
    var symbol: String {
        switch self {
        case .ninja:   return "sparkles"
        case .viking:  return "hammer.fill"
        case .pirate:  return "flag.fill"
        case .knight:  return "shield.fill"
        case .cyborg:  return "cpu"
        case .spartan: return "building.columns.fill"
        }
    }
    
    static func from(_ key: String) -> WatchTheme {
        WatchTheme(rawValue: key.lowercased()) ?? .ninja
    }
}

#Preview("WatchTheme sample") {
    let theme: WatchTheme = .ninja
    return Text(theme.headerTitle)
        .font(.headline)
        .foregroundStyle(theme.tint)
}
