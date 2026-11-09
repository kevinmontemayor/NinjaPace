//
//  WarriorBackgroundView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/9/26.
//

import SwiftUI

struct WarriorBackgroundView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(
                    themeStore.theme.homeBackgroundAsset
                )
                .resizable()
                .scaledToFill()
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .clipped()

                LinearGradient(
                    colors: [
                        .black.opacity(0.18),
                        .black.opacity(0.32),
                        .black.opacity(0.48)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
        }
        .ignoresSafeArea()
        .animation(
            .easeInOut(duration: 0.35),
            value: themeStore.theme
        )
    }
}

#Preview {
    WarriorBackgroundView()
        .environmentObject(ThemeStore())
}
