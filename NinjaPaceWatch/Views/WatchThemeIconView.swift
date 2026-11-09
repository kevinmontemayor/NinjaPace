//
//  WatchThemeIconView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 8/23/26.
//

import SwiftUI

struct WatchThemeIconView: View {

    let icon: WatchThemeIcon
    let tint: Color
    let size: CGFloat

    var body: some View {
        Group {
            switch icon {
            case .system(let name):
                Image(systemName: name)
                    .resizable()
                    .symbolRenderingMode(.monochrome)

            case .asset(let name):
                Image(name)
                    .renderingMode(.template)
                    .resizable()
            }
        }
        .scaledToFit()
        .foregroundStyle(tint)
        .frame(width: size, height: size)
    }
}

#Preview("🥷 Ninja Icon") {
    WatchThemeIconView(icon: WatchTheme.ninja.icon, tint: WatchTheme.ninja.tint, size: 32)
        .padding()
}

#Preview("🪓 Viking Icon") {
    WatchThemeIconView(icon: WatchTheme.viking.icon, tint: WatchTheme.viking.tint, size: 32)
        .padding()
}

#Preview("⚔️ Knight Icon") {
    WatchThemeIconView(icon: WatchTheme.knight.icon, tint: WatchTheme.knight.tint, size: 32)
        .padding()
}

#Preview("🏴‍☠️ Pirate Icon") {
    WatchThemeIconView(icon: WatchTheme.pirate.icon, tint: WatchTheme.pirate.tint, size: 32)
        .padding()
}

#Preview("🤖 Cyborg Icon") {
    WatchThemeIconView(icon: WatchTheme.cyborg.icon, tint: WatchTheme.cyborg.tint, size: 32)
        .padding()
}

#Preview("🛡 Spartan Icon") {
    WatchThemeIconView(icon: WatchTheme.spartan.icon, tint: WatchTheme.spartan.tint, size: 32)
        .padding()
}
