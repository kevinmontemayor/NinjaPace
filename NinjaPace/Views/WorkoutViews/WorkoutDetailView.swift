//
//  WorkoutDetailView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/08/26.
//

import Foundation
import SwiftUI

struct WorkoutDetailView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showsGoalEditor = false
    let workout: WorkoutRecord

    var body: some View {
        ZStack {
            WarriorBackgroundView()
            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    primaryStatsCard
                    performanceCard
                    caloriesCard
                    speedCard
                    goalCard
                    if !workout.heartRateZones.isEmpty { heartRateZonesCard }
                    if !workout.splits.isEmpty { splitsCard }
                    if !unlockedAchievements.isEmpty { achievementsCard }
                    workoutInfoCard
                }
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showsGoalEditor) { WorkoutGoalEditor(workout: workout) }
        .navigationTitle("Workout Details").navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                }
            }
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: 12) {
            Image(
                systemName: workout.wasGoalCompleted
                    ? "figure.run.circle.fill" : "figure.run.circle"
            )
            .font(.system(size: 48))
            .foregroundStyle(workout.wasGoalCompleted ? Color.green : themeStore.theme.appPrimaryTextColor)
            Text(workout.startedAt.formatted(date: .complete, time: .omitted))
                .font(.headline).foregroundStyle(themeStore.theme.appPrimaryTextColor)
            Text(workout.startedAt.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            if workout.wasGoalCompleted {
                Label("Goal Completed", systemImage: "checkmark.circle.fill")
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity).padding(20)
        .background(themeStore.theme.hudEditorRowBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Primary Stats

    private var primaryStatsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Workout Summary", systemImage: "chart.bar.fill")
            metricGridRow(
                leftTitle: "Distance", leftValue: formattedMiles, rightTitle: "Duration",
                rightValue: formattedDuration)
            Divider()
            metricGridRow(
                leftTitle: "Steps", leftValue: workout.steps.formatted(),
                rightTitle: "Avg. Cadence", rightValue: formattedAverageSPM)
            Divider()
            metricGridRow(
                leftTitle: "Avg. Pace", leftValue: formattedAveragePace,
                rightTitle: "Goal", rightValue: formattedGoalMiles)
        }
        .themedWorkoutCard(theme: themeStore.theme)
    }

    // MARK: - Performance Card

    private var performanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Performance", systemImage: "heart.fill")
            metricGridRow(
                leftTitle: "Avg. Heart Rate", leftValue: formattedAverageHeartRate,
                rightTitle: "Peak Heart Rate", rightValue: formattedPeakHeartRate)
            Divider()
            metricGridRow(
                leftTitle: "Start",
                leftValue: workout.startedAt.formatted(date: .omitted, time: .shortened),
                rightTitle: "Finish",
                rightValue: workout.endedAt.formatted(date: .omitted, time: .shortened))
        }
        .themedWorkoutCard(theme: themeStore.theme)
    }

    // MARK: - Calories Card

    private var caloriesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Energy", systemImage: "flame.fill")
            metricGridRow(
                leftTitle: "Active Calories", leftValue: formattedActiveCalories,
                rightTitle: "Total Calories", rightValue: formattedTotalCalories)

            if let elevation = workout.elevationGainFeet, elevation > 0 {
                Divider()
                metricGridRow(
                    leftTitle: "Elevation Gain",
                    leftValue: "\(Int(elevation.rounded())) ft", rightTitle: "Location",
                    rightValue: formattedWorkoutLocation)
            }
        }
        .themedWorkoutCard(theme: themeStore.theme)
    }
    
    private var formattedActiveCalories: String {
        guard let calories = workout.activeCalories, calories > 0 else { return "—" }

        return "\(Int(calories.rounded())) kcal"
    }

    private var formattedTotalCalories: String {
        guard let calories = workout.totalCalories, calories > 0 else { return "—" }

        return "\(Int(calories.rounded())) kcal"
    }

    // MARK: - Speed Card

    private var speedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Movement", systemImage: "speedometer")
            metricGridRow(
                leftTitle: "Avg. Speed", leftValue: formattedAverageSpeed,
                rightTitle: "Peak Speed", rightValue: formattedPeakSpeed)
            Divider()
            metricGridRow(
                leftTitle: "Active Time",
                leftValue: formattedTime(workout.activeDuration),
                rightTitle: "Paused Time",
                rightValue: formattedTime(workout.pausedDuration ?? 0))
        }
        .themedWorkoutCard(theme: themeStore.theme)
    }

    // MARK: - Goal Card

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Goal Performance", systemImage: "target")

            Button(workout.goalMiles > 0 ? "Edit Goal" : "Set Original Goal") {
                showsGoalEditor = true
            }
            if workout.goalMiles <= 0 {
                Text("The original goal was not saved in Apple Health. Set it to restore this workout’s goal completion and warrior progress.")
                    .font(.footnote)
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }

            HStack {
                Text("Goal Progress")
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)

                Spacer()

                Text("\(Int(workout.goalCompletionPercentage.rounded()))%")
                    .fontWeight(.bold).monospacedDigit()
                    .foregroundStyle(
                        workout.wasGoalCompleted
                            ? Color.green : themeStore.theme.appPrimaryTextColor)
            }

            ProgressView(value: min(workout.goalCompletionPercentage / 100, 1))
                .tint(workout.wasGoalCompleted ? .green : themeStore.theme.appPrimaryTextColor)

            if workout.milesOverGoal > 0.001 {
                metricGridRow(
                    leftTitle: "Goal", leftValue: formattedGoalMiles,

                    rightTitle: "Over Goal",
                    rightValue: workout.milesOverGoal.formatted(
                        .number.precision(.fractionLength(2))) + " mi")
            } else {
                metricGridRow(
                    leftTitle: "Goal", leftValue: formattedGoalMiles,

                    rightTitle: "Completed",
                    rightValue: workout.wasGoalCompleted ? "Yes" : "No")
            }

            if workout.wasScheduledRestDay {
                Label("Completed on a scheduled rest day", systemImage: "bed.double.fill")
                    .font(.footnote)
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }
        }
        .themedWorkoutCard(theme: themeStore.theme)
    }

    // MARK: - Heart Rate Zones Card

    private var heartRateZonesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Heart Rate Zones", systemImage: "heart.text.square.fill")

            ForEach(workout.heartRateZones) { zone in
                if zone.id != workout.heartRateZones.first?.id { Divider() }

                heartRateZoneRow(zone)
            }
        }
        .themedWorkoutCard(theme: themeStore.theme)
    }
    
    private func heartRateZoneRow(_ zone: HeartRateZoneSummary) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            themeStore.theme.appPrimaryTextColor.opacity(
                                zoneOpacity(for: zone.zone))
                        )
                        .frame(width: 34, height: 34)
                    Text("\(zone.zone)").font(.system(.caption, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Zone \(zone.zone)").fontWeight(.semibold)
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    Text(formattedHeartRateRange(zone)).font(.caption)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedZoneDuration(zone.duration))
                        .font(.system(.body, design: .monospaced)).fontWeight(.bold)
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    Text(formattedZonePercentage(zone)).font(.caption)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }
            }
            GeometryReader { geometry in
                let progress = heartRateZoneProgress(zone)
                ZStack(alignment: .leading) {
                    Capsule().fill(themeStore.theme.appSecondaryTextColor.opacity(0.12))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeStore.theme.appPrimaryTextColor.opacity(
                                        zoneOpacity(for: zone.zone)),
                                    themeStore.theme.appPrimaryTextColor,
                                ], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Splits Card

    private var splitsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Mile Splits", systemImage: "flag.checkered")
            ForEach(workout.splits) { split in
                if split.id != workout.splits.first?.id { Divider() }
                HStack {
                    Text("Mile \(split.splitNumber)").fontWeight(.semibold)
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedSplitPace(split))
                            .font(.system(.body, design: .monospaced)).fontWeight(.bold)
                            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                        HStack(spacing: 8) {
                            if let heartRate = split.averageHeartRate {
                                Text("\(Int(heartRate.rounded())) bpm")
                            }
                            if let cadence = split.averageCadenceSPM {
                                Text("\(Int(cadence.rounded())) spm")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    }
                }
            }
        }
        .themedWorkoutCard(theme: themeStore.theme)
    }

    // MARK: - Achievements Card

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Achievements Unlocked", systemImage: "trophy.fill")
            ForEach(unlockedAchievements) { achievement in
                if achievement.id != unlockedAchievements.first?.id { Divider() }
                achievementRow(achievement)
            }
        }
        .themedWorkoutCard(theme: themeStore.theme)
    }
    
    private func achievementRow(_ achievement: Achievement) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(themeStore.theme.appPrimaryTextColor.opacity(0.16))
                    .frame(width: 46, height: 46)
                Circle()
                    .stroke(
                        themeStore.theme.appPrimaryTextColor.opacity(0.55), lineWidth: 1.5
                    )
                    .frame(width: 46, height: 46)
                Image(systemName: achievement.systemImage)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(achievement.title).fontWeight(.bold)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                Text(achievement.description).font(.caption)
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
    
    private var unlockedAchievements: [Achievement] {
        workout.unlockedAchievementIDs.compactMap { Achievement(rawValue: $0) }
    }

    // MARK: - Metadata

    private var workoutInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Workout Info", systemImage: "info.circle.fill")
            infoRow(title: "Type", value: workout.workoutTypeRawValue.capitalized)
            Divider()
            infoRow(title: "Source", value: workout.source)
        }
        .themedWorkoutCard(theme: themeStore.theme)
    }

    // MARK: - Components

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage).font(.headline)
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
    }

    private func metricGridRow(leftTitle: String, leftValue: String, rightTitle: String, rightValue: String) -> some View {
        HStack(spacing: 12) {
            metric(title: leftTitle, value: leftValue)
            Divider().frame(height: 40)
            metric(title: rightTitle, value: rightValue)
        }
    }
    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(.headline, design: .monospaced)).fontWeight(.bold)
                .foregroundStyle(themeStore.theme.appPrimaryTextColor).lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title).font(.caption)
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
    private var formattedWorkoutLocation: String {
        guard let location = workout.workoutLocationRawValue, !location.isEmpty else {
            return "—"
        }
        return location.capitalized
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(themeStore.theme.appSecondaryTextColor)
            Spacer()
            Text(value).fontWeight(.semibold)
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }
    }

    // MARK: - Formatting

    private var formattedMiles: String {
        workout.completedMiles.formatted(.number.precision(.fractionLength(2))) + " mi"
    }
    
    private var formattedGoalMiles: String {
        workout.goalMiles.formatted(.number.precision(.fractionLength(2))) + " mi"
    }
    
    private var formattedDuration: String {
        formattedTime(workout.duration)
    }
    
    private var formattedAverageHeartRate: String {
        guard let average = workout.averageHeartRate, average > 0 else { return "—" }
        return "\(Int(average.rounded())) bpm"
    }
    
    private var formattedPeakHeartRate: String {
        guard let peak = workout.peakHeartRate, peak > 0 else { return "—" }
        return "\(Int(peak.rounded())) bpm"
    }

    private var formattedAverageSPM: String {
        guard let cadence = workout.resolvedAverageCadenceSPM, cadence > 0 else {
            return "—"
        }
        return "\(Int(cadence.rounded())) spm"
    }

    private var formattedAveragePace: String {
        guard let pace = workout.averagePaceSecondsPerMile, pace > 0 else { return "—" }
        let totalSeconds = Int(pace.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d /mi", minutes, seconds)
    }

    // MARK: - Helpers

    private var formattedAverageSpeed: String {
        guard let speed = workout.resolvedAverageSpeedMPH else { return "—" }
        return speed.formatted(.number.precision(.fractionLength(2))) + " mph"
    }
    
    private var formattedPeakSpeed: String {
        guard let speed = workout.resolvedPeakSpeedMPH else { return "—" }
        return speed.formatted(.number.precision(.fractionLength(2))) + " mph"
    }

    private func formattedTime(_ duration: TimeInterval) -> String {
        Duration.seconds(duration)
            .formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2)))
    }
    
    private func formattedSplitPace(_ split: WorkoutSplit) -> String {
        guard let pace = split.paceSecondsPerMile else { return "—" }

        let seconds = Int(pace.rounded())

        return String(format: "%d:%02d /mi", seconds / 60, seconds % 60)
    }
    
    private var totalHeartRateZoneDuration: TimeInterval {
        workout.heartRateZones.reduce(0) { $0 + $1.duration }
    }
    
    private func heartRateZoneProgress(_ zone: HeartRateZoneSummary) -> Double {
        guard totalHeartRateZoneDuration > 0 else { return 0 }
        return min(max(zone.duration / totalHeartRateZoneDuration, 0), 1)
    }
    
    private func formattedZonePercentage(_ zone: HeartRateZoneSummary) -> String {
        let percentage = heartRateZoneProgress(zone) * 100
        return "\(Int(percentage.rounded()))%"
    }
    
    private func formattedZoneDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded())

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, seconds) }

        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formattedHeartRateRange(_ zone: HeartRateZoneSummary) -> String {
        let minimum = Int(zone.minimumBPM.rounded())
        if let maximum = zone.maximumBPM {
            return "\(minimum)–\(Int(maximum.rounded())) bpm"
        }
        return "\(minimum)+ bpm"
    }
    
    private func zoneOpacity(for zone: Int) -> Double {
        switch zone {
        case 1: return 0.25
        case 2: return 0.40
        case 3: return 0.58
        case 4: return 0.76
        case 5: return 1.0
        default: return 0.45
        }
    }
}

#if DEBUG

extension WorkoutRecord {
    static var previewMarathon: WorkoutRecord {
        WorkoutRecord(
            startedAt: Calendar.current.date(bySettingHour: 7, minute: 12, second: 0, of: Date()) ?? Date(),
            endedAt: Calendar.current.date(bySettingHour: 13, minute: 26, second: 32, of: Date()) ?? Date(),
            goalMiles: 26.2, completedMiles: 26.24, steps: 48_921,
            averageHeartRate: 143, peakHeartRate: 172, activeCalories: 2_846,
            totalCalories: 3_102, averageCadenceSPM: 164, elevationGainFeet: 0,
            duration: 6 * 3600 + 14 * 60 + 32, pausedDuration: 11 * 60 + 18,
            averagePaceSecondsPerMile: 14 * 60 + 17, averageSpeedMPH: 4.2,
            peakSpeedMPH: 8.5, workoutTypeRawValue: "running",
            workoutLocationRawValue: "indoor", source: "NinjaPace",
            splits: [
                WorkoutSplit(
                    splitNumber: 1, distanceMiles: 1, duration: 13 * 60 + 52,
                    averageHeartRate: 129, averageCadenceSPM: 162),
                WorkoutSplit(
                    splitNumber: 2, distanceMiles: 1, duration: 13 * 60 + 46,
                    averageHeartRate: 133, averageCadenceSPM: 164),
                WorkoutSplit(
                    splitNumber: 3, distanceMiles: 1, duration: 13 * 60 + 41,
                    averageHeartRate: 137, averageCadenceSPM: 165),
                WorkoutSplit(
                    splitNumber: 4, distanceMiles: 1, duration: 13 * 60 + 38,
                    averageHeartRate: 141, averageCadenceSPM: 166),
                WorkoutSplit(
                    splitNumber: 5, distanceMiles: 1, duration: 13 * 60 + 55,
                    averageHeartRate: 144, averageCadenceSPM: 164),
            ],
            heartRateZones: [
                HeartRateZoneSummary(
                    zone: 1, minimumBPM: 90, maximumBPM: 119, duration: 21 * 60),
                HeartRateZoneSummary(
                    zone: 2, minimumBPM: 120, maximumBPM: 139,
                    duration: 2 * 3600 + 8 * 60),
                HeartRateZoneSummary(
                    zone: 3, minimumBPM: 140, maximumBPM: 154,
                    duration: 2 * 3600 + 43 * 60),
                HeartRateZoneSummary(
                    zone: 4, minimumBPM: 155, maximumBPM: 169, duration: 47 * 60),
                HeartRateZoneSummary(
                    zone: 5, minimumBPM: 170, maximumBPM: nil, duration: 4 * 60),
            ],
            unlockedAchievementIDs: [
                Achievement.marathon.rawValue, Achievement.twentyFiveMiles.rawValue,
            ])
    }
}

#Preview("Marathon Workout") {
    NavigationStack { WorkoutDetailView(workout: .previewMarathon) }
        .environmentObject(ThemeStore())
}
#endif
