//
//  MileageGoalLadder.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/24/26.
//

import Foundation

enum MileageGoalLadder {

    static let raceLocks: [Double] = [
        3.11,
        6.21,
        13.11,
        26.22
    ]

    static func adjustedMiles(from startingMiles: Double, steps: Int) -> Double {
        guard steps != 0 else { return max(0, startingMiles) }

        var miles = max(0, startingMiles)
        let direction = steps > 0 ? 1 : -1

        for _ in 0..<abs(steps) {
            miles = nextValue(from: miles, direction: direction)
        }

        return max(0, miles)
    }

    static func nextValue(from currentMiles: Double, direction: Int) -> Double {
        let safeMiles = max(0, currentMiles)
        guard direction != 0 else { return safeMiles }

        let epsilon = 0.001

        if direction > 0 {
            let nextHalfMile = (floor(safeMiles * 2 + epsilon) + 1) / 2
            if let nextLock = raceLocks.first(where: { target in
                target > safeMiles + epsilon &&
                target <= nextHalfMile + epsilon
            }) {
                return nextLock
            }

            return nextHalfMile
        } else {
            let previousHalfMile = max(0, (ceil(safeMiles * 2 - epsilon) - 1) / 2)
            if let previousLock = raceLocks.last(where: { target in
                target < safeMiles - epsilon &&
                target >= previousHalfMile - epsilon
            }) {
                return previousLock
            }

            return previousHalfMile
        }
    }

    static func isRaceDistance(_ miles: Double) -> Bool {
        raceLocks.contains {
            abs($0 - miles) < 0.01
        }
    }
}
