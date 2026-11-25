//
//  WatchIdleClockStyle.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import Foundation

enum WatchIdleClockStyle: String, CaseIterable, Identifiable {
    case digital, analog

    var id: String { rawValue }
    var title: String { self == .digital ? "Digital" : "Analog" }
}
