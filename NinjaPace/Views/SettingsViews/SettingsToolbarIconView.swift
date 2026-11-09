//
//  SettingsToolbarIconView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/9/26.
//

import SwiftUI

struct SettingsToolbarIconView: View {

    @EnvironmentObject private var themeStore: ThemeStore
    @ObservedObject var pushClient: StatsPushClient

    @State private var rotation: Double = 0
    @State private var isPulsing = false

    private var hasMacRelay: Bool {
        !pushClient.macBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isActive: Bool {
        pushClient.enabled && hasMacRelay
    }

    var body: some View {
        ZStack {
            if themeStore.theme == .ninja && hasMacRelay {
                Circle()
                    .fill(themeStore.theme.appPrimaryTextColor)
            }

            if hasMacRelay {
                animatedThemeIcon
            } else {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
            }
        }
        .frame(width: 34, height: 34)
        .contentShape(Circle())
        .onAppear {
            updateAnimation()
        }
        .onChange(of: pushClient.enabled) { _, _ in
            updateAnimation()
        }
        .onChange(of: themeStore.theme) { _, _ in
            updateAnimation()
        }
        .onChange(of: hasMacRelay) { _, _ in
            updateAnimation()
        }
    }

    // MARK: - Animated Warrior Icon

    private var themeIcon: some View {
        ThemeIconView(
            icon: themeStore.theme.toolbarIcon,
            tint: themeStore.theme.appPrimaryTextColor,
            size: 16
        )
    }

    @ViewBuilder
    private var animatedThemeIcon: some View {
        switch themeStore.theme.toolbarAnimation {
        case .spin:
            themeIcon
                .rotationEffect(.degrees(isActive ? rotation : 0))

        case .pulse:
            themeIcon
                .scaleEffect(isActive ? (isPulsing ? 1.16 : 0.94) : 1)
                .opacity(isActive ? (isPulsing ? 1 : 0.72) : 1)
                .shadow(
                    color: isActive
                        ? themeStore.theme.appPrimaryTextColor.opacity(isPulsing ? 0.85 : 0.20)
                        : .clear,
                    radius: isPulsing ? 7 : 2
                )
        }
    }

    // MARK: - Animation

    private func updateAnimation() {
        guard isActive else {
            withAnimation(.easeOut(duration: 0.25)) {
                rotation = 0
                isPulsing = false
            }
            return
        }

        let duration = themeStore.theme.toolbarAnimationDuration

        switch themeStore.theme.toolbarAnimation {
        case .spin:
            isPulsing = false
            rotation = 0

            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                rotation = 360
            }

        case .pulse:
            rotation = 0
            isPulsing = false

            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#if DEBUG

extension StatsPushClient {
    static func preview(
        macBaseURL: String = "",
        enabled: Bool = false,
        status: Status = .idle
    ) -> StatsPushClient {
        let client = StatsPushClient(defaultBaseURL: macBaseURL)
        client.macBaseURL = macBaseURL
        client.enabled = enabled
        client.status = status
        return client
    }
}

#Preview("Configured") {
    SettingsToolbarIconView(
        pushClient: .preview(macBaseURL: "123.456.7.890:8787")
    )
    .environmentObject(ThemeStore())
    .padding()
}

#Preview("Not Configured") {
    SettingsToolbarIconView(pushClient: .preview())
        .environmentObject(ThemeStore())
        .padding()
}

#Preview("Relay Pushing") {
    SettingsToolbarIconView(
        pushClient: .preview(
            macBaseURL: "123.456.7.890:8787",
            enabled: true,
            status: .pushing
        )
    )
    .environmentObject(ThemeStore())
    .padding()
}

#endif
