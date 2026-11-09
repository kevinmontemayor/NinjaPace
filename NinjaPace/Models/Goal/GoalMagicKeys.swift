//
//  GoalMagicKeys.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/20/26.
//

import Foundation

enum GoalMagicKeys {
    static let lastManualGoalDay = "goal.lastManualDay.v1"
    static let lastAppliedScheduleDay = "goal.lastAppliedScheduleDay.v1"

    static func dayKey(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 0
        let m = comps.month ?? 0
        let d = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}

extension UserDefaults {
    func string(forKey key: String, default defaultValue: String) -> String {
        string(forKey: key) ?? defaultValue
    }
}
