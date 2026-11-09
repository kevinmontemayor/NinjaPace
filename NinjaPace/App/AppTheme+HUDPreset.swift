//
//  AppTheme+HUDPreset.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/24/26.
//

import SwiftUI

extension AppTheme {

    var hudPreset: HUDConfiguration {
        switch self {
        case .ninja:
            return makeHUDPreset(
                title: "🥷 NINJAPACE HUD 🥷",
                subtitle: "Silent speed. Relentless focus.",
                liveColor: "#FF0050",
                pausedColor: "#FFD60A",
                idleColor: "#8E8E93",
                goalColor: "#30D158",
                backgroundColor: "#101014",
                backgroundOpacity: 0.72,
                glowIntensity: 0.85,
                textScale: 1.12,
                textWeight: 900,
                textOutline: 0.85
            )

        case .viking:
            return makeHUDPreset(
                title: "🪓 VIKINGPACE HUD 🪓",
                subtitle: "Run hard. Conquer miles.",
                liveColor: "#FF7A00",
                pausedColor: "#FFD60A",
                idleColor: "#8B7355",
                goalColor: "#49E670",
                backgroundColor: "#211006",
                backgroundOpacity: 0.78,
                glowIntensity: 0.95,
                textScale: 1.10,
                textWeight: 900,
                textOutline: 0.9
            )

        case .knight:
            return makeHUDPreset(
                title: "🛡️ KNIGHTPACE HUD ⚔️",
                subtitle: "Honor the run.",
                liveColor: "#5AAAFF",
                pausedColor: "#FFD60A",
                idleColor: "#8792A2",
                goalColor: "#4CD964",
                backgroundColor: "#0B1320",
                backgroundOpacity: 0.78,
                glowIntensity: 0.88,
                textScale: 1.08,
                textWeight: 850,
                textOutline: 0.8
            )

        case .pirate:
            return makeHUDPreset(
                title: "🏴‍☠️ PIRATEPACE HUD 🏴‍☠️",
                subtitle: "Chasing treasure one mile at a time.",
                liveColor: "#E8C07D",
                pausedColor: "#FFD447",
                idleColor: "#7F766B",
                goalColor: "#2EE6A6",
                backgroundColor: "#17120D",
                backgroundOpacity: 0.78,
                glowIntensity: 0.82,
                textScale: 1.10,
                textWeight: 900,
                textOutline: 0.9
            )

        case .cyborg:
            return makeHUDPreset(
                title: "🤖 CYBORGPACE HUD 🤖",
                subtitle: "System online. Limits removed.",
                liveColor: "#00FFAA",
                pausedColor: "#FFF200",
                idleColor: "#607D75",
                goalColor: "#00FF66",
                backgroundColor: "#03130F",
                backgroundOpacity: 0.82,
                glowIntensity: 1,
                textScale: 1.08,
                textWeight: 850,
                textOutline: 0.8
            )

        case .spartan:
            return makeHUDPreset(
                title: "🏛️ SPARTANPACE HUD 🏛️",
                subtitle: "Discipline. Endurance. Victory.",
                liveColor: "#FFD700",
                pausedColor: "#FF9F0A",
                idleColor: "#8A8066",
                goalColor: "#32D74B",
                backgroundColor: "#1A1404",
                backgroundOpacity: 0.8,
                glowIntensity: 0.92,
                textScale: 1.08,
                textWeight: 850,
                textOutline: 0.8
            )
        }
    }

    private func makeHUDPreset(
        title: String,
        subtitle: String,
        liveColor: String,
        pausedColor: String,
        idleColor: String,
        goalColor: String,
        backgroundColor: String,
        backgroundOpacity: Double,
        glowIntensity: Double,
        textScale: Double,
        textWeight: Int,
        textOutline: Double
    ) -> HUDConfiguration {
        HUDConfiguration(
            title: title,
            subtitle: subtitle,
            themeKey: rawValue,
            liveColor: liveColor,
            pausedColor: pausedColor,
            idleColor: idleColor,
            goalColor: goalColor,
            backgroundColor: backgroundColor,
            backgroundOpacity: backgroundOpacity,
            borderEnabled: true,
            borderWidth: 2,
            glowIntensity: glowIntensity,
            scale: 1,
            showMiles: true,
            showSteps: true,
            showHeartRate: true,
            showCalories: true,
            showElapsed: true,
            showPace: true,
            showGoal: true,
            textScale: textScale,
            textWeight: textWeight,
            textOutline: textOutline,
            liveBackgroundColor: "#101014",
            liveBackgroundOpacity: 0,
            pausedBackgroundColor: "#101014",
            pausedBackgroundOpacity: 0.78,
            idleBackgroundColor: "#101014",
            idleBackgroundOpacity: 0.55,
            goalBackgroundColor: "#101014",
            goalBackgroundOpacity: 0.88
        )
    }

    var hudEditorRowBackground: Color {
        switch self {
        case .ninja: return .black.opacity(0.5)
        case .viking: return .orange.opacity(0.6)
        case .knight: return .blue.opacity(0.4)
        case .pirate: return .brown.opacity(0.6)
        case .cyborg: return .green.opacity(0.4)
        case .spartan: return Color(red: 0.28, green: 0.10, blue: 0.07).opacity(0.72)
        }
    }

    var hudEditorSectionIcon: String {
        switch self {
        case .ninja: return "🥷"
        case .viking: return "🪓"
        case .knight: return "🛡️"
        case .pirate: return "🏴‍☠️"
        case .cyborg: return "🤖"
        case .spartan: return "🏛️"
        }
    }

    var appPrimaryTextColor: Color {
        switch self {
        case .ninja: return Color(red: 0.85, green: 0.05, blue: 0.08)
        case .viking, .knight, .pirate, .cyborg: return .white
        case .spartan: return Color(red: 0.98, green: 0.95, blue: 0.86)
        }
    }

    var appSecondaryTextColor: Color {
        switch self {
        case .ninja: return Color(red: 0.72, green: 0.08, blue: 0.10).opacity(0.88)
        case .viking: return .white.opacity(0.76)
        case .knight, .pirate: return .white.opacity(0.74)
        case .cyborg: return .white.opacity(0.72)
        case .spartan: return Color(red: 0.88, green: 0.82, blue: 0.68).opacity(0.88)
        }
    }

    var appAccentTextColor: Color {
        switch self {
        case .ninja: return Color(red: 0.95, green: 0.03, blue: 0.06)
        case .viking, .knight: return .white
        case .pirate: return .yellow.opacity(0.95)
        case .cyborg: return .mint
        case .spartan: return Color(red: 0.95, green: 0.76, blue: 0.22)
        }
    }
}

#if DEBUG

private struct AppThemeHUDPresetPreview: View {
    let theme: AppTheme

    private var configuration: HUDConfiguration {
        theme.hudPreset
    }

    private var previewThemeStore: ThemeStore {
        let store = ThemeStore()
        store.theme = theme
        return store
    }

    var body: some View {
        ZStack {
            WarriorBackgroundView()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    presetCard
                    colorCard
                }
                .padding()
                .padding(.top, 40)
            }
        }
        .environmentObject(previewThemeStore)
        .tint(theme.tint)
    }

    private var headerCard: some View {
        VStack(spacing: 8) {
            Text(theme.hudEditorSectionIcon)
                .font(.system(size: 44))

            Text(theme.displayName)
                .font(.title2.bold())

            Text(configuration.subtitle ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(theme.hudEditorRowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var presetCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(configuration.title)
                .font(.system(.headline, design: .monospaced))

            Divider()

            presetRow(title: "Theme Key", value: configuration.themeKey)
            presetRow(
                title: "Background Opacity",
                value: "\(Int((configuration.backgroundOpacity * 100).rounded()))%"
            )
            presetRow(
                title: "Glow",
                value: "\(Int((configuration.glowIntensity * 100).rounded()))%"
            )
            presetRow(title: "Text Scale", value: String(format: "%.2fx", configuration.textScale))
            presetRow(title: "Text Weight", value: "\(configuration.textWeight)")
            presetRow(
                title: "Text Outline",
                value: "\(Int((configuration.textOutline * 100).rounded()))%"
            )
            presetRow(title: "HUD Scale", value: String(format: "%.2fx", configuration.scale))
        }
        .padding()
        .background(theme.hudEditorRowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var colorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HUD Colors")
                .font(.headline)

            colorRow(title: "Live", hex: configuration.liveColor)
            colorRow(title: "Paused", hex: configuration.pausedColor)
            colorRow(title: "Idle", hex: configuration.idleColor)
            colorRow(title: "Goal", hex: configuration.goalColor)
            colorRow(title: "Background", hex: configuration.backgroundColor)
        }
        .padding()
        .background(theme.hudEditorRowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func presetRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
        }
    }

    private func colorRow(title: String, hex: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 22, height: 22)

            Text(title)

            Spacer()

            Text(hex.uppercased())
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Ninja HUD Preset") { AppThemeHUDPresetPreview(theme: .ninja) }
#Preview("Viking HUD Preset") { AppThemeHUDPresetPreview(theme: .viking) }
#Preview("Knight HUD Preset") { AppThemeHUDPresetPreview(theme: .knight) }
#Preview("Pirate HUD Preset") { AppThemeHUDPresetPreview(theme: .pirate) }
#Preview("Cyborg HUD Preset") { AppThemeHUDPresetPreview(theme: .cyborg) }
#Preview("Spartan HUD Preset") { AppThemeHUDPresetPreview(theme: .spartan) }

#endif
