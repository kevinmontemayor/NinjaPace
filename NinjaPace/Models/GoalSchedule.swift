//
//  GoalSchedule.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/18/26.
//

import Combine
import Foundation
import SwiftUI

struct GoalSchedule: Codable, Equatable, UsesScheduleDefaults {
    // 1 = Sunday ... 7 = Saturday (Calendar weekday)
    var milesByWeekday: [Int: Double]
    var useScheduleDefaults: Bool

    static let `default` = GoalSchedule(
        milesByWeekday: [
            1: 3.10686,  // Sun
            2: 3.10686, // Mon
            3: 3.10686, // Tue
            4: 3.10686, // Wed
            5: 3.10686, // Thu
            6: 3.10686, // Fri
            7: 13.1094 // Sat
        ],
        useScheduleDefaults: false
    )

    func miles(for weekday: Int) -> Double {
        milesByWeekday[weekday] ?? 3.10686
    }

    mutating func setMiles(_ miles: Double, for weekday: Int) {
        milesByWeekday[weekday] = miles
    }
}

/// Small helper to store Codable values in UserDefaults.
@propertyWrapper
struct CodableAppStorage<Value: Codable> {
    let key: String
    let defaultValue: Value
    var storage: UserDefaults = .standard

    var wrappedValue: Value {
        get {
            guard let data = storage.data(forKey: key) else { return defaultValue }
            return (try? JSONDecoder().decode(Value.self, from: data)) ?? defaultValue
        }
        set {
            let data = (try? JSONEncoder().encode(newValue))
            storage.set(data, forKey: key)
        }
    }
}

@MainActor
final class GoalScheduleStore: ObservableObject, GoalScheduleStoring {
    @CodableAppStorage(key: "goalSchedule.v1", defaultValue: .default)
    private var persisted: GoalSchedule

    @Published var schedule: GoalSchedule = .default {
        didSet { persisted = schedule }
    }

    init() {
        let initial = persisted
        self.schedule = initial
    }
}

extension GoalSchedule {
    mutating func bumpMiles(for weekday: Int, step: Double) {
        let current = miles(for: weekday)
        let next = SmartIncrement.apply(value: current, step: step)
        setMiles(next, for: weekday)
    }
    
    mutating func smartBumpMiles(for weekday: Int, direction: Int) {
        let current = miles(for: weekday)
        let step: Double
        switch current {
        case ..<3: step = 0.25
        case ..<10: step = 0.5
        default: step = 1.0
        }
        bumpMiles(for: weekday, step: Double(direction) * step)
    }

    mutating func setNearestLock(for weekday: Int) {
        let current = miles(for: weekday)
        let locked = DistanceLocks.snap(current, snapWindow: 10)
        setMiles(locked, for: weekday)
    }

    mutating func goToNextLock(for weekday: Int) {
        let current = miles(for: weekday)
        if let next = DistanceLocks.nextLock(after: current) {
            setMiles(next, for: weekday)
        }
    }

    mutating func goToPreviousLock(for weekday: Int) {
        let current = miles(for: weekday)
        if let prev = DistanceLocks.previousLock(before: current) {
            setMiles(prev, for: weekday)
        }
    }
}
