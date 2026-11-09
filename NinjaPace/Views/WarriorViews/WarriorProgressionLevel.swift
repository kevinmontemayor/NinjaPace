//
//  WarriorProgressionLevel.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/24/26.
//

import Foundation
import SwiftUI

enum WarriorProgressionLevel: Int, CaseIterable, Comparable {
    
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4
    
    var requiredGoals: Int {

        switch self {

        case .level1:
            return 0

        case .level2:
            return 10

        case .level3:
            return 25

        case .level4:
            return 50
        }
    }

    var nextLevel: WarriorProgressionLevel? {
        switch self {
        case .level1:
            return .level2
            
        case .level2:
            return .level3
            
        case .level3:
            return .level4
            
        case .level4:
            return nil
        }
    }

    static func level(for completedGoals: Int) -> WarriorProgressionLevel {
        switch completedGoals {
        case 50...:
            return .level4
            
        case 25...:
            return .level3
            
        case 10...:
            return .level2
            
        default:
            return .level1
        }
    }

    static func < (
        lhs: WarriorProgressionLevel,
        rhs: WarriorProgressionLevel
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var rankNumber: Int {
        rawValue
    }

    var rankLabel: String {
        "RANK \(romanNumeral)"
    }

    private var romanNumeral: String {
        switch self {
        case .level1:
            return "I"

        case .level2:
            return "II"

        case .level3:
            return "III"

        case .level4:
            return "IV"
        }
    }
}

extension WarriorProgressionLevel {

    var auraPrimaryColor: Color {
        switch self {
        case .level1:
            return .gray

        case .level2:
            return .yellow

        case .level3:
            return .red

        case .level4:
            return .cyan
        }
    }

    var auraSecondaryColor: Color {
        switch self {
        case .level1:
            return .white

        case .level2:
            return .orange

        case .level3:
            return .orange

        case .level4:
            return .purple
        }
    }

    var auraMinimumRadius: CGFloat {
        switch self {
        case .level1:
            return 8

        case .level2:
            return 14

        case .level3:
            return 22

        case .level4:
            return 30
        }
    }

    var auraMaximumRadius: CGFloat {
        switch self {
        case .level1:
            return 14

        case .level2:
            return 24

        case .level3:
            return 34

        case .level4:
            return 50
        }
    }

    var auraMinimumOpacity: Double {
        switch self {
        case .level1:
            return 0.18

        case .level2:
            return 0.30

        case .level3:
            return 0.42

        case .level4:
            return 0.55
        }
    }

    var auraMaximumOpacity: Double {
        switch self {
        case .level1:
            return 0.40

        case .level2:
            return 0.60

        case .level3:
            return 0.72

        case .level4:
            return 0.90
        }
    }

    var auraPulseDuration: Double {
        switch self {
        case .level1:
            return 2.2

        case .level2:
            return 1.9

        case .level3:
            return 1.65

        case .level4:
            return 1.35
        }
    }
}
