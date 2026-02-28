//
//  AppTheme.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/27/26.
//

import SwiftUI

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

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ninja:  return "Ninja"
        case .viking: return "Viking"
        case .knight: return "Knight"
        case .pirate: return "Pirate"
        case .cyborg: return "Cyborg"
        case .spartan: return "Spartan"
        }
    }

    /// Navigation title
    var launchPadTitle: String {
        switch self {
        case .ninja:  return "Ninja Dojo"
        case .viking: return "Viking Longhouse"
        case .knight: return "Knight Command"
        case .pirate: return "Pirate Deck"
        case .cyborg: return "Cyborg Control"
        case .spartan: return "Spartan Arena"
        }
    }
    
    var toolbarIcon: ThemeToolbarIcon {
        switch self {
        case .ninja:
            return .asset("shuriken")
        case .viking:
            return .system("hammer.fill")
        case .knight:
            return .system("shield.fill")
        case .pirate:
            return .system("flag.fill")
        case .spartan:
            return .system("building.columns.fill")
        case .cyborg:
            return .system("cpu")
        }
    }
    
    /// One place to define brand tint per theme
    var tint: Color {
        switch self {
        case .ninja:  return .gray
        case .viking: return .orange
        case .knight: return .blue
        case .pirate: return .brown
        case .cyborg: return .green
        case .spartan: return .red
        }
    }

    /// Optional: background chip color / badge color
    var badgeFill: Color {
        tint.opacity(0.9)
    }
    
    var cardArtAsset: String {
        "icon-\(rawValue)"
    }
}

#Preview("AppTheme sample") {
    VStack(spacing: 12) {
        ForEach(AppTheme.allCases) { theme in
            HStack(spacing: 12) {
                ThemeIconView(icon: theme.toolbarIcon, tint: theme.tint, size: 18)

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.headline)
                    Text(theme.launchPadTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .fill(theme.badgeFill)
                    .frame(width: 16, height: 16)
            }
            .padding(8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
    .padding()
}
