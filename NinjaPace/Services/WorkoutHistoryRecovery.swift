import Foundation
import HealthKit
import SwiftData

/// Values needed for recovery, independent of HealthKit storage and permissions.
struct RecoveryWorkout {
    var uuid: UUID = UUID()
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval
    var distanceMiles: Double?
    var steps: Int = 0
    var averageHeartRate: Double?
    var peakHeartRate: Double?
    var activeCalories: Double?
    var isIndoor: Bool?
}

extension RecoveryWorkout {
    init(healthKitWorkout workout: HKWorkout) {
        let heartRate = workout.statistics(for: HKQuantityType(.heartRate))
        let bpm = HKUnit.count().unitDivided(by: .minute())
        self.init(
            uuid: workout.uuid,
            startDate: workout.startDate,
            endDate: workout.endDate,
            duration: workout.duration,
            distanceMiles: workout.totalDistance?.doubleValue(for: .mile()),
            steps: Int(workout.statistics(for: HKQuantityType(.stepCount))?
                .sumQuantity()?.doubleValue(for: .count()) ?? 0),
            averageHeartRate: heartRate?.averageQuantity()?.doubleValue(for: bpm),
            peakHeartRate: heartRate?.maximumQuantity()?.doubleValue(for: bpm),
            activeCalories: workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
                .sumQuantity()?.doubleValue(for: .kilocalorie()),
            isIndoor: workout.metadata?[HKMetadataKeyIndoorWorkout] as? Bool
        )
    }
}

/// Reads HealthKit without writing to or deleting from the Health store.
@MainActor
final class WorkoutHistoryRecovery {
    private let store = HKHealthStore()

    func findWorkouts() async throws -> [RecoveryWorkout] {
        let types: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKQuantityType(.distanceWalkingRunning), HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate), HKQuantityType(.stepCount)
        ]
        try await store.requestAuthorization(toShare: [], read: types)
        let workouts: [HKWorkout] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: HKQuery.predicateForWorkouts(with: .running),
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: samples as? [HKWorkout] ?? []) }
            }
            store.execute(query)
        }
        return workouts.filter {
            ["com.github.kevinmontemayor.NinjaPace",
             "com.github.kevinmontemayor.NinjaPace.watchkitapp"]
                .contains($0.sourceRevision.source.bundleIdentifier)
        }.map { RecoveryWorkout(healthKitWorkout: $0) }
    }

    static func alreadyExists(_ workout: RecoveryWorkout, in records: [WorkoutRecord]) -> Bool {
        records.contains {
            $0.id == workout.uuid ||
            (abs($0.startedAt.timeIntervalSince(workout.startDate)) < 5 &&
             abs($0.endedAt.timeIntervalSince(workout.endDate)) < 5)
        }
    }

    static func makeRecord(from workout: RecoveryWorkout) -> WorkoutRecord {
        let miles = workout.distanceMiles ?? 0
        // Goal zero means unknown; never infer a historical goal from today's setting.
        let record = WorkoutRecord(
            id: workout.uuid, startedAt: workout.startDate, endedAt: workout.endDate,
            goalMiles: 0, completedMiles: miles, steps: workout.steps,
            averageHeartRate: workout.averageHeartRate,
            peakHeartRate: workout.peakHeartRate,
            activeCalories: workout.activeCalories,
            duration: workout.endDate.timeIntervalSince(workout.startDate),
            pausedDuration: max(0, workout.endDate.timeIntervalSince(workout.startDate) - workout.duration),
            averagePaceSecondsPerMile: miles > 0 ? workout.duration / miles : nil,
            workoutLocationRawValue: workout.isIndoor.map { $0 ? "indoor" : "outdoor" },
            source: "NinjaPace · Recovered from Apple Health"
        )
        record.milesOverGoal = 0
        return record
    }

    static func importWorkouts(_ workouts: [RecoveryWorkout], into container: ModelContainer) throws -> Int {
        // A separate context makes a failed save rollback independent of active app work.
        let context = ModelContext(container)
        context.autosaveEnabled = false
        var existing = try context.fetch(FetchDescriptor<WorkoutRecord>())
        var count = 0
        for workout in workouts where !alreadyExists(workout, in: existing) {
            let record = makeRecord(from: workout)
            context.insert(record)
            existing.append(record)
            count += 1
        }
        do { try context.save() }
        catch { context.rollback(); throw error }
        return count
    }
}
