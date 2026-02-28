//
//  GoalScheduleSettingsView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/18/26.
//

import SwiftUI

struct GoalScheduleSettingsView: View {
    @ObservedObject var store: GoalScheduleStore
    
    private struct Weekday: Identifiable {
        let id: Int   // 1 = Sunday ... 7 = Saturday
        let name: String
    }
    
    private let weekdays: [Weekday] = [
        Weekday(id: 2, name: "Monday"),
        Weekday(id: 3, name: "Tuesday"),
        Weekday(id: 4, name: "Wednesday"),
        Weekday(id: 5, name: "Thursday"),
        Weekday(id: 6, name: "Friday"),
        Weekday(id: 7, name: "Saturday"),
        Weekday(id: 1, name: "Sunday")
    ]
    
    var body: some View {
        Form {

            Section("Weekly Schedule") {
                ForEach(weekdays) { day in
                    HStack {
                        Text(day.name)
                        Spacer()

                        StepperMiles(
                            value: Binding(
                                get: { store.schedule.miles(for: day.id) },
                                set: { store.schedule.setMiles($0, for: day.id) }
                            ),
                            onStep: { step in
                                var stp = store.schedule
                                stp.bumpMiles(for: day.id, step: step)
                                store.schedule = stp
                            },
                            onPrevLock: {
                                var stp = store.schedule
                                stp.goToPreviousLock(for: day.id)
                                store.schedule = stp
                            },
                            onNextLock: {
                                var stp = store.schedule
                                stp.goToNextLock(for: day.id)
                                store.schedule = stp
                            },
                            onSnapNearest: {
                                var stp = store.schedule
                                stp.setNearestLock(for: day.id)
                                store.schedule = stp
                            }
                        )
                    }
                }
            }

            Section("Weekly Adjustments") {
                Button("+0.5 mi to Mon–Fri (snap to locks)") {
                    var sched = store.schedule
                    for day in [2,3,4,5,6] {
                        sched.bumpMiles(for: day, step: 0.5)
                    }
                    store.schedule = sched
                }

                Button("−0.5 mi to Mon–Fri (snap to locks)") {
                    var sched = store.schedule
                    for day in [2,3,4,5,6] {
                        sched.bumpMiles(for: day, step: -0.5)
                    }
                    store.schedule = sched
                }

                Button("Snap ALL days to nearest lock") {
                    var sched = store.schedule
                    for day in 1...7 {
                        sched.setNearestLock(for: day)
                    }
                    store.schedule = sched
                }
            }

            Section("Quick Templates") {
                Button("Mon–Fri 3.11 · Sat 9.0 · Sun 3.11") {
                    var schedule = store.schedule
                    for day in [2,3,4,5,6] { schedule.setMiles(3.11, for: day) }
                    schedule.setMiles(9.0, for: 7)
                    schedule.setMiles(3.11, for: 1)
                    store.schedule = schedule
                }

                Button("5K Daily") {
                    var schedule = store.schedule
                    for day in 1...7 { schedule.setMiles(3.10686, for: day) }
                    store.schedule = schedule
                }

                Button("10K Daily") {
                    var schedule = store.schedule
                    for day in 1...7 { schedule.setMiles(6.21371, for: day) }
                    store.schedule = schedule
                }

                Button("Half Marathon (Sat)") {
                    var schedule = store.schedule
                    schedule.setMiles(13.1094, for: 7)
                    store.schedule = schedule
                }

                Button("Full Marathon (Sat)") {
                    var schedule = store.schedule
                    schedule.setMiles(26.2188, for: 7)
                    store.schedule = schedule
                }
            }

            Section {
                Button(role: .destructive) {
                    store.schedule = .default
                } label: {
                    Text("Reset to Defaults")
                }
            }
        }
        .navigationTitle("Goal Schedule")
    }
}

/// Small reusable miles stepper widget
private struct StepperMiles: View {
    @Binding var value: Double

    var onStep: (Double) -> Void
    var onPrevLock: () -> Void
    var onNextLock: () -> Void
    var onSnapNearest: () -> Void

    private let step: Double = 0.5

    var body: some View {
        HStack(spacing: 6) {   // ✅ tighter
            Text("\(value, specifier: "%.2f") mi")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .trailing)

            CompactPillButton(systemName: "minus") { onStep(-step) }
            CompactPillButton(systemName: "plus")  { onStep(step) }

            Menu {
                Button("Previous lock") { onPrevLock() }
                Button("Next lock") { onNextLock() }
                Button("Snap to nearest lock") { onSnapNearest() }
            } label: {
                CompactPillIcon(systemName: "scope")
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct CompactPillButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct CompactPillIcon: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .frame(width: 32, height: 28)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview("Default") {
    let previewStore = GoalScheduleStore()
    return NavigationStack {
        GoalScheduleSettingsView(store: previewStore)
    }
}
