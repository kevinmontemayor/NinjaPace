import Foundation
import Testing
import UserNotifications
@testable import NinjaPace

@Suite("Monthly Challenges")
@MainActor
struct MonthlyChallengeTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Denver")!
        return calendar
    }

    private func date(_ year: Int = 2026, _ month: Int, _ day: Int = 1) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func workout(ending date: Date, miles: Double = 1) -> WorkoutRecord {
        WorkoutRecord(startedAt: date.addingTimeInterval(-1800), endedAt: date,
                      goalMiles: 3, completedMiles: miles, steps: 2000, duration: 1800)
    }

    @Test("Twelve independent announcements repeat at 9 AM on the first")
    func notifications() throws {
        let requests = MonthlyChallenge.all.map(MonthlyChallengeManager.notificationRequest)
        #expect(Set(requests.map(\.identifier)).count == 12)
        for (challenge, request) in zip(MonthlyChallenge.all, requests) {
            let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
            #expect(trigger.repeats)
            #expect(trigger.dateComponents.month == challenge.month)
            #expect(trigger.dateComponents.day == 1)
            #expect(trigger.dateComponents.hour == 9)
            #expect(trigger.dateComponents.minute == 0)
            #expect(trigger.dateComponents.year == nil)
            #expect(trigger.dateComponents.timeZone == nil)
            #expect(request.content.userInfo["destination"] as? String == "monthlyChallenge")
            #expect(request.content.subtitle == challenge.title)
        }
    }

    @Test("Months use completion time, exclude the next month and future workouts")
    func boundaries() {
        let workouts = [workout(ending: date(2026, 11)), workout(ending: date(2026, 12)),
                        workout(ending: date(2026, 10, 31)), workout(ending: date(2026, 11, 20))]
        let engine = MonthlyChallengeEngine(workouts: workouts, calendar: calendar)
        #expect(engine.progress(for: date(2026, 11), now: date(2026, 11, 15)).current == 1)
    }

    @Test("Mileage totals add workouts while single-workout challenges use the maximum")
    func metrics() {
        let february = MonthlyChallengeEngine(workouts: [workout(ending: date(2026, 2, 2), miles: 17),
            workout(ending: date(2026, 2, 3), miles: 13)], calendar: calendar)
        #expect(february.progress(for: date(2026, 2), now: date(2026, 3)).isComplete)
        let july = MonthlyChallengeEngine(workouts: [workout(ending: date(2026, 7, 2), miles: 4),
            workout(ending: date(2026, 7, 3), miles: 4)], calendar: calendar)
        #expect(july.progress(for: date(2026, 7), now: date(2026, 8)).current == 4)
        #expect(!july.progress(for: date(2026, 7), now: date(2026, 8)).isComplete)
    }

    @Test("Rewards persist after deletion, do not repeat celebrations, and reset each year")
    func persistence() throws {
        let suite = "MonthlyChallengeTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = MonthlyChallengeStore(defaults: defaults)
        let workouts = (1...12).map { workout(ending: date(2026, 11, $0)) }
        store.evaluate(workouts: workouts, now: date(2026, 11, 15), calendar: calendar)
        #expect(store.rewards.count == 1)
        #expect(store.rewards.first?.id == "2026-11")
        #expect(store.rewards.first?.completedAt == date(2026, 11, 12))
        #expect(store.isCelebrating)
        store.dismissPresentation()
        store.evaluate(workouts: workouts, now: date(2026, 11, 16), calendar: calendar)
        #expect(store.presentedMonth == nil)
        let restored = MonthlyChallengeStore(defaults: defaults)
        restored.evaluate(workouts: [], now: date(2027, 11), calendar: calendar)
        #expect(restored.reward(for: date(2026, 11), calendar: calendar) != nil)
        #expect(restored.reward(for: date(2027, 11), calendar: calendar) == nil)
    }

    @Test("Zero distance and invalid distance do not earn workout-count rewards")
    func invalidWorkouts() {
        let engine = MonthlyChallengeEngine(workouts: [workout(ending: date(2026, 11, 2), miles: 0),
            workout(ending: date(2026, 11, 3), miles: .nan)], calendar: calendar)
        #expect(engine.progress(for: date(2026, 11), now: date(2026, 12)).current == 0)
    }

    @Test("The catalog has one challenge per month and leaves lifetime awards separate")
    func catalog() {
        #expect(MonthlyChallenge.all.map(\.month) == Array(1...12))
        #expect(MonthlyChallenge.all.allSatisfy { $0.target > 0 })
        #expect(MonthlyChallenge.challenge(for: 0) == nil)
        #expect(MonthlyChallenge.challenge(for: 13) == nil)
    }
}
