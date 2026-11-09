//
//  GoalReminderManager.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 9/19/26.
//

import Foundation
import UserNotifications

struct GoalReminderDayPlan: Sendable, Equatable {
    let date: Date
    let goalMiles: Double
}

enum GoalReminderPreferences {
    static let enabledKey = "GoalReminders.enabled"
    static let reminderMinutesKey = "GoalReminders.reminderMinutes"
    static let lastCompletedDayKey = "GoalReminders.lastCompletedDay"

    static let defaultReminderMinutes = 18 * 60 // 6:00 PM

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }

    static var reminderMinutes: Int {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: reminderMinutesKey) != nil else {
            return defaultReminderMinutes
        }

        return min(max(defaults.integer(forKey: reminderMinutesKey), 0), (24 * 60) - 1)
    }

    static var lastCompletedDay: String? {
        UserDefaults.standard.string(forKey: lastCompletedDayKey)
    }
}

actor GoalReminderManager {
    static let shared = GoalReminderManager()

    private static let identifierPrefix = "com.ninjapace.goal-nudge."

    private let center: UNUserNotificationCenter
    private let calendar: Calendar

    init(
        center: UNUserNotificationCenter = .current(),
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.center = center
        self.calendar = calendar
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    func refreshSchedule(
        plans: [GoalReminderDayPlan],
        now: Date = .now
    ) async {
        guard GoalReminderPreferences.isEnabled else {
            await removeAllGoalNudges()
            return
        }

        let status = await authorizationStatus()
        guard Self.canScheduleNotifications(status) else {
            await removeAllGoalNudges()
            return
        }

        await removeAllGoalNudges()

        let reminderMinutes = GoalReminderPreferences.reminderMinutes
        let hour = reminderMinutes / 60
        let minute = reminderMinutes % 60
        let completedDay = GoalReminderPreferences.lastCompletedDay

        for plan in plans where plan.goalMiles > 0.001 {
            let dayKey = dayKey(for: plan.date)

            // A completed goal stays quiet for the rest of that calendar day,
            // even if the app is reopened and the schedule is refreshed.
            if dayKey == completedDay {
                continue
            }

            var dateComponents = calendar.dateComponents(
                [.year, .month, .day],
                from: plan.date
            )
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.second = 0

            guard let fireDate = calendar.date(from: dateComponents),
                  fireDate > now else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = "NinjaPace Goal Alert"
            content.body = "Your \(Self.formattedMiles(plan.goalMiles)) mi goal is still waiting."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )

            let request = UNNotificationRequest(
                identifier: Self.identifier(forDayKey: dayKey),
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                // One failed day should not prevent the remaining reminder
                // window from being scheduled.
                continue
            }
        }
    }

    func markGoalCompletedAndCancelReminder(for date: Date) {
        let key = dayKey(for: date)
        UserDefaults.standard.set(key, forKey: GoalReminderPreferences.lastCompletedDayKey)

        center.removePendingNotificationRequests(
            withIdentifiers: [Self.identifier(forDayKey: key)]
        )
    }

    func removeAllGoalNudges() async {
        let pending = await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }

        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }

        guard !identifiers.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

#if DEBUG
    func scheduleTestNudge(goalMiles: Double) async -> Bool {
        let status = await authorizationStatus()
        guard Self.canScheduleNotifications(status) else { return false }

        let content = UNMutableNotificationContent()
        content.title = "NinjaPace Goal Alert"
        content.body = "Test nudge: your \(Self.formattedMiles(goalMiles)) mi goal is waiting."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "\(Self.identifierPrefix)test",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        )

        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }
#endif

    private func dayKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private static func identifier(forDayKey dayKey: String) -> String {
        "\(identifierPrefix)\(dayKey)"
    }

    private static func formattedMiles(_ miles: Double) -> String {
        miles.formatted(.number.precision(.fractionLength(0...2)))
    }

    private static func canScheduleNotifications(_ status: UNAuthorizationStatus) -> Bool {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }
    
    func sendGoalAchievedNotification(title: String, body: String) async {
        let status = await authorizationStatus()
        
        guard Self.canScheduleNotifications(status) else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "com.ninjapace.goal-achieved.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await center.add(request)
        } catch {
            // Goal achievement notification is non-critical.
        }
    }
}
