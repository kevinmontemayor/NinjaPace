//
//  DistanceLocks.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/23/26.
//

import Foundation

enum DistanceLocks {
    // Canonical mile distances
    static let oneMile: Double = 1.0
    static let twoMiles: Double = 2.0
    static let fiveK: Double = 3.10686
    static let tenK: Double = 6.21371
    static let half: Double = 13.1094
    static let full: Double = 26.2188
    
    // Ordered list matters for "next/previous lock" navigation
    static let locks: [Double] = [
        oneMile, twoMiles, fiveK, tenK, half, full
    ]
    
    /// If candidate is within `snapWindow` miles of a lock, return the lock.
    static func snap(_ candidate: Double, snapWindow: Double) -> Double {
        guard candidate > 0 else { return 0 }
        var best: (value: Double, delta: Double)? = nil

        for lock in locks {
            let delta = abs(candidate - lock)
            if delta <= snapWindow {
                if best == nil || delta < best!.delta {
                    best = (lock, delta)
                }
            }
        }
        return best?.value ?? candidate
    }
    
    /// Move to the next lock above current (if any)
    static func nextLock(after value: Double) -> Double? {
        locks.first(where: { $0 > value })
    }
    
    /// Move to the previous lock below current (if any)
    static func previousLock(before value: Double) -> Double? {
        locks.last(where: { $0 < value })
    }
}

extension Double {
    /// Helpful for avoiding ugly floating point tails
    func roundedTo(_ places: Int) -> Double {
        let power = pow(10.0, Double(places))
        return (self * power).rounded() / power
    }
}
