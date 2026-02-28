//
//  ThemeWelcomeView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/27/26.
//

import SwiftUI

struct ThemeWelcomeView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Welcome to NinjaPace")
                    .font(.title2).bold()

                Text("Choose your warrior.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            // Theme chooser
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(AppTheme.allCases) { t in
                    ThemeCard(theme: t, isSelected: themeStore.theme == t)
                        .onTapGesture { themeStore.theme = t }
                }
            }

            NavigationLink {
                LaunchPadView()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 6)

            Spacer()
        }
        .padding()
    }
}

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            // Background Image
            Image(theme.cardArtAsset)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .clipped()
            
            // Subtle bottom gradient for text readability
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.75)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Title
            Text(theme.displayName)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(isSelected ? theme.tint : .clear, lineWidth: 3)
        )
        .shadow(radius: isSelected ? 8 : 2)
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
}

#Preview("Theme Welcome - Dark") {
    ThemeWelcomeView()
        .environmentObject(ThemeStore())
}

#Preview("Theme Welcome - Light") {
    ThemeWelcomeView()
        .environmentObject(ThemeStore())
}
