//
//  MonthlyChallengeStore.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 9/19/26.
//

import Combine
import Foundation

/// A reward belongs to a calendar month AND year, independently of lifetime awards.
nonisolated struct MonthlyChallengeReward: Codable, Identifiable {
    let year: Int
    let month: Int
    let completedAt: Date
    var id: String { String(format: "%04d-%02d", year, month) }
}

struct MonthlyChallengeEngine {
    let workouts: [WorkoutRecord]
    var calendar: Calendar = .autoupdatingCurrent

    func progress(for date: Date, now: Date = .now) -> AchievementProgress {
        let month = calendar.component(.month, from: date)
        guard let challenge = MonthlyChallenge.challenge(for: month),
              let interval = calendar.dateInterval(of: .month, for: date) else {
            return AchievementProgress(current: 0, target: 1)
        }
        // Completion time determines the month; the upper bound is exclusive.
        let eligible = workouts.filter {
            $0.endedAt >= interval.start && $0.endedAt < interval.end && $0.endedAt <= now
                && $0.duration > 0 && $0.completedMiles.isFinite && $0.completedMiles > 0
        }
        let current: Double
        switch challenge.metric {
        case .workouts: current = Double(eligible.count)
        case .totalMiles: current = eligible.reduce(0) { $0 + $1.completedMiles }
        case .singleWorkoutMiles: current = eligible.map(\.completedMiles).max() ?? 0
        }
        return AchievementProgress(current: current, target: challenge.target)
    }
}

@MainActor
final class MonthlyChallengeStore: ObservableObject {
    static let shared = MonthlyChallengeStore()
    static let rewardsKey = "MonthlyChallenges.earnedRewards"

    @Published private(set) var rewards: [MonthlyChallengeReward]
    @Published var presentedMonth: Date?
    @Published private(set) var isCelebrating = false
    @Published private(set) var schedulingError: String?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        rewards = defaults.data(forKey: Self.rewardsKey)
            .flatMap { try? JSONDecoder().decode([MonthlyChallengeReward].self, from: $0) } ?? []
    }

    func reward(for date: Date, calendar: Calendar = .autoupdatingCurrent) -> MonthlyChallengeReward? {
        rewards.first {
            $0.year == calendar.component(.year, from: date)
                && $0.month == calendar.component(.month, from: date)
        }
    }

    func evaluate(workouts: [WorkoutRecord], now: Date = .now, calendar: Calendar = .autoupdatingCurrent) {
        let engine = MonthlyChallengeEngine(workouts: workouts, calendar: calendar)
        let months = Set(workouts.filter { $0.endedAt <= now }.compactMap {
            calendar.dateInterval(of: .month, for: $0.endedAt)?.start
        })
        var earned = rewards
        for month in months.sorted() where reward(for: month, calendar: calendar) == nil {
            guard engine.progress(for: month, now: now).isComplete else { continue }
            // Preserve the actual crossing date, including rewards recovered from history.
            let records = workouts.filter { calendar.isDate($0.endedAt, equalTo: month, toGranularity: .month) }
                .sorted { $0.endedAt < $1.endedAt }
            let completedAt = records.first {
                engine.progress(for: month, now: min($0.endedAt, now)).isComplete
            }?.endedAt ?? now
            earned.append(MonthlyChallengeReward(year: calendar.component(.year, from: month),
                                                 month: calendar.component(.month, from: month),
                                                 completedAt: completedAt))
            if calendar.isDate(month, equalTo: now, toGranularity: .month), presentedMonth == nil {
                presentedMonth = month
                isCelebrating = true
            }
        }
        guard earned.count != rewards.count, let data = try? JSONEncoder().encode(earned) else { return }
        defaults.set(data, forKey: Self.rewardsKey)
        rewards = earned
    }

    func openCurrentChallenge() {
        presentedMonth = .now
        isCelebrating = false
    }

    func dismissPresentation() {
        presentedMonth = nil
        isCelebrating = false
    }

    func refreshNotifications() async {
        do {
            try await MonthlyChallengeManager.shared.scheduleNotifications()
            schedulingError = nil
        } catch {
            schedulingError = "Monthly challenge alerts could not be scheduled. Try toggling Monthly Challenge Alerts in Goal Alerts."
        }
    }
}
