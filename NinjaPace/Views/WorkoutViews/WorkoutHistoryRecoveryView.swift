//
//  WorkoutHistoryRecoveryView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 10/18/26.
//

import SwiftData
import SwiftUI

struct WorkoutHistoryRecoveryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var recovery = WorkoutHistoryRecovery()
    @State private var candidates: [RecoveryWorkout] = []
    @State private var isBusy = false
    @State private var message: String?
    @State private var didSearch = false
    @State private var didImport = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Recover running workouts recorded by NinjaPace from Apple Health. Your Health records will not be changed.")
                    Text("Original mileage goals, splits, heart-rate zones, and achievement unlocks cannot be restored. Recovered workouts show a goal of 0 (unknown). If Health has no distance or step count, those values also show 0; other missing measurements remain unavailable.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if !didImport {
                        Button(didSearch ? "Search Again" : "Find NinjaPace Workouts") {
                            Task { await search() }
                        }
                        .disabled(isBusy)
                    }
                    if isBusy { ProgressView() }
                    if let message { Text(message) }
                }
                if !candidates.isEmpty && !didImport {
                    Section("Workouts to Recover (\(candidates.count))") {
                        ForEach(candidates, id: \.uuid) { workout in
                            VStack(alignment: .leading) {
                                Text(workout.startDate, format: .dateTime.month().day().year().hour().minute())
                                Text("\(workout.distanceMiles ?? 0, specifier: "%.2f") mi")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Button("Recover \(candidates.count) Workouts") { recover() }
                            .disabled(isBusy)
                    }
                }
            }
            .navigationTitle("Recover History")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func search() async {
        isBusy = true
        message = nil
        defer { isBusy = false }
        do {
            let workouts = try await recovery.findWorkouts()
            let existing = try modelContext.fetch(FetchDescriptor<WorkoutRecord>())
            candidates = workouts.filter { !WorkoutHistoryRecovery.alreadyExists($0, in: existing) }
            didSearch = true
            message = candidates.isEmpty
                ? "No additional NinjaPace workouts are available to read. If you expected workouts, check NinjaPace’s Health read permissions."
                : "Review the workouts below, then tap Recover to add them to NinjaPace."
        } catch {
            candidates = []
            message = "Could not read workouts: \(error.localizedDescription)"
        }
    }

    private func recover() {
        do {
            let count = try WorkoutHistoryRecovery.importWorkouts(candidates, into: modelContext.container)
            message = "Recovered \(count) workouts. Existing records were preserved."
            didImport = true
        } catch {
            message = "Recovery could not be saved: \(error.localizedDescription)"
        }
    }
}

#if DEBUG

@MainActor
private struct WorkoutHistoryRecoveryPreviewHost: View {
    private let container: ModelContainer

    init() {
        do {
            let configuration = ModelConfiguration(
                isStoredInMemoryOnly: true
            )
            
            container = try ModelContainer(for: WorkoutRecord.self, configurations: configuration)
        } catch {
            fatalError(
                "WorkoutHistoryRecovery preview failed: \(error)"
            )
        }
    }

    var body: some View {
        WorkoutHistoryRecoveryView()
            .modelContainer(container)
    }
}

#Preview("Recover History – Ready") {
    WorkoutHistoryRecoveryPreviewHost()
}

#endif
