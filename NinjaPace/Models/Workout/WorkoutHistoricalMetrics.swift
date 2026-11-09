//
//  WorkoutHistoricalMetrics.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/08/26.
//

import Foundation

enum WorkoutLocation: String, Codable {
    case indoor
    case outdoor
    case unknown
}

struct WorkoutSplit: Codable, Hashable, Identifiable {

    var id: UUID
    var splitNumber: Int

    /// Usually 1.0 mile.
    var distanceMiles: Double

    /// Duration of this individual split.
    var duration: TimeInterval

    var averageHeartRate: Double?
    var averageCadenceSPM: Double?

    init(
        id: UUID = UUID(),
        splitNumber: Int,
        distanceMiles: Double,
        duration: TimeInterval,
        averageHeartRate: Double? = nil,
        averageCadenceSPM: Double? = nil
    ) {
        self.id = id
        self.splitNumber = splitNumber
        self.distanceMiles = distanceMiles
        self.duration = duration
        self.averageHeartRate = averageHeartRate
        self.averageCadenceSPM = averageCadenceSPM
    }

    var paceSecondsPerMile: Double? {
        guard distanceMiles > 0 else { return nil }
        return duration / distanceMiles
    }
}

struct HeartRateZoneSummary: Codable, Hashable, Identifiable {

    var id: UUID
    var zone: Int
    var minimumBPM: Double
    var maximumBPM: Double?
    var duration: TimeInterval

    init(
        id: UUID = UUID(),
        zone: Int,
        minimumBPM: Double,
        maximumBPM: Double? = nil,
        duration: TimeInterval
    ) {
        self.id = id
        self.zone = zone
        self.minimumBPM = minimumBPM
        self.maximumBPM = maximumBPM
        self.duration = duration
    }
}
