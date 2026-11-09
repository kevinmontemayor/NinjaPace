//
//  WatchAnimatedThemeIconView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 8/23/26.
//

import SwiftUI

enum WatchThemeIconAnimation {
    case spin
    case pulse
}

struct WatchAnimatedThemeIconView: View {

    let theme: WatchTheme
    let tint: Color
    let size: CGFloat
    let isActive: Bool

    var body: some View {
        Group {
            if isActive {
                ActiveWatchThemeIconView(
                    theme: theme,
                    tint: tint,
                    size: size
                )
            } else {
                WatchThemeIconView(
                    icon: theme.icon,
                    tint: tint,
                    size: size
                )
            }
        }
    }
}

private struct ActiveWatchThemeIconView: View {

    let theme: WatchTheme
    let tint: Color
    let size: CGFloat

    @State private var rotation: Double = 0
    @State private var isPulsing = false

    var body: some View {
        Group {
            switch theme.iconAnimation {
            case .spin:
                spinningIcon
                
            case .pulse:
                pulsingIcon
            }
        }
        .onAppear {
            startAnimation()
        }
        .onChange(of: theme) { _, _ in
            startAnimation()
        }
    }

    private var spinningIcon: some View {
        WatchThemeIconView(
            icon: theme.icon,
            tint: tint,
            size: size
        )
        .rotationEffect(.degrees(rotation))
    }

    private var pulsingIcon: some View {
        WatchThemeIconView(
            icon: theme.icon,
            tint: tint,
            size: size
        )
        .scaleEffect(isPulsing ? 1.16 : 0.94)
        .opacity(isPulsing ? 1 : 0.72)
        .shadow(
            color: tint.opacity(isPulsing ? 0.90 : 0.20),
            radius: isPulsing ? 6 : 2
        )
    }

    private func startAnimation() {
        rotation = 0
        isPulsing = false

        switch theme.iconAnimation {
        case .spin:
            withAnimation(
                .linear(duration: theme.iconAnimationDuration)
                    .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }

        case .pulse:
            withAnimation(
                .easeInOut(duration: theme.iconAnimationDuration)
                    .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}

#Preview("🥷 Ninja — Active") {
    let theme: WatchTheme = .ninja

    WatchAnimatedThemeIconView(
        theme: theme,
        tint: theme.tint,
        size: 32,
        isActive: true
    )
    .padding()
}

#Preview("🪓 Viking — Active") {
    let theme: WatchTheme = .viking

    WatchAnimatedThemeIconView(
        theme: theme,
        tint: theme.tint,
        size: 32,
        isActive: true
    )
    .padding()
}

#Preview("⚔️ Knight — Active") {
    let theme: WatchTheme = .knight

    WatchAnimatedThemeIconView(
        theme: theme,
        tint: theme.tint,
        size: 32,
        isActive: true
    )
    .padding()
}

#Preview("🏴‍☠️ Pirate — Active") {
    let theme: WatchTheme = .pirate

    WatchAnimatedThemeIconView(
        theme: theme,
        tint: theme.tint,
        size: 32,
        isActive: true
    )
    .padding()
}

#Preview("🤖 Cyborg — Active") {
    let theme: WatchTheme = .cyborg

    WatchAnimatedThemeIconView(
        theme: theme,
        tint: theme.tint,
        size: 32,
        isActive: true
    )
    .padding()
}

#Preview("🛡 Spartan — Active") {
    let theme: WatchTheme = .spartan

    WatchAnimatedThemeIconView(
        theme: theme,
        tint: theme.tint,
        size: 32,
        isActive: true
    )
    .padding()
}
