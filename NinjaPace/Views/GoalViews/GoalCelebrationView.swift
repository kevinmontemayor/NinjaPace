//
//  GoalCelebrationView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 9/29/26.
//

import SwiftUI

enum GoalCelebrationSettings {
    static let enabledKey = "GoalCelebrations.enabled"
}

enum GoalCelebrationStyle {
    case goal
    case monthlyChallenge
    case grandmaster
}

struct GoalCelebrationView: View {
    let theme: AppTheme
    let seed: Int
    let style: GoalCelebrationStyle
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var startedAt = Date()
    
    private let particleCount = 28
    private let animationDuration: TimeInterval = 2.05
    
    private var isUITesting: Bool {
#if DEBUG
        ProcessInfo.processInfo.environment[
            "NINJAPACE_IPHONE_UI_TEST_STATE"
        ] != nil
#else
        false
#endif
    }
    
    init(theme: AppTheme, seed: Int = 0, style: GoalCelebrationStyle = .goal) {
        self.theme = theme
        self.seed = seed
        self.style = style
    }
    
    var body: some View {
        GeometryReader { geometry in
            if let screenshotElapsed {
                animatedCelebration(in: geometry.size, elapsed: screenshotElapsed)
            } else if reduceMotion {
                reducedMotionCelebration(in: geometry.size)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    let elapsed = timeline.date.timeIntervalSince(startedAt)
                    animatedCelebration(
                        in: geometry.size,
                        elapsed: elapsed
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(celebrationTitle)
        .accessibilityIdentifier("goalCelebrationOverlay")
        .accessibilityHidden(!isUITesting)
        .onAppear {
            startedAt = Date()
        }
    }
    
    /// Freeze the real renderer only for the opt-in, in-memory screenshot harness.
    private var screenshotElapsed: TimeInterval? {
#if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["NINJAPACE_IPHONE_UI_TEST_STATE"] != nil,
           environment["NINJAPACE_SCREENSHOT_DATA"] == "1",
           ["celebration", "mastery"].contains(environment["NINJAPACE_SCREENSHOT_SCREEN"] ?? "") {
            return 0.85
        }
#endif
        return nil
    }

    private func animatedCelebration(in size: CGSize, elapsed: TimeInterval) -> some View {
        
        let bursts: [BurstOrigin]
        
        switch style {
        case .goal:
            bursts = [
                BurstOrigin(
                    id: 0,
                    point: CGPoint(
                        x: size.width * 0.50,
                        y: size.height * 0.72
                    ),
                    delay: 0,
                    seedOffset: 0
                )
            ]
            
        case .monthlyChallenge:
            bursts = [
                BurstOrigin(
                    id: 0,
                    point: CGPoint(
                        x: size.width * 0.28,
                        y: size.height * 0.72
                    ),
                    delay: 0,
                    seedOffset: 0
                ),
                BurstOrigin(
                    id: 1,
                    point: CGPoint(
                        x: size.width * 0.72,
                        y: size.height * 0.72
                    ),
                    delay: 0.55,
                    seedOffset: 100
                )
            ]
            
        case .grandmaster:
            bursts = [
                BurstOrigin(
                    id: 0,
                    point: CGPoint(
                        x: size.width * 0.50,
                        y: size.height * 0.70
                    ),
                    delay: 0,
                    seedOffset: 0
                ),
                BurstOrigin(
                    id: 1,
                    point: CGPoint(
                        x: size.width * 0.18,
                        y: size.height * 0.72
                    ),
                    delay: 0.85,
                    seedOffset: 100
                ),
                BurstOrigin(
                    id: 2,
                    point: CGPoint(
                        x: size.width * 0.82,
                        y: size.height * 0.72
                    ),
                    delay: 1.75,
                    seedOffset: 200
                )
            ]
        }
        
        return ZStack {
            ForEach(bursts) { burst in
                particleBurst(
                    at: burst.point,
                    in: size,
                    elapsed: elapsed,
                    burstDelay: burst.delay,
                    seedOffset: burst.seedOffset
                )
            }
            
            celebrationBanner(in: size, elapsed: elapsed)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }
    
    private func reducedMotionCelebration(in size: CGSize) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ThemeIconView(
                    icon: theme.celebrationPrimaryIcon,
                    tint: theme.appPrimaryTextColor,
                    size: 46
                )
                
                ThemeIconView(
                    icon: theme.celebrationSecondaryIcon,
                    tint: theme.appPrimaryTextColor,
                    size: 36
                )
            }
            
            Text(celebrationTitle)
                .font(.system(.headline, design: .rounded).weight(.black))
                .tracking(1.1)
                .foregroundStyle(theme.appPrimaryTextColor)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(theme.hudEditorRowBackground)
                .overlay {
                    Capsule()
                        .stroke(theme.tint.opacity(0.75), lineWidth: 1.5)
                }
        )
        .shadow(color: theme.tint.opacity(0.3), radius: 12)
        .position( x: size.width / 2, y: size.height * 0.42)
    }
    
    private func burstRing(at origin: CGPoint, elapsed: TimeInterval, delay: TimeInterval, maximumDiameter: CGFloat) -> some View {
        let localElapsed = max(0, elapsed - delay)
        let progress = max(0, min(1, localElapsed / 0.72))
        let diameter = 26 + maximumDiameter * progress
        
        return Circle()
            .stroke(theme.tint.opacity(max(0, 0.72 * (1 - progress))), lineWidth: 3)
            .frame(width: diameter, height: diameter)
            .position(origin)
    }
    
    private func particle(for index: Int, in size: CGSize) -> GoalCelebrationParticle {
        let horizontalUnit = unitValue(index: index, salt: 11)
        let verticalUnit = unitValue(index: index, salt: 23)
        let gravityUnit = unitValue(index: index, salt: 37)
        let sizeUnit = unitValue(index: index, salt: 41)
        let spinUnit = unitValue(index: index, salt: 53)
        let delayUnit = unitValue(index: index, salt: 67)
        let durationUnit = unitValue(index: index, salt: 79)
        let jitterXUnit = unitValue(index: index, salt: 83)
        let jitterYUnit = unitValue(index: index, salt: 97)
        let usesSecondary = unitValue(index: index, salt: 109) > 0.70

        let direction: Double = index.isMultiple(of: 2) ? 1 : -1

        let themeSpinMultiplier: Double
        switch theme {
        case .ninja:
            themeSpinMultiplier = 1.45
        case .viking:
            themeSpinMultiplier = 1.10
        case .knight:
            themeSpinMultiplier = 0.90
        case .pirate:
            themeSpinMultiplier = 0.18
        case .cyborg:
            themeSpinMultiplier = 0.65
        case .spartan:
            themeSpinMultiplier = 0.95
        }
        
        let launchMultiplier: CGFloat
        let gravityMultiplier: CGFloat

        switch theme {
        case .pirate:
            launchMultiplier = 0.82
            gravityMultiplier = 1.28

        case .cyborg:
            launchMultiplier = 1.08
            gravityMultiplier = 0.90

        default:
            launchMultiplier = 1
            gravityMultiplier = 1
        }
        
        let particleSizeMultiplier: CGFloat

        switch theme {
        case .pirate:
            particleSizeMultiplier = 1.18

        case .cyborg:
            particleSizeMultiplier = 0.82

        default:
            particleSizeMultiplier = 1
        }
        
        let roleSpinMultiplier: Double
        let roleSizeMultiplier: CGFloat
        let roleLaunchMultiplier: CGFloat
        let roleGravityMultiplier: CGFloat

        switch (theme, usesSecondary) {

        case (.ninja, true):
            // Kunai:
            // longer, aerodynamic, slower tumble
            roleSpinMultiplier = 0.55
            roleSizeMultiplier = 0.92
            roleLaunchMultiplier = 1.05
            roleGravityMultiplier = 1.00

        case (.viking, true):
            // Shield:
            // chunky, slower rotation, heavier fall
            roleSpinMultiplier = 0.45
            roleSizeMultiplier = 1.20
            roleLaunchMultiplier = 0.90
            roleGravityMultiplier = 1.12

        case (.knight, true):
            // Shield:
            // broad and weighty
            roleSpinMultiplier = 0.42
            roleSizeMultiplier = 1.18
            roleLaunchMultiplier = 0.90
            roleGravityMultiplier = 1.10

        case (.pirate, true):
            // Flag:
            // lighter and floatier than the cannonballs
            roleSpinMultiplier = 0.35
            roleSizeMultiplier = 1.12
            roleLaunchMultiplier = 1.28
            roleGravityMultiplier = 0.60

        case (.cyborg, true):
            // Energy bolt:
            // shoots rather than tumbles
            roleSpinMultiplier = 0.08
            roleSizeMultiplier = 0.90
            roleLaunchMultiplier = 1.15
            roleGravityMultiplier = 0.78

        case (.spartan, true):
            // Shield:
            // large, deliberate tumble
            roleSpinMultiplier = 0.42
            roleSizeMultiplier = 1.20
            roleLaunchMultiplier = 0.90
            roleGravityMultiplier = 1.10

        default:
            // Primary weapon uses original physics.
            roleSpinMultiplier = 1
            roleSizeMultiplier = 1
            roleLaunchMultiplier = 1
            roleGravityMultiplier = 1
        }
        
        return GoalCelebrationParticle(
            horizontalTravel: CGFloat((horizontalUnit * 1.30) - 0.65) * size.width,
            launchVelocity: -size.height * CGFloat(0.38 + verticalUnit * 0.30) * launchMultiplier * roleLaunchMultiplier,
            gravity: size.height * CGFloat(0.58 + gravityUnit * 0.28) * gravityMultiplier * roleGravityMultiplier,
            size: CGFloat(20 + sizeUnit * 16) * particleSizeMultiplier * roleSizeMultiplier,
            rotation: direction * (520 + spinUnit * 900) * themeSpinMultiplier * roleSpinMultiplier,
            delay: delayUnit * 0.24,
            duration: 1.45 + durationUnit * 0.60,
            startXJitter: CGFloat((jitterXUnit - 0.5) * 44),
            startYJitter: CGFloat((jitterYUnit - 0.5) * 22),
            usesSecondary: usesSecondary
        )
    }
    
    @ViewBuilder
    private func particleBurst(at origin: CGPoint, in size: CGSize, elapsed: TimeInterval, burstDelay: TimeInterval, seedOffset: Int) -> some View {
        burstRing(
            at: origin,
            elapsed: elapsed,
            delay: burstDelay,
            maximumDiameter:
                min(size.width, size.height) * 0.44
        )
        
        burstRing(
            at: origin,
            elapsed: elapsed,
            delay: burstDelay + 0.12,
            maximumDiameter:
                min(size.width, size.height) * 0.32
        )
        
        ForEach(0..<particleCount, id: \.self) { index in
            let particle = particle(for: index + seedOffset, in: size)
            let localElapsed = elapsed - burstDelay - particle.delay
            let progress = max(0, min(1, localElapsed / particle.duration))
            let icon = particle.usesSecondary ? theme.celebrationSecondaryIcon : theme.celebrationPrimaryIcon
            
            if localElapsed >= 0, localElapsed <= particle.duration {
                ThemeIconView(
                    icon: icon,
                    tint: theme.appPrimaryTextColor,
                    size: particle.size
                )
                .scaleEffect(0.72 + 0.34 * sin(.pi * progress))
                .rotationEffect(.degrees(particle.rotation * progress))
                .opacity(particleOpacity(progress))
                .position(
                    x: origin.x
                    + particle.startXJitter
                    + particle.horizontalTravel
                    * progress,
                    y: origin.y
                    + particle.startYJitter
                    + particle.launchVelocity
                    * progress
                    + particle.gravity
                    * progress
                    * progress
                )
            }
        }
    }
    
    private func particleOpacity(_ progress: Double) -> Double {
        if progress < 0.08 {
            return progress / 0.08
        }
        if progress > 0.76 {
            return max(0, (1 - progress) / 0.24)
        }
        return 1
    }

    private func unitValue(index: Int, salt: Int) -> Double {
        let value = sin(Double(index * 97 + salt * 193 + seed * 389) * 12.9898) * 43_758.5453
        return value - floor(value)
    }
    
    private func celebrationBanner(in size: CGSize, elapsed: TimeInterval) -> some View {
        let riseDuration: TimeInterval = 0.55
        let fadeStart: TimeInterval = 1.65
        let rawProgress = max(0, min(1, elapsed / riseDuration))
        // Cubic ease-out.
        let riseProgress = 1 - pow(1 - rawProgress, 3)
        let startY = size.height + 70
        let destinationY = size.height * 0.79
        let y = startY + (destinationY - startY) * riseProgress
        let fadeProgress = max(0, min(1, (elapsed - fadeStart) / 0.40))
        let opacity = rawProgress * (1 - fadeProgress)
        
        return Text(celebrationTitle)
            .font(.system(size: style == .grandmaster ? 30 : 28, weight: .black, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(theme.appPrimaryTextColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
            .background {
                Capsule()
                    .fill(theme.hudEditorRowBackground.opacity(0.96))
                    .overlay {
                        Capsule()
                            .stroke(theme.tint.opacity(0.9), lineWidth: 2)
                    }
            }
            .shadow(color: theme.tint.opacity(0.7), radius: 14)
            .shadow(color: .black.opacity(0.7), radius: 5, y: 3)
            .scaleEffect(0.90 + 0.10 * riseProgress)
            .opacity(opacity)
            .position(x: size.width / 2, y: y)
    }
    
    private var celebrationTitle: String {
        switch style {
        case .goal:
            return "GOAL COMPLETED"

        case .monthlyChallenge:
            return "CHALLENGE CONQUERED"

        case .grandmaster:
            return "GRANDMASTER"
        }
    }
    
    private struct BurstOrigin: Identifiable {
        let id: Int
        let point: CGPoint
        let delay: TimeInterval
        let seedOffset: Int
    }
}

private struct GoalCelebrationParticle {
    let horizontalTravel: CGFloat
    let launchVelocity: CGFloat
    let gravity: CGFloat
    let size: CGFloat
    let rotation: Double
    let delay: TimeInterval
    let duration: TimeInterval
    let startXJitter: CGFloat
    let startYJitter: CGFloat
    let usesSecondary: Bool
}

#if DEBUG

private struct GoalCelebrationPreview: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            WarriorBackgroundView()

            GoalCelebrationView(
                theme: theme,
                seed: 1
            )
        }
        .environmentObject(ThemeStore())
    }
}

#Preview("Weaponized Confetti — Ninja") {
    GoalCelebrationPreview(theme: .ninja)
}

#Preview("Weaponized Confetti — Viking") {
    GoalCelebrationPreview(theme: .viking)
}

#Preview("Weaponized Confetti — Knight") {
    GoalCelebrationPreview(theme: .knight)
}

#Preview("Weaponized Confetti — Pirate") {
    GoalCelebrationPreview(theme: .pirate)
}

#Preview("Weaponized Confetti — Cyborg") {
    GoalCelebrationPreview(theme: .cyborg)
}

#Preview("Weaponized Confetti — Spartan") {
    GoalCelebrationPreview(theme: .spartan)
}

#endif
