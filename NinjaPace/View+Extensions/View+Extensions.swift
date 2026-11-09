//
//  View+Extensions.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/08/26.
//

import SwiftUI

extension View {
    func themedWorkoutCard(theme: AppTheme) -> some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

        return self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.hudEditorRowBackground, in: shape)
            .overlay {
                shape
                    .stroke(theme.appPrimaryTextColor.opacity(0.16), lineWidth: 1)
            }
    }
}

#Preview("Themed Workout Card") {
    let theme = AppTheme.ninja

    ZStack {
        WarriorBackgroundView()

        VStack(alignment: .leading, spacing: 14) {
            Label("Workout Summary", systemImage: "chart.bar.fill")
                .font(.headline)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundStyle(theme.appSecondaryTextColor)

                    Text("26.22 mi")
                        .font(.system(.headline, design: .monospaced))
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundStyle(theme.appSecondaryTextColor)

                    Text("5:44:00")
                        .font(.system(.headline, design: .monospaced))
                        .fontWeight(.bold)
                }
            }
        }
        .foregroundStyle(theme.appPrimaryTextColor)
        .themedWorkoutCard(theme: theme)
        .padding()
    }
    .environmentObject(ThemeStore())
}
