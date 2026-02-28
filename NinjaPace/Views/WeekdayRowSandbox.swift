//
//  WeekdayRowSandbox.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/28/26.
//

import SwiftUI

private struct WeekdayRowSandbox: View {
    @State private var schedule: GoalSchedule = .default
    let weekday: Int
    let name: String

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)

                Text("\(schedule.miles(for: weekday), specifier: "%.2f") mi")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()
            
            IncrementButton(kind: .minus, tint: .gray) {
                schedule.smartBumpMiles(for: weekday, direction: -1)
            }

            IncrementButton(kind: .plus, tint: .blue) {
                schedule.smartBumpMiles(for: weekday, direction: 1)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview("Increment Controls — Default") {
    NavigationStack {
        Form {
            Section("Sandbox") {
                WeekdayRowSandbox(weekday: 2, name: "Monday")
                WeekdayRowSandbox(weekday: 7, name: "Saturday")
            }
        }
        .navigationTitle("Goal Buttons")
    }
}

#Preview("Increment Controls — Large Type") {
    NavigationStack {
        Form {
            Section("Sandbox") {
                WeekdayRowSandbox(weekday: 2, name: "Monday")
                WeekdayRowSandbox(weekday: 7, name: "Saturday")
            }
        }
        .navigationTitle("Goal Buttons")
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
