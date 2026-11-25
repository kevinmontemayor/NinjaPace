//
//  WatchIdleWarriorClockView.swift
//  NinjaPaceWatch
//
//  Created by Kevin Montemayor on 11/23/26.
//

import SwiftUI

/// A quiet, in-app clock that dismisses back to the normal workout dashboard.
struct WatchIdleWarriorClockView: View {
    @ObservedObject var manager: WatchWorkoutManager
    let theme: WatchTheme
    let clockStyle: WatchIdleClockStyle
    let dismiss: () -> Void
    var isNavigationPreview = false

    private var artwork: String {
        // A new/unpaired Watch has no confirmed rank yet. Never invent an earned title.
        manager.warriorLevel?.assetName(forThemeKey: theme.rawValue) ?? theme.heroAssetName
    }

    var body: some View {
        GeometryReader { geometry in
            let clockHeight = clockStyle == .digital ? 48 : max(64, geometry.size.height * 0.32)
            let titleHeight: CGFloat = 30
            let artworkHeight = max(200, geometry.size.height - clockHeight - titleHeight)
            VStack(spacing: 6) {
                VStack(spacing: 0) {
                    TimelineView(.periodic(
                        from: Calendar.current.dateInterval(of: .minute, for: .now)?.start ?? .now,
                        by: 60
                    )) { context in
                        switch clockStyle {
                        case .digital:
                            Text(context.date, format: .dateTime.hour().minute())
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(theme.primaryTextColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                                .accessibilityIdentifier("idleClockDigital")
                        case .analog:
                            WatchIdleAnalogClock(date: context.date, theme: theme)
                                .frame(height: clockHeight)
                                .accessibilityIdentifier("idleClockAnalog")
                        }
                    }
                }
                .frame(height: clockHeight)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("homeClock")
                WatchWarriorArtworkView(
                    theme: theme,
                    warriorLevel: manager.warriorLevel,
                    running: false,
                    paused: false,
                    identifier: "idleWarriorArtwork"
                )
                .frame(height: artworkHeight)
                .frame(maxWidth: .infinity)
                Color.clear
                    .frame(height: titleHeight)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .background(WatchDashboardBackground(theme: theme))
        ._statusBarHidden(!isNavigationPreview)
        .contentShape(Rectangle())
        .onTapGesture(perform: dismiss)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Warrior idle clock")
        .accessibilityHint("Double tap to return to dashboard")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { dismiss() }
        .accessibilityIdentifier(isNavigationPreview ? "idleClockNavigationPreview" : "idleWarriorClock")
    }
}

struct WatchIdleClockAngles {
    let hour: Double
    let minute: Double

    init(date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = Double(parts.minute ?? 0)
        hour = Double((parts.hour ?? 0) % 12) * 30 + minutes * 0.5
        minute = minutes * 6
    }
}

private struct WatchIdleAnalogClock: View {
    let date: Date
    let theme: WatchTheme

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let radius = diameter / 2
            let angles = WatchIdleClockAngles(date: date)
            ZStack {
                ForEach(0..<60) { tick in
                    Capsule()
                        .fill(tick.isMultiple(of: 5) ? theme.primaryTextColor : theme.secondaryTextColor)
                        .frame(width: tick.isMultiple(of: 5) ? 2 : 1,
                               height: tick.isMultiple(of: 5) ? 7 : 3)
                        .offset(y: -radius + 5)
                        .rotationEffect(.degrees(Double(tick) * 6))
                }
                hand(length: radius * 0.5, width: 3, angle: angles.hour)
                hand(length: radius * 0.76, width: 2, angle: angles.minute)
                Circle().fill(theme.tint).frame(width: 5, height: 5)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(date, format: .dateTime.hour().minute()))
    }

    private func hand(length: CGFloat, width: CGFloat, angle: Double) -> some View {
        Capsule()
            .fill(theme.primaryTextColor)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
    }
}

#if DEBUG
@MainActor
private struct IdleClockPreview: View {
    @StateObject private var manager: WatchWorkoutManager
    let theme: WatchTheme
    let style: WatchIdleClockStyle

    init(theme: WatchTheme, level: WarriorProgressionLevel, style: WatchIdleClockStyle) {
        let manager = WatchWorkoutManager()
        manager.warriorLevel = level
        _manager = StateObject(wrappedValue: manager)
        self.theme = theme
        self.style = style
    }

    var body: some View {
        WatchIdleWarriorClockView(manager: manager, theme: theme, clockStyle: style, dismiss: {})
    }
}

#Preview("Ninja — Digital — Shinobi") {
    IdleClockPreview(theme: .ninja, level: .level1, style: .digital)
}
#Preview("Ninja — Digital — Tatsujin — Small") {
    IdleClockPreview(theme: .ninja, level: .level4, style: .digital)
        .frame(width: 162, height: 197)
}
#Preview("Viking — Analog — Jarl") {
    IdleClockPreview(theme: .viking, level: .level4, style: .analog)
}
#Preview("Cyborg — Digital — Vanguard") {
    IdleClockPreview(theme: .cyborg, level: .level3, style: .digital)
}
#Preview("Pirate — Analog — Captain") {
    IdleClockPreview(theme: .pirate, level: .level3, style: .analog)
}
#endif
