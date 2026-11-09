//
//  HUDConfiguration.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/24/26.
//

import Foundation

struct HUDConfiguration: Codable, Equatable, Sendable {
    var title: String
    var subtitle: String?
    var themeKey: String
    var liveColor: String
    var pausedColor: String
    var idleColor: String
    var goalColor: String
    var backgroundColor: String
    var backgroundOpacity: Double
    var borderEnabled: Bool
    var borderWidth: Double
    var glowIntensity: Double
    var scale: Double
    var showMiles: Bool
    var showSteps: Bool
    var showHeartRate: Bool
    var showCalories: Bool
    var showElapsed: Bool
    var showPace: Bool
    var showGoal: Bool
    var textScale: Double
    var textWeight: Int
    var textOutline: Double
    var liveBackgroundColor: String
    var liveBackgroundOpacity: Double
    var pausedBackgroundColor: String
    var pausedBackgroundOpacity: Double
    var idleBackgroundColor: String
    var idleBackgroundOpacity: Double
    var goalBackgroundColor: String
    var goalBackgroundOpacity: Double
    
    nonisolated static let `default` = HUDConfiguration(
        title: "🥷 NINJA HUD 🥷",
        subtitle: nil,
        themeKey: "ninja",
        liveColor: "#FF0050",
        pausedColor: "#FFCC00",
        idleColor: "#B4B4B4",
        goalColor: "#00FF78",
        backgroundColor: "#000000",
        backgroundOpacity: 0,
        borderEnabled: true,
        borderWidth: 2.0,
        glowIntensity: 0.75,
        scale: 1,
        showMiles: true,
        showSteps: true,
        showHeartRate: true,
        showCalories: true,
        showElapsed: true,
        showPace: true,
        showGoal: true,
        textScale: 1.12,
        textWeight: 900,
        textOutline: 0.85,
        liveBackgroundColor: "#101014",
        liveBackgroundOpacity: 0.0,
        pausedBackgroundColor: "#101014",
        pausedBackgroundOpacity: 0.78,
        idleBackgroundColor: "#101014",
        idleBackgroundOpacity: 0.55,
        goalBackgroundColor: "#101014",
        goalBackgroundOpacity: 0.88
    )
}
