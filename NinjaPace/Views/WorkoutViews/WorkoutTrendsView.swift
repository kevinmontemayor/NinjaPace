//
//  WorkoutTrendsView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 9/7/26.
//

import Charts
import SwiftData
import SwiftUI

struct WorkoutTrendsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \WorkoutRecord.startedAt, order: .forward) private var workouts: [WorkoutRecord]
    
    @State private var scope: WorkoutTrendScope = .monthly
    @State private var metric: WorkoutTrendMetric = .miles
    @State private var selectedDate: Date?
    @State private var showingMetricPicker = false
    
    private var engine: WorkoutTrendEngine {
        WorkoutTrendEngine(workouts: workouts)
    }
    
    private var allPeriods: [WorkoutTrendPeriod] {
        engine.periods(for: scope)
    }
    
    private var battleRecord: WorkoutBattleRecord {
        engine.battleRecord
    }
    
    private var displayPeriods: [WorkoutTrendPeriod] {
        allPeriods
    }
    
    private var latestPeriod: WorkoutTrendPeriod? {
        displayPeriods.last
    }
    
    private var bestPeriod: WorkoutTrendPeriod? {
        WorkoutTrendMetric.bestPeriod(in: allPeriods, metric: metric)
    }
    
    private var yDomain: ClosedRange<Double> {
        if metric == .goalRate { return 0...100 }
        
        let values = displayPeriods.compactMap { metric.value(for: $0) }
        guard let minimum = values.min(), let maximum = values.max() else { return 0...1 }
        
        if let minimumSpread = metric.minimumLineSpread {
            let spread = max(maximum - minimum, minimumSpread)
            let padding = spread * 0.18
            return max(0, minimum - padding)...(maximum + padding)
        }
        
        return 0...max(1, maximum * 1.15)
    }
    
    private var visibleTrendSpan: TimeInterval {
        switch scope {
        case .monthly:
            return 60 * 60 * 24 * 31 * 6
            
        case .yearly:
            return 60 * 60 * 24 * 366 * 6
        }
    }
    
    private var initialTrendScrollDate: Date {
        guard let latest = allPeriods.last?.startDate else {
            return .now
        }
        
        let component: Calendar.Component = scope == .monthly ? .month : .year
        
        return Calendar.current.date(
            byAdding: component,
            value: -5,
            to: latest
        ) ?? latest
    }
    
    private var selectedPeriod: WorkoutTrendPeriod? {
        guard let selectedDate else { return nil }
        return displayPeriods.min {
            abs($0.startDate.timeIntervalSince(selectedDate)) < abs($1.startDate.timeIntervalSince(selectedDate))
        }
    }
    
    private var focusedPeriod: WorkoutTrendPeriod? {
        selectedPeriod ?? latestPeriod
    }
    
    private var focusedPreviousPeriod: WorkoutTrendPeriod? {
        guard let focusedPeriod,
              let index = displayPeriods.firstIndex(of: focusedPeriod),
              index > displayPeriods.startIndex else {
            return nil
        }
        
        return displayPeriods[displayPeriods.index(before: index)]
    }
    
    var body: some View {
        ZStack {
            WarriorBackgroundView()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    scopePicker
                    trainingIntel
                    metricPicker
                    chartCard
                    periodSummary
                    
                    if let bestPeriod {
                        bestPeriodCard(bestPeriod)
                    }
                    
                    battleRecordCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Workout Trends")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    navigateBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
    }

    private var scopePicker: some View {
        HStack(spacing: 4) {
            ForEach(WorkoutTrendScope.allCases) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        scope = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(
                            scope == option ? Color.white : themeStore.theme.appSecondaryTextColor
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if scope == option {
                                RoundedRectangle(
                                    cornerRadius: 8,
                                    style: .continuous
                                )
                                .fill(themeStore.theme.tint)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.rawValue)
                .accessibilityIdentifier("workoutTrendScope_\(option.rawValue)")
                .accessibilityValue(scope == option ? "Selected" : "Not Selected")
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .fill(themeStore.theme.hudEditorRowBackground)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workoutTrendScopePicker")
    }
    
    @ViewBuilder
    private var trainingIntel: some View {
        if let focusedPeriod {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(themeStore.theme.tint.opacity(0.16))
                        .frame(width: 46, height: 46)

                    Image(systemName: "scope")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(themeStore.theme.tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("TRAINING INTEL")
                        .font(.caption.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(themeStore.theme.tint)

                    Text(intelTitle(for: focusedPeriod))
                        .font(.headline)
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor)

                    Text(intelMessage(for: focusedPeriod))
                        .bold()
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(themeStore.theme.hudEditorRowBackground)
            )
            .accessibilityIdentifier("workoutTrendTrainingIntel")
        }
    }

    private var metricPicker: some View {
        Button {
            showingMetricPicker = true
        } label: {
            HStack(spacing: 12) {
                Label(metric.rawValue, systemImage: metric.systemImage)
                .font(.headline)
                
                Spacer(minLength: 8)
                
                Text(metric.chartSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    .multilineTextAlignment(.trailing)
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.bold())
            }
            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(themeStore.theme.hudEditorRowBackground)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Trend Metric")
        .accessibilityValue(metric.rawValue)
        .accessibilityIdentifier("workoutTrendMetricMenu")
        .sheet(isPresented: $showingMetricPicker) {
            metricSelectionSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    private var metricSelectionSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(WorkoutTrendMetric.allCases) { option in
                        Button {
                            metric = option
                            showingMetricPicker = false
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: option.systemImage)
                                .font(.title3)
                                .foregroundStyle(themeStore.theme.tint)
                                .frame(width: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.rawValue)
                                        .font(.headline)
                                    
                                    Text(option.chartSubtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                                
                                if metric == option {
                                    Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(themeStore.theme.tint)
                                    .font(.title3)
                                }
                            }
                            .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                            .padding(14)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                                .fill(themeStore.theme.hudEditorRowBackground)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("workoutTrendMetric_\(option.rawValue)")
                    }
                }
                .padding()
            }
            .background {
                WarriorBackgroundView()
            }
            .navigationTitle("Trend Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button("Done") {
                        showingMetricPicker = false
                    }
                }
            }
        }
        .tint(themeStore.theme.tint)
    }
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if displayPeriods.isEmpty {
                ContentUnavailableView(
                    "No Trend Data",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Complete a workout and NinjaPace will begin building your trend.")
                )
                .frame(minHeight: 240)
            } else {
                Chart {
                    ForEach(displayPeriods) { period in
                        if let value = metric.value(for: period) {
                            if metric.usesLineChart {
                                AreaMark(
                                    x: .value(scope.periodTitle, period.startDate, unit: scope == .monthly ? .month : .year),
                                    yStart: .value("Baseline", yDomain.lowerBound),
                                    yEnd: .value(metric.rawValue, value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            themeStore.theme.tint.opacity(0.24),
                                            themeStore.theme.tint.opacity(0.02)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                                LineMark(
                                    x: .value(scope.periodTitle, period.startDate, unit: scope == .monthly ? .month : .year),
                                    y: .value(metric.rawValue, value)
                                )
                                .interpolationMethod(.catmullRom)
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                .foregroundStyle(themeStore.theme.tint)

                                PointMark(
                                    x: .value(scope.periodTitle, period.startDate, unit: scope == .monthly ? .month : .year),
                                    y: .value(metric.rawValue, value)
                                )
                                .symbolSize(selectedPeriod?.id == period.id ? 100 : 40)
                                .foregroundStyle(themeStore.theme.tint)
                                .opacity(selectedPeriod == nil || selectedPeriod?.id == period.id ? 1 : 0.42)
                            } else {
                                BarMark(
                                    x: .value(scope.periodTitle, period.startDate, unit: scope == .monthly ? .month : .year),
                                    y: .value(metric.rawValue, value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            themeStore.theme.tint,
                                            themeStore.theme.tint.opacity(0.38)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .opacity(selectedPeriod == nil || selectedPeriod?.id == period.id ? 1 : 0.32)
                                .cornerRadius(4)
                            }
                        }
                    }

                    if let selectedPeriod,
                       metric.value(for: selectedPeriod) != nil {

                        RuleMark(
                            x: .value(
                                scope.periodTitle,
                                selectedPeriod.startDate
                            )
                        )
                        .lineStyle(
                            StrokeStyle(
                                lineWidth: 1,
                                dash: [4, 4]
                            )
                        )
                        .foregroundStyle(
                            themeStore.theme.tint.opacity(0.72)
                        )
                    }
                }
                .chartYScale(domain: yDomain)
                .chartXAxis {
                    AxisMarks(
                        values: .stride(
                            by: scope == .monthly
                                ? .month
                                : .year
                        )
                    ) { value in
                        AxisValueLabel(centered: true) {
                            if let date = value.as(Date.self) {
                                Text(scope.label(for: date))
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(themeStore.theme.appSecondaryTextColor.opacity(0.18))

                        AxisValueLabel {
                            if let number = value.as(Double.self) {
                                Text(metric.axisLabel(number))
                                    .font(.caption2)
                                    .foregroundStyle(.white)
                                    .offset(x: -2, y: -6)
                            }
                        }
                    }
                }
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: visibleTrendSpan)
                .chartScrollPosition(initialX: initialTrendScrollDate)
                .chartXSelection(value: $selectedDate)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        if let selectedPeriod,
                           let selectedValue = metric.value(for: selectedPeriod),
                           let plotFrame = proxy.plotFrame,
                           let xPosition = proxy.position(forX: selectedPeriod.startDate),
                           let yPosition = proxy.position(forY: selectedValue) {
                            let plotRect = geometry[plotFrame]
                            let badgeWidth: CGFloat = 118
                            let badgeHeight: CGFloat = 46
                            let edgeInset: CGFloat = 6
                            let markSpacing: CGFloat = 10
                            let markX = plotRect.minX + xPosition
                            let markY = plotRect.minY + yPosition
                            let minimumX = plotRect.minX + badgeWidth / 2 + edgeInset
                            let maximumX = plotRect.maxX - badgeWidth / 2 - edgeInset
                            let bubbleX = min(max(markX, minimumX), maximumX)
                            let desiredBubbleY = markY - markSpacing - badgeHeight / 2
                            let minimumY = plotRect.minY + badgeHeight / 2 + edgeInset
                            let maximumY = plotRect.maxY - badgeHeight / 2 - edgeInset
                            let bubbleY = min(max(desiredBubbleY, minimumY), maximumY)
                            
                            selectedValueBadge(for: selectedPeriod)
                            .position(x: bubbleX, y: bubbleY)
                            .allowsHitTesting(false)
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: selectedDate)
                .frame(height: 280)
                .accessibilityIdentifier("workoutTrendChart")
                if metric == .pace {
                    Text("Lower pace is faster.")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }
                if metric == .cadence {
                    Text("Higher cadence is faster.")
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }
            }
        }
        .id(scope)
        .onChange(of: scope) {
            selectedDate = nil
        }
        .onChange(of: metric) {
            selectedDate = nil
        }
        .padding(16)
    }
    
    @ViewBuilder
    private var periodSummary: some View {
        if let focusedPeriod {
            VStack(alignment: .leading, spacing: 12) {
                Text(scope.fullLabel(for: focusedPeriod.startDate))
                .font(.headline)
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                
                Text(metric.formattedValue(for: focusedPeriod))
                .font(.system(.title2, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                
                Label(metric.comparisonText(current: focusedPeriod, previous: focusedPreviousPeriod, scope: scope), systemImage: "arrow.left.and.right")
                .font(.subheadline)
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(themeStore.theme.hudEditorRowBackground))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(scope.fullLabel(for: focusedPeriod.startDate)), \(metric.rawValue)")
            .accessibilityValue(metric.formattedValue(for: focusedPeriod))
            .accessibilityHint(metric.comparisonText(current: focusedPeriod, previous: focusedPreviousPeriod, scope: scope))
            .accessibilityIdentifier("workoutTrendLatestSummary")
        }
    }

    private func bestPeriodCard(_ period: WorkoutTrendPeriod) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(themeStore.theme.tint.opacity(0.16))
                    .frame(width: 48, height: 48)

                Image(systemName: "medal.fill")
                    .foregroundStyle(themeStore.theme.tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(metric.bestTitle)
                    .font(.caption)
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)

                Text(scope.fullLabel(for: period.startDate))
                    .font(.headline)
                    .foregroundStyle(themeStore.theme.appPrimaryTextColor)

                Text(metric.formattedValue(for: period))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(themeStore.theme.hudEditorRowBackground)
        )
    }

    private func selectedValueBadge(for period: WorkoutTrendPeriod) -> some View {
        VStack(spacing: 2) {
            Text(metric.formattedValue(for: period))
                .font(.caption.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            
            Text(scope.label(for: period.startDate))
                .font(.caption2)
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
        }
        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(themeStore.theme.hudEditorRowBackground)
                .overlay(
                    Capsule()
                        .stroke(themeStore.theme.tint.opacity(0.7), lineWidth: 1)
                )
        )
        .shadow(color: themeStore.theme.tint.opacity(0.22), radius: 7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(scope.fullLabel(for: period.startDate)), \(metric.formattedValue(for: period))"
        )
    }

    private var battleRecordCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("BATTLE RECORD", systemImage: "shield.fill")
                    .font(.headline)
                    .foregroundStyle(themeStore.theme.tint)

                Spacer()

                Text("LIFETIME")
                    .font(.caption2.bold())
                    .tracking(0.8)
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }

            HStack(spacing: 0) {
                battleRecordMetric(
                    title: "Miles",
                    value: battleRecord.totalMiles.formatted(.number.precision(.fractionLength(2))),
                    systemImage: "road.lanes"
                )

                Divider()
                    .frame(height: 48)

                battleRecordMetric(
                    title: "Workouts",
                    value: battleRecord.workoutCount.formatted(),
                    systemImage: "figure.run"
                )

                Divider()
                    .frame(height: 48)

                battleRecordMetric(
                    title: "Goals",
                    value: battleRecord.completedGoals.formatted(),
                    systemImage: "target"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(themeStore.theme.hudEditorRowBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(themeStore.theme.tint.opacity(0.18), lineWidth: 1)
                )
        )
        .accessibilityIdentifier("workoutBattleRecord")
    }

    private func battleRecordMetric(title: String, value: String, systemImage: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption.bold())
                .foregroundStyle(themeStore.theme.tint)

            Text(value)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundStyle(themeStore.theme.appPrimaryTextColor)
                .minimumScaleFactor(0.72)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundStyle(themeStore.theme.appSecondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(title)")
    }

    private func intelTitle(for period: WorkoutTrendPeriod) -> String {
        if bestPeriod?.id == period.id {
            if latestPeriod?.id == period.id {
                switch metric {
                case .miles: return "NEW MILEAGE HIGH"
                case .workouts: return "MOST ACTIVE"
                case .duration: return "TIME ON TARGET"
                case .steps: return "STEP HIGH"
                case .averageDistance: return "LONGEST AVERAGE"
                case .pace: return "FASTEST"
                case .averageHeartRate: return "PEAK HEART RATE"
                case .calories: return "ENERGY HIGH"
                case .cadence: return "CADENCE HIGH"
                case .goalRate: return "TARGET LOCK"
                }
            }

            return metric.bestTitle.uppercased()
        }

        switch metric.direction(current: period, previous: focusedPreviousPeriod) {
        case .improved:
            switch metric {
            case .miles: return "UPSHIFT"
            case .workouts: return "MORE ACTIVE"
            case .duration: return "MORE TRAINING TIME"
            case .steps: return "STEP VOLUME UP"
            case .averageDistance: return "LONGER SESSIONS"
            case .pace: return "FASTER"
            case .averageHeartRate: return "HEART RATE UP"
            case .calories: return "ENERGY OUTPUT UP"
            case .cadence: return "CADENCE UP"
            case .goalRate: return "TARGET UP"
            }
        case .even:
            return "STEADY"
        case .declined:
            switch metric {
            case .miles: return "LOWER VOLUME"
            case .workouts: return "FEWER SESSIONS"
            case .duration: return "LESS TRAINING TIME"
            case .steps: return "STEP VOLUME DOWN"
            case .averageDistance: return "SHORTER SESSIONS"
            case .pace: return "PACE SLOWED"
            case .averageHeartRate: return "HEART RATE DOWN"
            case .calories: return "ENERGY OUTPUT DOWN"
            case .cadence: return "CADENCE DOWN"
            case .goalRate: return "TARGET RATE DOWN"
            }
        case .unavailable:
            return "BASELINE"
        }
    }

    private func intelMessage(for period: WorkoutTrendPeriod) -> String {
        if bestPeriod?.id == period.id {
            let periodName = scope.periodTitle.lowercased()

            switch metric {
            case .miles:
                return "\(scope.fullLabel(for: period.startDate)) is your highest-mileage \(periodName) in this history."
            case .workouts:
                return "\(scope.fullLabel(for: period.startDate)) has your highest workout count in this history."
            case .duration:
                return "\(scope.fullLabel(for: period.startDate)) has your most active training time in this history."
            case .steps:
                return "\(scope.fullLabel(for: period.startDate)) has your highest recorded step total in this history."
            case .averageDistance:
                return "\(scope.fullLabel(for: period.startDate)) has your longest average workout distance in this history."
            case .pace:
                return "\(scope.fullLabel(for: period.startDate)) has your fastest average pace in this history."
            case .averageHeartRate:
                return "\(scope.fullLabel(for: period.startDate)) has your highest time-weighted average heart rate in this history."
            case .calories:
                return "\(scope.fullLabel(for: period.startDate)) has your highest recorded active-calorie total in this history."
            case .cadence:
                return "\(scope.fullLabel(for: period.startDate)) has your highest time-weighted average cadence in this history."
            case .goalRate:
                return "\(scope.fullLabel(for: period.startDate)) has your highest known-goal completion rate in this history."
            }
        }

        return metric.comparisonText(current: period, previous: focusedPreviousPeriod, scope: scope)
    }
    
    private func navigateBack() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            dismiss()
        }
    }
}

struct WorkoutTrendSummaryCard: View {
    @EnvironmentObject private var themeStore: ThemeStore

    let workouts: [WorkoutRecord]

    private var periods: [WorkoutTrendPeriod] {
        WorkoutTrendEngine(workouts: workouts).recentPeriods(for: .monthly, limit: 6)
    }

    private var latest: WorkoutTrendPeriod? { periods.last }
    private var previous: WorkoutTrendPeriod? { periods.dropLast().last }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Workout Trends", systemImage: "chart.xyaxis.line")
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }
            
            if !periods.isEmpty {
                Chart(periods) { period in
                    BarMark(
                        x: .value("Month", period.startDate, unit: .month),
                        y: .value("Miles", period.totalMiles)
                    )
                    .foregroundStyle(themeStore.theme.tint)
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: periods.map(\.startDate)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.month(.narrow)))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 105)
                .accessibilityIdentifier("workoutTrendPreviewChart")
            }

            if let latest {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(latest.totalMiles.formatted(.number.precision(.fractionLength(2)))) mi")
                        .font(.headline.monospacedDigit())
                    
                    Spacer()
                    
                    Text(
                        WorkoutTrendMetric.miles.comparisonText(
                            current: latest,
                            previous: previous,
                            scope: .monthly
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(themeStore.theme.appSecondaryTextColor)
                    .multilineTextAlignment(.trailing)
                }
            }
        }
        .foregroundStyle(themeStore.theme.appPrimaryTextColor)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

#if DEBUG

@MainActor
private struct WorkoutTrendsPreviewHost: View {
    private let container: ModelContainer

    init() {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: WorkoutRecord.self, configurations: configuration)

            let context = container.mainContext
            let calendar = Calendar.current
            let now = Date()
            let monthlyMiles: [Double] = [22.4, 30.8, 27.6, 38.1, 43.9, 50.2, 47.8, 59.6, 66.3]

            for (monthsAgo, miles) in monthlyMiles.reversed().enumerated() {
                let date = calendar.date(byAdding: .month, value: -monthsAgo, to: now) ?? now
                let trendIndex = Double(monthlyMiles.count - 1 - monthsAgo)
                let firstMiles = miles * 0.42
                let secondMiles = miles * 0.58
                let basePace = 13 * 60 + 50 - trendIndex * 5
                let firstDuration = firstMiles * (basePace + 18)
                let secondDuration = secondMiles * basePace
                let firstGoal = firstMiles * (monthsAgo.isMultiple(of: 3) ? 1.08 : 0.90)
                let secondGoal = secondMiles * 0.92
                let averageHeartRate = 149 - trendIndex * 0.65
                let cadence = 159 + trendIndex * 0.85

                context.insert(
                    WorkoutRecord(
                        startedAt: date,
                        endedAt: date.addingTimeInterval(firstDuration),
                        goalMiles: firstGoal,
                        completedMiles: firstMiles,
                        steps: Int(firstMiles * (1_860 - trendIndex * 4)),
                        averageHeartRate: averageHeartRate + 2,
                        peakHeartRate: averageHeartRate + 24,
                        activeCalories: firstMiles * (114 + trendIndex * 0.7),
                        totalCalories: firstMiles * (128 + trendIndex * 0.7),
                        averageCadenceSPM: cadence - 1,
                        duration: firstDuration,
                        averagePaceSecondsPerMile: firstDuration / firstMiles,
                        workoutTypeRawValue: "running",
                        workoutLocationRawValue: "indoor",
                        source: "Apple Watch"
                    )
                )

                let secondStart = date.addingTimeInterval(86_400 * 6)
                context.insert(
                    WorkoutRecord(
                        startedAt: secondStart,
                        endedAt: secondStart.addingTimeInterval(secondDuration),
                        goalMiles: secondGoal,
                        completedMiles: secondMiles,
                        steps: Int(secondMiles * (1_820 - trendIndex * 3)),
                        averageHeartRate: averageHeartRate,
                        peakHeartRate: averageHeartRate + 22,
                        activeCalories: secondMiles * (118 + trendIndex * 0.9),
                        totalCalories: secondMiles * (132 + trendIndex * 0.9),
                        averageCadenceSPM: cadence + 1,
                        duration: secondDuration,
                        averagePaceSecondsPerMile: secondDuration / secondMiles,
                        workoutTypeRawValue: "running",
                        workoutLocationRawValue: "indoor",
                        source: "Apple Watch"
                    )
                )
            }

            try context.save()
        } catch {
            fatalError("WorkoutTrends preview failed: \(error)")
        }
    }

    var body: some View {
        NavigationStack {
            WorkoutTrendsView()
        }
        .modelContainer(container)
        .environmentObject(ThemeStore())
    }
}

#Preview("Workout Trends") {
    WorkoutTrendsPreviewHost()
}

#endif
