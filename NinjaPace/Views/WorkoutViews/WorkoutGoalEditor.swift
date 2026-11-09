//
//  WorkoutGoalEditor.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 10/18/26.
//

import Foundation
import SwiftData
import SwiftUI

struct WorkoutGoalEditor: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let workout: WorkoutRecord

    @State private var goalText = ""
    @State private var saveError: String?

    private var goal: Double? {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        formatter.isLenient = false
        guard let value = formatter.number(from: goalText.trimmingCharacters(in: .whitespacesAndNewlines))?.doubleValue,
              value.isFinite, value > 0 else { return nil }
        return value
    }

    /// Historical workout mileage is displayed to two decimal places
    /// throughout NinjaPace, so goal completion uses the same precision.
    private var proposedGoalWasCompleted: Bool {
        guard let goal else { return false }
        
        return WorkoutRecord.goalWasCompleted(completedMiles: workout.completedMiles, goalMiles: goal)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Original Mileage Goal") {
                    TextField("Goal in miles", text: $goalText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("historicalGoalMiles")

                    Text("Distance completed: " + workout.completedMiles.formatted(.number.precision(.fractionLength(2))) + " mi")

                    if goal != nil {
                        Label(proposedGoalWasCompleted ? "Goal completed" : "Goal not completed", systemImage: proposedGoalWasCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(proposedGoalWasCompleted ? Color.green : Color.secondary)
                    }
                }

                Section {
                    Text("Enter the target you set for this workout. " + "Saving updates goal totals, awards, and warrior progress " + "in NinjaPace. Apple Health stays unchanged.")
                    
                    if let saveError {
                        Text(saveError)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Workout Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(goal == nil)
                }
            }
            .onAppear {
                if workout.goalMiles > 0 {
                    goalText = workout.goalMiles.formatted(.number
                            .grouping(.never)
                            .precision(.fractionLength(0...6))
                    )
                }
            }
        }
    }

    private func save() {
        guard let goal else { return }

        let previous = (
            workout.goalMiles,
            workout.wasGoalCompleted,
            workout.goalCompletionPercentage,
            workout.milesOverGoal
        )

        guard workout.updateGoalMiles(goal) else { return }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            workout.goalMiles = previous.0
            workout.wasGoalCompleted = previous.1
            workout.goalCompletionPercentage = previous.2
            workout.milesOverGoal = previous.3
            saveError = "Could not save the goal. Please try again."
        }
    }
}

#if DEBUG

@MainActor
private struct WorkoutGoalEditorPreviewHost: View {
    private let container: ModelContainer
    private let workout: WorkoutRecord

    init() {
        do {
            let configuration = ModelConfiguration(
                isStoredInMemoryOnly: true
            )

            container = try ModelContainer(
                for: WorkoutRecord.self,
                configurations: configuration
            )

            let endedAt = Date()
            let duration: TimeInterval = 82 * 60

            workout = WorkoutRecord(
                startedAt: endedAt.addingTimeInterval(-duration),
                endedAt: endedAt,
                goalMiles: 6.26,
                completedMiles: 6.259999999,
                steps: 11_842,
                averageHeartRate: 146,
                peakHeartRate: 171,
                activeCalories: 712,
                totalCalories: 801,
                averageCadenceSPM: 165,
                elevationGainFeet: 0,
                duration: duration,
                pausedDuration: 0,
                averagePaceSecondsPerMile: duration / 6.26,
                averageSpeedMPH: 4.58,
                peakSpeedMPH: 7.2,
                workoutTypeRawValue: "running",
                workoutLocationRawValue: "indoor",
                source: "Apple Watch"
            )

            container.mainContext.insert(workout)
        } catch {
            fatalError(
                "WorkoutGoalEditor preview failed: \(error)"
            )
        }
    }

    var body: some View {
        WorkoutGoalEditor(workout: workout)
            .modelContainer(container)
    }
}

#Preview("Goal Editor – Rounded 6.26 / 6.26") {
    WorkoutGoalEditorPreviewHost()
}

#endif
