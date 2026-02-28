//
//  GoalLaunchPad.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/17/26.
//

import SwiftUI

struct GoalLaunchPad: View {
    @Binding var goalMiles: Double
    var applyScheduleDefault: () -> Void
    @Binding var useScheduleDefault: Bool
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
                Text("Milage Goal")
                    .font(.headline)
                Spacer()
                Text("\(goalMiles, specifier: "%.2f") mi")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
            }

            // Preset grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
                ForEach(presets, id: \.0) { label, miles in
                    Button {
                        goalMiles = miles
                        markManualOverride()
                    } label: {
                        Text(label)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            // Fine tuning
            HStack(spacing: 10) {
                Button("− 0.25") {
                    goalMiles = max(0, goalMiles - 0.25)
                    markManualOverride()
                }
                .buttonStyle(.bordered)

                Button("+ 0.25") {
                    goalMiles += 0.25
                    markManualOverride()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Round") {
                    goalMiles = (goalMiles * 4).rounded() / 4 // nearest 0.25
                    markManualOverride()
                }
                .buttonStyle(.bordered)
            }

            Toggle("Schedule Defaults", isOn: $useScheduleDefault)
            
            Button("Apply Today’s Default") {
                applyScheduleDefault()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 6)
    }
}


#Preview("GoalLaunchPad Preview") {
    @Previewable @State var previewGoalMiles: Double = 3.10686
    @Previewable @State var previewUseScheduleDefault: Bool = false

    GoalLaunchPad(
        goalMiles: .init(get: { previewGoalMiles }, set: { previewGoalMiles = $0 }),
        applyScheduleDefault: {},
        useScheduleDefault: .init(get: { previewUseScheduleDefault }, set: { previewUseScheduleDefault = $0 }),
        markManualOverride: {}
    )
    .padding()
}

