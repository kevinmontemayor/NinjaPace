//
//  GoalLaunchPadView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/17/26.
//

import SwiftUI

struct GoalLaunchPadView: View {
    @EnvironmentObject private var themeStore: ThemeStore

    @Binding var goalMiles: Double
    @Binding var useScheduleDefault: Bool

    var applyScheduleDefault: () -> Void
    var markManualOverride: () -> Void

    private let presets: [(String, Double)] = [
        ("1 mile", 1.0),
        ("2 mile", 2.0),
        ("5K", 3.10686),
        ("10K", 6.21371),
        ("Half", 13.1094),
        ("Full", 26.2188),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Mileage Goal")
                    .font(.headline)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)

                Spacer()

                Text("\(goalMiles, specifier: "%.2f") mi")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .accessibilityIdentifier("goalMilesValue")
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
                ForEach(presets, id: \.0) { label, miles in
                    Button {
                        goalMiles = miles
                        markManualOverride()
                    } label: {
                        Text(label)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(
                        TrainingControlButtonStyle(
                            backgroundColor: themeStore.theme.hudEditorRowBackground,
                            foregroundColor: themeStore.theme.appPrimaryTextColor
                        )
                    )
                    .accessibilityIdentifier("goalPreset_\(label)")
                }
            }

            HStack(spacing: 10) {
                Button("− 0.25") {
                    goalMiles = max(0, goalMiles - 0.25)
                    markManualOverride()
                }
                .buttonStyle(
                    TrainingControlButtonStyle(
                        backgroundColor: themeStore.theme.hudEditorRowBackground,
                        foregroundColor: themeStore.theme.appPrimaryTextColor
                    )
                )
                .accessibilityIdentifier("goalMinusQuarterButton")

                Button("+ 0.25") {
                    goalMiles += 0.25
                    markManualOverride()
                }
                .buttonStyle(
                    TrainingControlButtonStyle(
                        backgroundColor: themeStore.theme.hudEditorRowBackground,
                        foregroundColor: themeStore.theme.appPrimaryTextColor
                    )
                )
                .accessibilityIdentifier("goalPlusQuarterButton")

                Spacer()

                Button("Round") {
                    goalMiles = (goalMiles * 4).rounded() / 4
                    markManualOverride()
                }
                .buttonStyle(
                    TrainingControlButtonStyle(
                        backgroundColor: themeStore.theme.hudEditorRowBackground,
                        foregroundColor: themeStore.theme.appPrimaryTextColor
                    )
                )
                .accessibilityIdentifier("goalRoundButton")
            }

            Toggle("Use Schedule Defaults", isOn: $useScheduleDefault)
                .toggleStyle(ThemedToggleStyle(theme: themeStore.theme))
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                .fontWeight(.semibold)
                .accessibilityIdentifier("useScheduleDefaultsToggle")

            Button("Apply Today’s Default Goal") {
                applyScheduleDefault()
            }
            .buttonStyle(
                TrainingControlButtonStyle(
                    backgroundColor: themeStore.theme.hudEditorRowBackground,
                    foregroundColor: themeStore.theme.appPrimaryTextColor
                )
            )
            .accessibilityIdentifier("applyTodayDefaultGoalButton")
        }
        .padding(.vertical, 6)
    }
}

#Preview("GoalLaunchPad Preview") {
    @Previewable @State var previewGoalMiles: Double = 3.10686
    @Previewable @State var previewUseScheduleDefault = false

    GoalLaunchPadView(
        goalMiles: .init(get: { previewGoalMiles }, set: { previewGoalMiles = $0 }),
        useScheduleDefault: .init(get: { previewUseScheduleDefault }, set: { previewUseScheduleDefault = $0 }),
        applyScheduleDefault: {},
        markManualOverride: {}
    )
    .environmentObject(ThemeStore())
    .padding()
}
