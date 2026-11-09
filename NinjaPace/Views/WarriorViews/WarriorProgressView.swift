//
//  WarriorProgressView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/24/26.
//

import SwiftUI

struct WarriorProgressView: View {
    
    let theme: AppTheme
    let completedGoals: Int
    let isWorkoutRunning: Bool
    
    @State private var auraPulse = false
    let levelOverride: WarriorProgressionLevel?
    
    private var level: WarriorProgressionLevel {
        levelOverride ??
            .level(
                for: completedGoals
            )
    }
    
    private var nextLevel: WarriorProgressionLevel? {
        level.nextLevel
    }
    
    private var goalsUntilNextLevel: Int {
        guard let nextLevel else {
            return 0
        }
        
        return max(
            0,
            nextLevel.requiredGoals -
            completedGoals
        )
    }
    
    private var levelProgress: Double {
        guard let nextLevel else {
            return 1
        }
        
        let currentRequirement =
        level.requiredGoals
        
        let range =
        nextLevel.requiredGoals -
        currentRequirement
        
        guard range > 0 else {
            return 1
        }
        
        let progress =
        completedGoals -
        currentRequirement
        
        return min(
            1,
            max(
                0,
                Double(progress) /
                Double(range)
            )
        )
    }
    
    init(
        theme: AppTheme,
        completedGoals: Int,
        isWorkoutRunning: Bool,
        levelOverride: WarriorProgressionLevel? = nil
    ) {
        self.theme = theme
        self.completedGoals = completedGoals
        self.isWorkoutRunning = isWorkoutRunning
        self.levelOverride = levelOverride
    }
    
    var body: some View {
        VStack(spacing: 8) {
            
            warrior
            
            VStack(spacing: 3) {
                Text(level.rankLabel)
                    .font(
                        .system(
                            .caption2,
                            design: .rounded
                        )
                        .weight(.bold)
                    )
                    .tracking(1.4)
                    .foregroundStyle(
                        theme.appSecondaryTextColor
                    )
                
                Text(
                    theme
                        .progressionTitle(
                            for: level
                        )
                        .uppercased()
                )
                .font(
                    .system(
                        .caption,
                        design: .rounded
                    )
                    .weight(.heavy)
                )
                .tracking(1.2)
                .foregroundStyle(
                    theme.appPrimaryTextColor
                )
                
                progressionText
            }
            
            ProgressView(
                value: levelProgress
            )
            .tint(
                theme.appAccentTextColor
            )
            .frame(
                maxWidth: 190
            )
        }
        .onAppear {
            updateAuraAnimation()
        }
        .onChange(
            of: isWorkoutRunning
        ) { _, _ in
            updateAuraAnimation()
        }
        .onChange(
            of: level
        ) { _, _ in
            updateAuraAnimation()
        }
    }
    
    @ViewBuilder
    private var warrior: some View {
        
        if let assetName =
            theme.warriorAsset(
                for: level
            ) {
            
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(
                    width: warriorSize,
                    height: warriorSize
                )
                .shadow(
                    color:
                        level
                            .auraPrimaryColor
                            .opacity(
                                isWorkoutRunning
                                    ? (
                                        auraPulse
                                            ? level.auraMaximumOpacity
                                            : level.auraMinimumOpacity
                                    )
                                    : level.auraMinimumOpacity
                            ),
                    radius:
                        isWorkoutRunning
                            ? (
                                auraPulse
                                    ? level.auraMaximumRadius
                                    : level.auraMinimumRadius
                            )
                            : level.auraMinimumRadius
                )
                .shadow(
                    color:
                        level
                            .auraSecondaryColor
                            .opacity(
                                isWorkoutRunning
                                    ? (
                                        auraPulse
                                            ? level.auraMaximumOpacity * 0.65
                                            : level.auraMinimumOpacity * 0.5
                                    )
                                    : level.auraMinimumOpacity * 0.25
                            ),
                    radius:
                        isWorkoutRunning
                            ? (
                                auraPulse
                                    ? level.auraMaximumRadius * 1.35
                                    : level.auraMinimumRadius
                            )
                            : level.auraMinimumRadius * 1.15
                )
                .shadow(
                    color:
                        level == .level4
                            ? Color.pink.opacity(
                                auraPulse ? 0.55 : 0.15
                            )
                            : .clear,
                    radius:
                        level == .level4
                            ? (
                                auraPulse ? 62 : 20
                            )
                            : 0
                )
        } else {
            
            Image(
                systemName:
                    theme
                    .progressionPlaceholderSymbol
            )
            .resizable()
            .scaledToFit()
            .foregroundStyle(
                theme.appPrimaryTextColor
            )
            .frame(
                width: 95,
                height: 95
            )
            .frame(
                width: 155,
                height: 155
            )
            .shadow(
                color:
                    theme
                    .appAccentTextColor
                    .opacity(0.25),
                radius: 12
            )
        }
    }
    
    @ViewBuilder
    private var progressionText: some View {
        
        if let nextLevel {
            
            Text(
                "\(completedGoals) goals completed • " +
                "\(goalsUntilNextLevel) more until " +
                theme.progressionTitle(
                    for: nextLevel
                )
            )
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(
                theme.appSecondaryTextColor
            )
            
        } else {
            
            Text(
                "\(completedGoals) GOALS COMPLETED • MAX LEVEL"
            )
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(
                theme.appAccentTextColor
            )
        }
    }
    
    private func updateAuraAnimation() {
        
        guard isWorkoutRunning else {
            withAnimation(
                .easeOut(duration: 0.25)
            ) {
                auraPulse = false
            }
            
            return
        }
        
        auraPulse = false
        
        withAnimation(
            .easeInOut(
                duration: level.auraPulseDuration
            )
            .repeatForever(
                autoreverses: true
            )
        ) {
            auraPulse = true
        }
    }
    
    private var baseWarriorSize: CGFloat {
        switch level {
        case .level1:
            return 155

        case .level2:
            return 175

        case .level3:
            return 190

        case .level4:
            return 280
        }
    }
    
    private var themeScale: CGFloat {
        switch theme {
        case .ninja:
            return 1.10

        case .viking:
            return 1.03

        case .knight:
            return 1.00

        case .pirate:
            return 1.04

        case .cyborg:
            return 1.05

        case .spartan:
            return 1.02
        }
    }
    
    private var levelSpecificScale: CGFloat {
        switch (theme, level) {
            
        case (.viking, .level2):
            return 1.08

        case (.viking, .level3):
            return 1.12

        case (.knight, .level3):
            return 1.10
            
        case (.spartan, .level3):
            return 1.12

        case (.cyborg, .level3):
            return 1.08

        default:
            return 1.00
        }
    }
    
    private var warriorSize: CGFloat {
        baseWarriorSize
            * themeScale
            * levelSpecificScale
    }
}


// MARK: - Previews
#if DEBUG

#Preview("Warrior Progression – All Levels") {
    ScrollView {
        VStack(spacing: 32) {
            previewLevel(
                .level1,
                title: "LEVEL I"
            )
            
            previewLevel(
                .level2,
                title: "LEVEL II"
            )
            
            previewLevel(
                .level3,
                title: "LEVEL III"
            )
            
            previewLevel(
                .level4,
                title: "LEVEL IV"
            )
        }
        .padding()
    }
    .background {
        WarriorBackgroundView()
    }
    .environmentObject(
        ThemeStore()
    )
}

@ViewBuilder
private func previewLevel(
    _ level: WarriorProgressionLevel,
    title: String
) -> some View {
    VStack(spacing: 10) {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
        
        WarriorProgressView(
            theme: .ninja,
            completedGoals:
                level.requiredGoals,
            isWorkoutRunning: false,
            levelOverride: level
        )
    }
}

#endif

#Preview("Warrior Progression – Active Aura") {

    VStack(spacing: 30) {

        WarriorProgressView(
            theme: .ninja,
            completedGoals: 25,
            isWorkoutRunning: true,
            levelOverride: .level3
        )

        WarriorProgressView(
            theme: .ninja,
            completedGoals: 50,
            isWorkoutRunning: true,
            levelOverride: .level4
        )
    }
    .padding()
    .background {
        WarriorBackgroundView()
    }
    .environmentObject(
        ThemeStore()
    )
}

#Preview("Spartan – All Levels") {

    ScrollView {

        VStack(spacing: 28) {

            ForEach(
                WarriorProgressionLevel.allCases,
                id: \.rawValue
            ) { level in

                WarriorProgressView(
                    theme: .spartan,
                    completedGoals:
                        level.requiredGoals,
                    isWorkoutRunning: false,
                    levelOverride: level
                )
            }
        }
        .padding()
    }
    .background {
        WarriorBackgroundView()
    }
    .environmentObject(
        ThemeStore()
    )
}

#Preview("Compare Warriors – Level III") {

    ScrollView {

        VStack(spacing: 24) {

            ForEach(
                AppTheme.allCases
            ) { theme in

                VStack(spacing: 6) {

                    Text(
                        theme.rawValue.uppercased()
                    )
                    .font(.caption)
                    .fontWeight(.bold)

                    WarriorProgressView(
                        theme: theme,
                        completedGoals:
                            WarriorProgressionLevel
                                .level3
                                .requiredGoals,
                        isWorkoutRunning: false,
                        levelOverride: .level3
                    )
                }
            }
        }
        .padding()
    }
}
