//
//  MonthlyChallengeManager.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 9/7/26.
//

import Foundation
import UserNotifications

// MARK: - Challenge Types

nonisolated enum MonthlyChallengeMetric: String, Codable, Sendable {
    case workouts
    case totalMiles
    case singleWorkoutMiles
}

// MARK: - Monthly Challenge

nonisolated struct MonthlyChallenge: Identifiable, Sendable {

    let month: Int
    let title: String
    let description: String
    let metric: MonthlyChallengeMetric
    let target: Double

    var id: Int { month }

    var badgeAsset: String {
        "achievement_month_\(month)"
    }

    static let all: [MonthlyChallenge] = [

        .init(
            month: 1,
            title: "New Year's Resolve",
            description: "Complete 10 workouts",
            metric: .workouts,
            target: 10
        ),

        .init(
            month: 2,
            title: "Heart of a Warrior",
            description: "Run 30 total miles",
            metric: .totalMiles,
            target: 30
        ),

        .init(
            month: 3,
            title: "March of Champions",
            description: "Complete 12 workouts",
            metric: .workouts,
            target: 12
        ),

        .init(
            month: 4,
            title: "Storm Runner",
            description: "Run 40 total miles",
            metric: .totalMiles,
            target: 40
        ),

        .init(
            month: 5,
            title: "Trial by Fire",
            description: "Complete 15 workouts",
            metric: .workouts,
            target: 15
        ),

        .init(
            month: 6,
            title: "Summer Vanguard",
            description: "Run 50 total miles",
            metric: .totalMiles,
            target: 50
        ),

        .init(
            month: 7,
            title: "Summit Conqueror",
            description: "Complete a 10K workout",
            metric: .singleWorkoutMiles,
            target: 6.2137
        ),

        .init(
            month: 8,
            title: "Iron Discipline",
            description: "Complete 16 workouts",
            metric: .workouts,
            target: 16
        ),

        .init(
            month: 9,
            title: "Relentless Pursuit",
            description: "Run 60 total miles",
            metric: .totalMiles,
            target: 60
        ),

        .init(
            month: 10,
            title: "Shadow Warrior",
            description: "Complete 13 workouts",
            metric: .workouts,
            target: 13
        ),

        .init(
            month: 11,
            title: "Iron Will",
            description: "Complete 12 workouts",
            metric: .workouts,
            target: 12
        ),

        .init(
            month: 12,
            title: "Final Stand",
            description: "Run 50 total miles",
            metric: .totalMiles,
            target: 50
        )
    ]

    static func challenge(for month: Int) -> MonthlyChallenge? {
        all.first { $0.month == month }
    }

    static var current: MonthlyChallenge? {
        let month = Calendar.autoupdatingCurrent.component(
            .month,
            from: .now
        )

        return challenge(for: month)
    }
}

// MARK: - Monthly Challenge Preferences

nonisolated enum MonthlyChallengePreferences {

    static let enabledKey =
        "MonthlyChallenges.notificationsEnabled"

    static let reminderMinutesKey =
        "MonthlyChallenges.reminderMinutes"

    // Default: 9:00 AM
    static let defaultReminderMinutes = 9 * 60

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }

    static var reminderMinutes: Int {
        let defaults = UserDefaults.standard
        
        guard defaults.object(
            forKey: reminderMinutesKey
        ) != nil else {
            return defaultReminderMinutes
        }
        
        return min(max(defaults.integer(forKey: reminderMinutesKey), 0), 1439)
    }
}

// MARK: - Monthly Notifications

actor MonthlyChallengeManager {

    static let shared = MonthlyChallengeManager()

    private let center = UNUserNotificationCenter.current()

    nonisolated static let identifierPrefix = "com.ninjapace.monthly-challenge."
    private var scheduleGeneration = 0

    func scheduleNotifications() async throws {
        scheduleGeneration += 1
        let generation = scheduleGeneration
        guard MonthlyChallengePreferences.isEnabled else {
            removeNotifications()
            return
        }
        let status = await notificationStatus()
        guard generation == scheduleGeneration else { return }
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            removeNotifications()
            return
        }
        // Stable identifiers replace earlier requests without touching daily reminders.
        for challenge in MonthlyChallenge.all {
            guard generation == scheduleGeneration else { return }
            do {
                try await center.add(Self.notificationRequest(for: challenge))
            } catch {
                if generation == scheduleGeneration { removeNotifications() }
                throw error
            }
            // Disabling during an in-flight add must not leave an alert behind.
            if !MonthlyChallengePreferences.isEnabled {
                removeNotifications()
                return
            }
        }
    }

    nonisolated static func notificationRequest(for challenge: MonthlyChallenge) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "⚔️ NEW NINJAPACE CHALLENGE!"
        content.subtitle = challenge.title
        content.body = "A new battle awaits, Warrior! \(challenge.description) to unlock your monthly achievement."
        content.sound = .default
        content.userInfo = ["destination": "monthlyChallenge", "month": challenge.month]
        let reminderMinutes = MonthlyChallengePreferences.reminderMinutes
        let hour = reminderMinutes / 60
        let minute = reminderMinutes % 60
        
        var components = DateComponents()
        components.month = challenge.month
        
        // Always the FIRST of the month
        components.day = 1
        
        // User-selected time
        components.hour = hour
        components.minute = minute
        
        components.second = 0
        return UNNotificationRequest(identifier: "\(identifierPrefix)\(challenge.month)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )
    }

    func removeNotifications() {
        scheduleGeneration += 1
        center.removePendingNotificationRequests(withIdentifiers: MonthlyChallenge.all.map {
            "\(Self.identifierPrefix)\($0.month)"
        })
    }

    private func notificationStatus() async -> UNAuthorizationStatus {

        await withCheckedContinuation { continuation in

            center.getNotificationSettings { settings in

                continuation.resume(
                    returning: settings.authorizationStatus
                )
            }
        }
    }
}
