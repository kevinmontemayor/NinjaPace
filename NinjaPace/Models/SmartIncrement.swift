//
//  SmartIncrement.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/23/26.
//

import Foundation

enum SmartIncrement {
    /// Adds/subtracts `step` and snaps to canonical distances if within `snapWindow`.
    ///
    /// - value: current miles
    /// - step: e.g. +0.5 or -0.5
    /// - snapWindow: how close you need to be to lock (0.15 feels good for 0.5 steps)
    /// - minValue: min allowed miles
    /// - maxValue: max allowed miles
    static func apply(
        value: Double,
        step: Double,
        snapWindow: Double = 0.15,
        minValue: Double = 0,
        maxValue: Double = 100
    ) -> Double {
        let raw = (value + step)
        let clamped = max(minValue, min(maxValue, raw))
        let snapped = DistanceLocks.snap(clamped, snapWindow: snapWindow)

        // keep nice formatting (optional)
        return snapped.roundedTo(5)
    }
}

