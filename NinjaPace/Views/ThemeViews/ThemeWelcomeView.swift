//
//  ThemeWelcomeView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/27/26.
//

import SwiftUI

struct ThemeWelcomeView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @EnvironmentObject private var health: HealthStreamManager
    @Environment(\.dismiss) private var dismiss

    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                WarriorBackgroundView()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("Welcome to NinjaPace")
                                .font(.title2.bold())
                                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                                .accessibilityIdentifier("welcomeTitle")

                            Text("Choose your warrior.")
                                .font(.subheadline)
                                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12),
                                                count: geometry.size.width >= 600 ? 3 : 2), spacing: 12) {
                            ForEach(AppTheme.allCases) { theme in
                                Button {
                                    selectTheme(theme)
                                } label: {
                                    ThemeCard(theme: theme, isSelected: themeStore.theme == theme)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("warrior_\(theme.rawValue)")
                                .accessibilityValue(themeStore.theme == theme ? "Selected" : "Not Selected")
                                .accessibilityLabel(theme.displayName)
                            }
                        }
                        
                        Button {
                            onContinue()
                        } label: {
                            Label("Begin Training", systemImage: "figure.martial.arts")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 6)
                        .accessibilityIdentifier("beginTrainingButton")

                        NavigationLink {
                            HUDCustomizationView(configuration: $health.hudConfiguration)
                        } label: {
                            Label("Customize HUD", systemImage: "paintpalette")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 6)
                        .accessibilityIdentifier("welcomeCustomizeHUDButton")
                    }
                    .padding()
                    .frame(maxWidth: 720)
                    .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("welcomeScrollView")
            }
        }
        .tint(themeStore.theme.tint)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .accessibilityIdentifier("welcomeBackButton")
            }
        }
    }

    private func selectTheme(_ theme: AppTheme) {
        themeStore.theme = theme
        health.hudConfiguration = theme.hudPreset
        health.themeKey = theme.rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        health.saveHUDConfiguration()
        health.syncCurrentSettingsToWatch()
    }
}

#Preview("Theme Welcome - Dark") {
    NavigationStack {
        ThemeWelcomeView {
            print("Begin Training tapped")
        }
        .environmentObject(ThemeStore())
        .environmentObject(HealthStreamManager())
    }
    .preferredColorScheme(.dark)
}

#Preview("Theme Welcome - Light") {
    NavigationStack {
        ThemeWelcomeView {
            print("Begin Training tapped")
        }
        .environmentObject(ThemeStore())
        .environmentObject(HealthStreamManager())
    }
    .preferredColorScheme(.light)
}
