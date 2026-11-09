//
//  WorkoutHistoryView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 8/7/26.
//

import Foundation
import SwiftData
import SwiftUI

struct WorkoutHistoryView: View {

    @EnvironmentObject private var themeStore: ThemeStore
    @State private var expandedYear: Date?
    @State private var expandedMonth: Date?
    @State private var didSeedInitialYear = false
    @State private var showsRecovery = false
    @State private var showsWorkoutTrends = false
    @Query(sort: \WorkoutRecord.startedAt, order: .reverse) private var workouts: [WorkoutRecord]
    
    private var conditionalColor: Color {
        themeStore.theme == .ninja ? themeStore.theme.tint : .white
    }

    private var completedGoalCount: Int {
        workouts.filter(\.wasGoalCompleted).count
    }
    
    private var groupedWorkouts: [WorkoutMonthGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: workouts) { workout in
            let components = calendar.dateComponents([.year, .month], from: workout.startedAt)
            return calendar.date(from: components) ?? workout.startedAt
        }

        return grouped
            .map { monthStart, workouts in
                WorkoutMonthGroup(
                    monthStart: monthStart,
                    workouts: workouts.sorted { $0.startedAt > $1.startedAt }
                )
            }
            .sorted { $0.monthStart > $1.monthStart }
    }
    
    private var groupedYears: [WorkoutYearGroup] {
        let calendar = Calendar.current

        let grouped = Dictionary(
            grouping: groupedWorkouts
        ) { month in
            let components = calendar.dateComponents(
                [.year],
                from: month.monthStart
            )

            return calendar.date(from: components)
                ?? month.monthStart
        }

        return grouped
            .map { yearStart, months in
                WorkoutYearGroup(
                    yearStart: yearStart,
                    months: months.sorted {
                        $0.monthStart > $1.monthStart
                    }
                )
            }
            .sorted {
                $0.yearStart > $1.yearStart
            }
    }
    
    private func seedInitialYearIfNeeded() {
        guard !didSeedInitialYear,
              let newestYear = groupedYears.first?.yearStart else {
            return
        }

        didSeedInitialYear = true
        expandedYear = newestYear
    }
    
    var body: some View {
        ZStack {
            WarriorBackgroundView()

            VStack(alignment: .leading, spacing: 0) {
                Text("History")
                    .font(.largeTitle.bold())
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                if workouts.isEmpty {
                    emptyState
                } else {
                    workoutHistory
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Recover History", systemImage: "arrow.clockwise.icloud") {
                    showsRecovery = true
                }
            }
        }
        .sheet(isPresented: $showsRecovery) { WorkoutHistoryRecoveryView() }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            seedInitialYearIfNeeded()
        }
        .onChange(of: groupedYears.map(\.yearStart)) { _, _ in
            seedInitialYearIfNeeded()
        }
        .navigationDestination(isPresented: $showsWorkoutTrends) {
            WorkoutTrendsView()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label {
                Text("No Workouts Yet")
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)
            } icon: {
                Image(systemName: "figure.run")
                    .foregroundStyle(themeStore.theme.appAccentTextColor)
            }
        } description: {
            Text("Complete your first NinjaPace workout and your training history will appear here.")
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - History

    private var workoutHistory: some View {
        List {
            Section {
                weeklySummary
            }
            .listRowBackground(themeStore.theme.hudEditorRowBackground)

            Section {
                Button {
                    showsWorkoutTrends = true
                } label: {
                    WorkoutTrendSummaryCard(workouts: workouts)
                }
                .buttonStyle(.plain)
                .tint(themeStore.theme.tint)
                .accessibilityIdentifier("workoutTrendsButton")
            }
            .listRowBackground(themeStore.theme.hudEditorRowBackground)

            ForEach(groupedYears) { year in
                Section {
                    yearHeader(for: year)
                        .listRowBackground(
                            themeStore.theme.hudEditorRowBackground
                        )

                    if expandedYear == year.yearStart {
                        ForEach(year.months) { month in
                            monthHeader(for: month)
                                .padding(.leading, 14)
                                .listRowBackground(
                                    themeStore.theme.hudEditorRowBackground
                                )

                            if expandedMonth == month.monthStart {
                                ForEach(month.workouts) { workout in
                                    NavigationLink {
                                        WorkoutDetailView(
                                            workout: workout
                                        )
                                    } label: {
                                        WorkoutHistoryRow(
                                            workout: workout
                                        )
                                        .padding(.leading, 20)
                                    }
                                    .tint(themeStore.theme.tint)
                                    .listRowBackground(
                                        themeStore.theme
                                            .hudEditorRowBackground
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 20, for: .scrollContent)
        .contentMargins(.bottom, 340, for: .scrollContent)
    }

    // MARK: - Weekly Summary

    private var weeklySummary: some View {
        let calendar = Calendar.current
        let now = Date()
        let weeklyWorkouts = workouts.filter {
            calendar.isDate($0.startedAt, equalTo: now, toGranularity: .weekOfYear)
        }
        let weeklyMiles = weeklyWorkouts.reduce(0) { $0 + $1.completedMiles }
        let completedGoals = weeklyWorkouts.filter(\.wasGoalCompleted).count

        return VStack(alignment: .leading, spacing: 12) {
            Label("This Week", systemImage: "calendar")
                .font(.headline)

            HStack {
                summaryMetric(title: "Workouts", value: "\(weeklyWorkouts.count)")
                Divider()
                summaryMetric(
                    title: "Miles",
                    value: weeklyMiles.formatted(.number.precision(.fractionLength(2)))
                )
                Divider()
                summaryMetric(title: "Goals", value: "\(completedGoals)")
            }
            .frame(height: 46)
        }
        .foregroundStyle(themeStore.theme == .ninja ? themeStore.theme.appPrimaryTextColor : .white)
        .padding(.vertical, 6)
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline)
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func yearHeader(for group: WorkoutYearGroup) -> some View {
        Button {
            withAnimation(
                .easeInOut(duration: 0.24)
            ) {
                toggleYear(group.yearStart)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(themeStore.theme.tint.opacity(0.22))
                        .frame(width: 44, height: 44)
                    
                    Image(
                        systemName: "calendar.badge.clock"
                    )
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(conditionalColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.title)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    
                    Text(group.yearSummaryText)
                        .font(.caption)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: expandedYear == group.yearStart ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                .foregroundStyle(conditionalColor)
                .frame(width: 20)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(group.accessibilityIdentifier)
        .accessibilityValue(expandedYear == group.yearStart ? "Expanded" : "Collapsed")
    }
    
    private func monthHeader(for group: WorkoutMonthGroup) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                toggleMonth(group.monthStart)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(themeStore.theme.tint.opacity(0.15))
                        .frame(width: 38, height: 38)

                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(conditionalColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(group.monthTitle)
                        .font(.headline)
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)

                    Text(group.monthSummaryText)
                        .font(.caption)
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }

                Spacer()

                Text("\(group.workouts.count)")
                    .font(.system(.headline, design: .monospaced))
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)

                Image(systemName: expandedMonth == group.monthStart ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(conditionalColor)
                    .frame(width: 18)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(group.accessibilityIdentifier)
        .accessibilityValue(expandedMonth == group.monthStart ? "Expanded" : "Collapsed")
    }

    private func toggleMonth(_ month: Date) {
        expandedMonth = expandedMonth == month ? nil : month
    }
    
    private func toggleYear(_ year: Date) {
        if expandedYear == year {
            expandedYear = nil
            expandedMonth = nil
        } else {
            expandedYear = year
            expandedMonth = nil
        }
    }
}

private struct WorkoutHistoryRow: View {

    @EnvironmentObject private var themeStore: ThemeStore

    let workout: WorkoutRecord

    var body: some View {
        HStack(spacing: 12) {
            goalIndicator

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .fontWeight(.semibold)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)

                Text("\(formattedMiles) miles • \(formattedDuration)")
                    .font(.footnote)
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }

            Spacer()

            if workout.wasGoalCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }

    private var goalIndicator: some View {
        Image(systemName: workout.wasGoalCompleted ? "figure.run.circle.fill" : "figure.run.circle")
            .font(.title2)
            .foregroundStyle(workout.wasGoalCompleted ? .green : .white)
    }

    private var formattedMiles: String {
        workout.completedMiles.formatted(.number.precision(.fractionLength(2)))
    }

    private var formattedDuration: String {
        Duration.seconds(workout.duration)
            .formatted(.time(pattern: .hourMinuteSecond(padHourToLength: 2)))
    }
}

struct WorkoutMonthGroup: Identifiable {
    let monthStart: Date
    let workouts: [WorkoutRecord]

    var id: Date { monthStart }

    var title: String {
        monthStart.formatted(.dateTime.month(.wide).year())
    }

    var monthTitle: String {
        monthStart.formatted(.dateTime.month(.wide))
    }

    var totalMiles: Double {
        workouts.reduce(0) { $0 + $1.completedMiles }
    }

    var completedGoals: Int {
        workouts.filter(\.wasGoalCompleted).count
    }

    var monthSummaryText: String {
        let miles = totalMiles.formatted(.number.precision(.fractionLength(2)))
        let goalText = completedGoals == 1 ? "1 goal" : "\(completedGoals) goals"
        return "\(miles) mi • \(goalText) completed"
    }
    
    var accessibilityIdentifier: String {
        let components = Calendar.current.dateComponents([.year, .month], from: monthStart)
        return String(format: "historyMonth_%04d-%02d", components.year ?? 0, components.month ?? 0)
    }
}

struct WorkoutYearGroup: Identifiable {
    let yearStart: Date
    let months: [WorkoutMonthGroup]

    var id: Date {
        yearStart
    }

    var title: String {
        yearStart.formatted(.dateTime.year())
    }

    var workoutCount: Int {
        months.reduce(0) { $0 + $1.workouts.count }
    }

    var totalMiles: Double {
        months.reduce(0) { $0 + $1.totalMiles }
    }

    var completedGoals: Int {
        months.reduce(0) { $0 + $1.completedGoals }
    }

    var yearSummaryText: String {
        let miles = totalMiles.formatted(.number.precision(.fractionLength(2)))
        let workoutText = workoutCount == 1 ? "1 workout" : "\(workoutCount) workouts"
        let goalText = completedGoals == 1 ? "1 goal" : "\(completedGoals) goals"
        
        return "\(miles) mi • \(workoutText) • \(goalText)"
    }
    
    var accessibilityIdentifier: String {
        let year = Calendar.current.component(.year, from: yearStart)
        
        return "historyYear_\(year)"
    }
}

#if DEBUG

@MainActor
private struct WorkoutHistoryPreviewHost: View {
    private let container: ModelContainer

    init() {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: WorkoutRecord.self, configurations: configuration)

            let context = container.mainContext
            let calendar = Calendar.current
            let now = Date()

            let sampleWorkouts: [WorkoutRecord] = [
                WorkoutRecord(
                    startedAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                    endedAt: calendar.date(byAdding: .day, value: -1, to: now)?
                        .addingTimeInterval(46 * 60 + 22) ?? now,
                    goalMiles: 3.11,
                    completedMiles: 3.42,
                    steps: 6_384,
                    averageHeartRate: 141,
                    peakHeartRate: 166,
                    activeCalories: 418,
                    totalCalories: 472,
                    averageCadenceSPM: 164,
                    duration: 46 * 60 + 22,
                    averagePaceSecondsPerMile: 13 * 60 + 33,
                    workoutTypeRawValue: "running",
                    workoutLocationRawValue: "indoor",
                    source: "Apple Watch"
                ),
                WorkoutRecord(
                    startedAt: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
                    endedAt: calendar.date(byAdding: .day, value: -4, to: now)?
                        .addingTimeInterval(91 * 60) ?? now,
                    goalMiles: 6.21,
                    completedMiles: 6.30,
                    steps: 11_804,
                    averageHeartRate: 146,
                    peakHeartRate: 171,
                    activeCalories: 801,
                    totalCalories: 884,
                    averageCadenceSPM: 166,
                    duration: 91 * 60,
                    averagePaceSecondsPerMile: 14 * 60 + 26,
                    workoutTypeRawValue: "running",
                    workoutLocationRawValue: "indoor",
                    source: "Apple Watch"
                ),
                WorkoutRecord(
                    startedAt: calendar.date(byAdding: .month, value: -1, to: now) ?? now,
                    endedAt: calendar.date(byAdding: .month, value: -1, to: now)?
                        .addingTimeInterval(2 * 3600 + 48 * 60) ?? now,
                    goalMiles: 13.1,
                    completedMiles: 13.18,
                    steps: 24_331,
                    averageHeartRate: 144,
                    peakHeartRate: 169,
                    activeCalories: 1_412,
                    totalCalories: 1_536,
                    averageCadenceSPM: 163,
                    duration: 2 * 3600 + 48 * 60,
                    averagePaceSecondsPerMile: 12 * 60 + 45,
                    workoutTypeRawValue: "running",
                    workoutLocationRawValue: "indoor",
                    source: "Apple Watch"
                ),
                WorkoutRecord(
                    startedAt: calendar.date(byAdding: .month, value: -2, to: now) ?? now,
                    endedAt: calendar.date(byAdding: .month, value: -2, to: now)?
                        .addingTimeInterval(6 * 3600 + 12 * 60) ?? now,
                    goalMiles: 26.2,
                    completedMiles: 26.24,
                    steps: 48_921,
                    averageHeartRate: 143,
                    peakHeartRate: 172,
                    activeCalories: 2_846,
                    totalCalories: 3_102,
                    averageCadenceSPM: 164,
                    duration: 6 * 3600 + 12 * 60,
                    averagePaceSecondsPerMile: 14 * 60 + 12,
                    workoutTypeRawValue: "running",
                    workoutLocationRawValue: "indoor",
                    source: "Apple Watch"
                )
            ]

            for workout in sampleWorkouts {
                context.insert(workout)
            }

            try context.save()
        } catch {
            fatalError("WorkoutHistory preview failed: \(error)")
        }
    }

    var body: some View {
        NavigationStack {
            WorkoutHistoryView()
        }
        .modelContainer(container)
        .environmentObject(ThemeStore())
    }
}

#Preview("Workout History + Trends") {
    WorkoutHistoryPreviewHost()
}

#endif
