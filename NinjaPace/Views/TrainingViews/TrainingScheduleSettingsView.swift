//
//  TrainingScheduleSettingsView.swift
//  NinjaPace
//
//  Created by Kevin Montemayor on 2/18/26.
//

import SwiftUI

private enum GoalScheduleSection {
    case schedule
    case adjustments
    case templates
}

struct TrainingScheduleSettingsView: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: GoalScheduleStore
    @State private var expandedSection: GoalScheduleSection?
    @State private var selectedDayID: Int?
    @State private var isPreviewCollapsed = false
    private struct Weekday: Identifiable {
        let id: Int  // 1 = Sunday ... 7 = Saturday
        let name: String
    }
    
    private let weekdays: [Weekday] = [
        Weekday(id: 2, name: "Monday"), Weekday(id: 3, name: "Tuesday"), Weekday(id: 4, name: "Wednesday"),
        Weekday(id: 5, name: "Thursday"), Weekday(id: 6, name: "Friday"), Weekday(id: 7, name: "Saturday"),
        Weekday(id: 1, name: "Sunday"),
    ]
    
    private struct WeeklyGoalPreview: View {
        @EnvironmentObject private var themeStore: ThemeStore
        @State private var draggingDayID: Int?
        @State private var dragStartMiles: Double = 0
        @State private var lastAppliedDragMiles: Double?
        private let dragPointsPerStep: CGFloat = 22
        struct Day: Identifiable, Equatable {
            let id: Int
            let name: String
            let miles: Double
            var shortName: String { String(name.prefix(3)) }
            var isRestDay: Bool { miles <= 0.001 }
        }
        let days: [Day]
        let onSelectDay: (Int) -> Void
        let onAdjustDay: (Int, Double) -> Void
        private var totalMiles: Double { days.reduce(0) { $0 + $1.miles } }
        private var averageMiles: Double {
            guard !days.isEmpty else { return 0 }
            return totalMiles / Double(days.count)
        }
        private var maximumMiles: Double { max(days.map(\.miles).max() ?? 0, 0.01) }
        private var longestDay: Day? { days.max { $0.miles < $1.miles } }
        private var currentWeekday: Int { Calendar.current.component(.weekday, from: Date()) }
        
        var body: some View {
            VStack(spacing: 14) {
                summaryRow
                chart
                Label("Press and Hold a Day and Drag to Adjust", systemImage: "hand.draw.fill").font(.subheadline)
                    .bold().lineLimit(2).fixedSize(horizontal: false, vertical: true).foregroundStyle(themeStore.theme.appSecondaryTextColor)
            }
            .animation(.easeInOut(duration: 0.25), value: days)
#if DEBUG
            .onAppear {
                let environment = ProcessInfo.processInfo.environment
                if environment["NINJAPACE_IPHONE_UI_TEST_STATE"] != nil,
                   environment["NINJAPACE_SCREENSHOT_DATA"] == "1",
                   environment["NINJAPACE_SCREENSHOT_SCREEN"] == "schedule" {
                    // Hold the real drag callout for documentation without editing a goal.
                    draggingDayID = 6
                }
            }
#endif
        }
        
        private var summaryRow: some View {
            HStack(spacing: 12) {
                summaryItem(title: "Weekly", value: totalMiles.formatted(.number.precision(.fractionLength(2))) + " mi")
                Divider().overlay(themeStore.theme.appPrimaryTextColor.opacity(0.18)).frame(height: 28)
                summaryItem(title: "Daily Avg", value: averageMiles.formatted(.number.precision(.fractionLength(2))) + " mi")
                Divider().overlay(themeStore.theme.appPrimaryTextColor.opacity(0.18)).frame(height: 28)
                summaryItem(title: "Longest", value: {
                    guard totalMiles > 0.001 else { return "Rest Week" }
                    guard let longestDay else { return "—" }
                    let miles = longestDay.miles.formatted(.number.precision(.fractionLength(2)))
                    return "\(longestDay.shortName) \(miles) mi"}())
            }
            .frame(maxWidth: .infinity)
        }
        
        private func summaryItem(title: String, value: String) -> some View {
            VStack(spacing: 2) {
                Text(title).font(.caption2).foregroundStyle(themeStore.theme.appSecondaryTextColor)
                Text(value).font(.system(.caption, design: .monospaced).weight(.semibold)).foregroundStyle(
                    themeStore.theme.appPrimaryTextColor
                ).lineLimit(1).minimumScaleFactor(0.7)
            }.frame(maxWidth: .infinity)
        }
        
        private var chart: some View {
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let spacing: CGFloat = 7
                let totalSpacing = spacing * CGFloat(max(days.count - 1, 0))
                let barWidth = max(18, (availableWidth - totalSpacing) / CGFloat(max(days.count, 1)))
                HStack(alignment: .bottom, spacing: spacing) { ForEach(days) { day in dayBar(day, width: barWidth) } }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }.frame(height: 220)
        }
        
        private func dayBar(_ day: Day, width: CGFloat) -> some View {
            let isToday = day.id == currentWeekday
            let isRestDay = day.isRestDay
            let normalized = min(max(day.miles / maximumMiles, 0), 1)
            let minimumBarHeight: CGFloat = isRestDay ? 5 : 8
            let barHeight = max(minimumBarHeight, CGFloat(normalized) * 115)
            let mileageText: String
            
            if isRestDay {
                mileageText = "REST"
            } else {
                mileageText = day.miles.formatted(.number.precision(.fractionLength(1)))
            }
            
            let barColor: Color

            if isRestDay {
                barColor = themeStore.theme.appSecondaryTextColor.opacity(0.14)
            } else if isToday {
                barColor = themeStore.theme.tint
            } else {
                barColor = themeStore.theme.tint.opacity(0.58)
            }
            
            let primaryTextColor: Color
            
            if isRestDay {
                primaryTextColor = themeStore.theme.appSecondaryTextColor.opacity(0.72)
            } else if isToday {
                primaryTextColor = themeStore.theme.appPrimaryTextColor
            } else {
                primaryTextColor = themeStore.theme.appSecondaryTextColor
            }
            
            let isDragging = draggingDayID == day.id
            let borderColor: Color
            
            if isDragging {
                borderColor = themeStore.theme.appAccentTextColor
            } else if isToday {
                borderColor = themeStore.theme.tint
            } else {
                borderColor = .clear
            }
            
            let shadowColor: Color
            
            if isDragging {
                shadowColor = themeStore.theme.tint.opacity(0.70)
            } else if isToday && !isRestDay {
                shadowColor = themeStore.theme.tint.opacity(0.50)
            } else {
                shadowColor = .clear
            }
            
            let weekdayWeight: Font.Weight = isToday ? .bold : .medium
            let accessibilityValue: String
            
            if isRestDay {
                accessibilityValue = "Rest day"
            } else {
                accessibilityValue = day.miles.formatted(.number.precision(.fractionLength(2))) + " miles"
            }
            
            return VStack(spacing: 6) {
                Text(mileageText).font(.system(size: 12,
                                               weight: .bold,
                                               design: .monospaced)
                )
                .foregroundStyle(primaryTextColor)
                .lineLimit(1).minimumScaleFactor(0.85)
                .fixedSize(horizontal: true, vertical: false)
                if let snapLabel = snapLabel(for: day.miles) {
                    Text(snapLabel).font(.system(size: 10,
                                                 weight: .bold,
                                                 design: .rounded)
                    )
                    .foregroundStyle(themeStore.theme.appAccentTextColor)
                }
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    barColor,
                                    barColor.opacity(0.65)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: width, height: barHeight)
                        .overlay {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(borderColor, lineWidth: 1.5)
                        }
                        .shadow(color: shadowColor, radius: 6)
                    
                    if isDragging {
                        mileageDragBadge(for: day)
                            .offset(y: -80)
                            .zIndex(100)
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }
                Text(day.shortName).font(.system(size: 10,
                                                 weight: weekdayWeight,
                                                 design: .rounded)
                )
                .foregroundStyle(primaryTextColor)
                todayIndicator(isToday: isToday)
            }
            .frame(width: width, alignment: .bottom).scaleEffect(draggingDayID == day.id ? 1.045 : 1)
            .animation(.snappy(duration: 0.18), value: draggingDayID)
            .onTapGesture { onSelectDay(day.id) }.highPriorityGesture(adjustmentGesture(for: day))
            .accessibilityElement(children: .ignore).accessibilityLabel(day.name).accessibilityValue(accessibilityValue).accessibilityAddTraits(.isButton).accessibilityHint("Opens the weekly schedule controls")
        }
        
        @ViewBuilder private func todayIndicator(isToday: Bool) -> some View {
            if isToday {
                Circle().fill(themeStore.theme.appAccentTextColor).frame(width: 5, height: 5)
            } else {
                Color.clear.frame(width: 5, height: 5)
            }
        }
        
        private func adjustmentGesture(for day: Day) -> some Gesture {
            let longPress = LongPressGesture(minimumDuration: 0.22, maximumDistance: 12)
            let drag = DragGesture(minimumDistance: 0)
            return longPress.sequenced(before: drag).onChanged { value in
                switch value {
                case .first(true):
                    if draggingDayID != day.id {
                        draggingDayID = day.id
                        dragStartMiles = day.miles
                        lastAppliedDragMiles = day.miles
                    }
                case .second(true, let dragValue?):
                    if draggingDayID != day.id {
                        draggingDayID = day.id
                        dragStartMiles = day.miles
                        lastAppliedDragMiles = day.miles
                    }
                    let steps = dragSteps(for: dragValue.translation.height)
                    let adjustedMiles = MileageGoalLadder.adjustedMiles(from: dragStartMiles, steps: steps)
                    let roundedMiles = (adjustedMiles * 100).rounded() / 100
                    guard lastAppliedDragMiles != roundedMiles else { return }
                    lastAppliedDragMiles = roundedMiles
                    onAdjustDay(day.id, roundedMiles)
                default: break
                }
            }.onEnded { _ in
                draggingDayID = nil
                lastAppliedDragMiles = nil
            }
        }
        
        private func dragSteps(for translation: CGFloat) -> Int {
            let magnitude = Int((abs(translation) / dragPointsPerStep).rounded(.down))
            if translation < 0 { return magnitude }
            return -magnitude
        }
        
        private func snapLabel(for miles: Double) -> String? {
            if abs(miles - 3.11) < 0.01 { return "5K" }
            if abs(miles - 6.21) < 0.01 { return "10K" }
            if abs(miles - 13.11) < 0.01 { return "HALF" }
            if abs(miles - 26.22) < 0.01 { return "FULL" }
            return nil
        }
        
        private func mileageDragBadge(for day: Day) -> some View {
            VStack(spacing: 2) {
                Text(
                    day.isRestDay
                        ? "REST"
                        : day.miles.formatted(
                            .number.precision(
                                .fractionLength(2)
                            )
                        ) + " mi"
                )
                .font(.caption.bold())
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                
                if let snapLabel = snapLabel(for: day.miles) {
                    Text(snapLabel)
                        .font(.caption2.bold())
                        .foregroundStyle(themeStore.theme.tint
                        )
                }
            }
            .foregroundStyle(
                themeStore.theme.appPrimaryTextColor
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(
                        themeStore.theme.hudEditorRowBackground
                    )
                    .overlay {
                        Capsule()
                            .stroke(
                                themeStore.theme.tint.opacity(0.8),
                                lineWidth: 1.2
                            )
                    }
            )
            .shadow(
                color: themeStore.theme.tint.opacity(0.30),
                radius: 8
            )
            .allowsHitTesting(false)
        }
    }
    
    private var scheduleForm: some View {
        Form {
            weeklyScheduleSection
            weeklyAdjustmentsSection
            quickTemplatesSection.id("scheduleQuickTemplates")
            resetSection
        }
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 12, for: .scrollContent)
    }

    var body: some View {
        ZStack {
            WarriorBackgroundView()
            VStack(spacing: 0) {
                stickySchedulePreview
#if DEBUG
                ScrollViewReader { proxy in
                    scheduleForm
                        .task(id: expandedSection == .templates) {
                            let environment = ProcessInfo.processInfo.environment
                            guard expandedSection == .templates,
                                  environment["NINJAPACE_IPHONE_UI_TEST_STATE"] != nil,
                                  environment["NINJAPACE_SCREENSHOT_DATA"] == "1",
                                  environment["NINJAPACE_SCREENSHOT_SCREEN"] == "schedule" else { return }
                            await Task.yield()
                            proxy.scrollTo("scheduleQuickTemplates", anchor: .top)
                        }
                }
#else
                scheduleForm
#endif
            }
        }
        .tint(themeStore.theme.tint).navigationTitle("Goal Schedule").navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true).toolbarBackground(.hidden, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Back", systemImage: "chevron.left").foregroundStyle(themeStore.theme.appPrimaryTextColor)
                    }
                }
            }
    }
    
    private var stickySchedulePreview: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Weekly Preview", systemImage: "chart.bar.fill").fontWeight(.semibold).foregroundStyle(themeStore.theme.appPrimaryTextColor)
                Spacer()
                if isPreviewCollapsed {
                    Text(weeklyTotalMiles.formatted(.number.precision(.fractionLength(2))) + " mi").font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold).foregroundStyle(themeStore.theme.appSecondaryTextColor)
                }
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { isPreviewCollapsed.toggle() }
                } label: {
                    Image(systemName: isPreviewCollapsed ? "chevron.down" : "chevron.up").font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(themeStore.theme.appPrimaryTextColor).frame(width: 30, height: 30).contentShape(Rectangle())
                }
                .buttonStyle(.plain).accessibilityLabel(isPreviewCollapsed ? "Expand Weekly Preview" : "Collapse Weekly Preview")
            }
            if !isPreviewCollapsed {
                WeeklyGoalPreview(
                    days: previewDays,
                    onSelectDay: { dayID in
                        withAnimation(.smooth(duration: 0.35)) {
                            selectedDayID = dayID
                            expandedSection = .schedule
                        }
                    },
                    onAdjustDay: { dayID, miles in
                        var schedule = store.schedule
                        schedule.setMiles(miles, for: dayID)
                        store.schedule = schedule
                    }
                )
                .padding(.vertical, 4).transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.985, anchor: .top)), removal: .opacity))
            }
        }
        .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, isPreviewCollapsed ? 10 : 12).overlay(alignment: .bottom)
        { Divider() }
            .zIndex(10).animation(.easeInOut(duration: 0.22), value: isPreviewCollapsed)
    }
    
    private var resetSection: some View {
        Section {
            Button("Reset to Defaults", systemImage: "wand.and.stars", role: .destructive) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    store.schedule = .default
                    expandedSection = .schedule
                }
            }.foregroundStyle(resetButtonColor)
        }.listRowBackground(themeStore.theme.hudEditorRowBackground)
    }
    
    private var previewDays: [WeeklyGoalPreview.Day] {
        weekdays.map { weekday in
            WeeklyGoalPreview.Day(id: weekday.id, name: weekday.name, miles: store.schedule.miles(for: weekday.id))
        }
    }
    
    private var weeklyTotalMiles: Double { previewDays.reduce(0) { $0 + $1.miles } }
    
    private var weeklyScheduleSection: some View {
        Section {
            ThemedDisclosureGroup(isExpanded: expansionBinding(for: .schedule)) {
                collapsibleHeader(title: "Weekly Schedule", systemImage: "calendar")
            } content: {
                VStack(spacing: 12) {
                    ForEach(weekdays) { day in
                        HStack {
                            HStack(spacing: 12) {
                                Text(day.name).foregroundStyle(themeStore.theme.appPrimaryTextColor).fontWeight(
                                    .semibold)
                                Spacer()
                                Image(systemName: "hand.draw.fill").font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(themeStore.theme.appSecondaryTextColor).accessibilityHidden(true)
                            }
                            Spacer()
                            StepperMiles(
                                value: Binding(
                                    get: { store.schedule.miles(for: day.id) },
                                    set: { newMiles in
                                        var schedule = store.schedule
                                        schedule.setMiles(newMiles, for: day.id)
                                        store.schedule = schedule
                                    }), isSelected: selectedDayID == day.id,
                                onSelect: { withAnimation(.snappy(duration: 0.18)) { selectedDayID = day.id } },
                                onPrevLock: {
                                    var schedule = store.schedule
                                    schedule.goToPreviousLock(for: day.id)
                                    store.schedule = schedule
                                },
                                onNextLock: {
                                    var schedule = store.schedule
                                    schedule.goToNextLock(for: day.id)
                                    store.schedule = schedule
                                },
                                onSnapNearest: {
                                    var schedule = store.schedule
                                    schedule.setNearestLock(for: day.id)
                                    store.schedule = schedule
                                },
                                onRest: {
                                    var schedule = store.schedule
                                    schedule.setMiles(0, for: day.id)
                                    store.schedule = schedule
                                })
                        }
                        if day.id != weekdays.last?.id { Divider() }
                    }
                }.padding(.vertical, 6)
            }.foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }.listRowBackground(themeStore.theme.hudEditorRowBackground)
    }
    
    private var weeklyAdjustmentsSection: some View {
        Section {
            ThemedDisclosureGroup(isExpanded: expansionBinding(for: .adjustments)) {
                collapsibleHeader(title: "Weekly Adjustments", systemImage: "slider.horizontal.3")
            } content: {
                VStack(spacing: 10) {
                    Button("+0.5 mi to Mon–Fri") { adjustWeekdays(by: 0.5) }
                    Button("−0.5 mi to Mon–Fri") { adjustWeekdays(by: -0.5) }
                    Button("Snap All Days to Nearest Lock") {
                        var schedule = store.schedule
                        for day in 1...7 { schedule.setNearestLock(for: day) }
                        store.schedule = schedule
                    }
                    Button {
                        setRestDays([2, 3, 4, 5, 6])
                    } label: {
                        Label("Set Mon–Fri as Rest Days", systemImage: "bed.double.fill")
                    }
                    Button {
                        setRestDays([7, 1])
                    } label: {
                        Label("Set Weekend as Rest Days", systemImage: "moon.zzz.fill")
                    }
                    Button {
                        setRestDays(Array(1...7))
                    } label: {
                        Label("Set Entire Week as Rest", systemImage: "calendar.badge.minus")
                    }
                }.buttonStyle(
                    TrainingControlButtonStyle(
                        backgroundColor: themeStore.theme.hudEditorRowBackground,
                        foregroundColor: themeStore.theme.appPrimaryTextColor)
                ).padding(.vertical, 6)
            }.foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }.listRowBackground(themeStore.theme.hudEditorRowBackground)
    }
    
    private func setRestDays(_ dayIDs: [Int]) {
        var schedule = store.schedule
        for dayID in dayIDs { schedule.setMiles(0, for: dayID) }
        store.schedule = schedule
    }
    
    private var quickTemplatesSection: some View {
        Section {
            ThemedDisclosureGroup(isExpanded: expansionBinding(for: .templates)) {
                collapsibleHeader(title: "Quick Templates", systemImage: "apps.iphone.badge.checkmark")
            } content: {
                VStack(spacing: 10) {
                    Button {
                        applyThreeRunDayTemplate()
                    } label: {
                        Label("Mon/Wed/Fri + Saturday Long Run", systemImage: "figure.run")
                    }
                    Button("Standard Week") {
                        var schedule = store.schedule
                        for day in [2, 3, 4, 5, 6] { schedule.setMiles(3.11, for: day) }
                        schedule.setMiles(9.0, for: 7)
                        schedule.setMiles(3.11, for: 1)
                        store.schedule = schedule
                    }
                    Button("5K Daily") { setAllDays(to: 3.10686) }
                    Button("10K Daily") { setAllDays(to: 6.21371) }
                    Button("Half Marathon Saturday") {
                        var schedule = store.schedule
                        schedule.setMiles(13.1094, for: 7)
                        store.schedule = schedule
                    }
                    Button("Full Marathon Saturday") {
                        var schedule = store.schedule
                        schedule.setMiles(26.2188, for: 7)
                        store.schedule = schedule
                    }
                }.buttonStyle(
                    TrainingControlButtonStyle(
                        backgroundColor: themeStore.theme.hudEditorRowBackground,
                        foregroundColor: themeStore.theme.appPrimaryTextColor)
                ).padding(.vertical, 6)
            }.foregroundStyle(themeStore.theme.appPrimaryTextColor)
        }.listRowBackground(themeStore.theme.hudEditorRowBackground)
    }
    
    private func applyThreeRunDayTemplate() {
        var schedule = store.schedule
        // Start by making every day a rest day.
        for dayID in 1...7 { schedule.setMiles(0, for: dayID) }
        schedule.setMiles(3.11, for: 2)  // Monday
        schedule.setMiles(3.11, for: 4)  // Wednesday
        schedule.setMiles(3.11, for: 6)  // Friday
        schedule.setMiles(9.0, for: 7)  // Saturday
        store.schedule = schedule
    }
    
    private func adjustWeekdays(by amount: Double) {
        var schedule = store.schedule
        for day in [2, 3, 4, 5, 6] { schedule.bumpMiles(for: day, step: amount) }
        store.schedule = schedule
    }
    
    private func setAllDays(to miles: Double) {
        var schedule = store.schedule
        for day in 1...7 { schedule.setMiles(miles, for: day) }
        store.schedule = schedule
    }
    
    // MARK: - Helpers
    private func expansionBinding(for section: GoalScheduleSection) -> Binding<Bool> {
        Binding(
            get: { expandedSection == section }, set: { isExpanded in expandedSection = isExpanded ? section : nil })
    }
    
    private func collapsibleHeader(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage).fontWeight(.semibold).foregroundStyle(
            themeStore.theme.appPrimaryTextColor)
    }
    
    private var resetButtonColor: Color {
        switch themeStore.theme {
        case .ninja: return .white
        case .spartan, .pirate, .knight: return .red
        case .viking, .cyborg: return .black
        }
    }
}

/// Small reusable miles stepper widget
private struct StepperMiles: View {
    @EnvironmentObject private var themeStore: ThemeStore
    @Binding var value: Double
    let isSelected: Bool
    let onSelect: () -> Void
    let onPrevLock: () -> Void
    let onNextLock: () -> Void
    let onSnapNearest: () -> Void
    let onRest: () -> Void
    @State private var showingMileageActions = false
    @State private var isDragging = false
    @State private var dragStartMiles: Double = 0
    @State private var lastAppliedMiles: Double?
    @State private var snapFeedbackTrigger = 0
    private let dragPointsPerStep: CGFloat = 22
    private var isHighlighted: Bool { isSelected || isDragging }
    var body: some View {
        HStack(spacing: 10) {
            draggableMileageControl
            Button {
                showingMileageActions = true
            } label: {
                CompactPillIcon(systemName: "scope")
            }.buttonStyle(.borderless).confirmationDialog(
                "Mileage Actions", isPresented: $showingMileageActions, titleVisibility: .visible
            ) {
                Button("Previous Lock") { onPrevLock() }
                Button("Next Lock") { onNextLock() }
                Button("Snap to Nearest Lock") { onSnapNearest() }
                Button("Set as Rest Day", role: .destructive) { onRest() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(value <= 0.001 ? "This day is currently a rest day." : "Current goal: \(formattedMiles)")
            }
        }
        .sensoryFeedback(.selection, trigger: snapFeedbackTrigger)
    }
    
    private var draggableMileageControl: some View {
        HStack(spacing: 4) {
            if value <= 0.001 {
                Image(systemName: "bed.double.fill")
                Text("REST")
            } else {
                Text(formattedMiles)
            }
            Image(systemName: "arrow.up.and.down").font(.system(size: 14, weight: .bold))
        }
        .font(.system(.subheadline, design: .monospaced))
        .fontWeight(.semibold).foregroundStyle(themeStore.theme.appPrimaryTextColor)
        .frame(minWidth: 100, minHeight: 34).padding(.horizontal, 10).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(
                isHighlighted ? themeStore.theme.appAccentTextColor : Color.white.opacity(0.10),
                lineWidth: isHighlighted ? 1.5 : 1)
        }
        .shadow(color: isDragging ? themeStore.theme.appAccentTextColor.opacity(0.45) : isSelected ? themeStore.theme.appAccentTextColor.opacity(0.18) : .clear, radius: isDragging ? 6 : isSelected ? 3 : 0)
        .scaleEffect(isDragging ? 1.045 : 1).animation(.snappy(duration: 0.18), value: isDragging)
        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .gesture(mileageAdjustmentGesture).simultaneousGesture(TapGesture().onEnded { onSelect() })
        .onChange(of: isSelected) { _, newValue in
            guard !newValue else { return }
            isDragging = false
            lastAppliedMiles = nil
        }
        .accessibilityLabel("Mileage goal").accessibilityValue(value <= 0.001 ? "Rest day" : formattedMiles)
        .accessibilityHint("Press and hold, then drag up or down to adjust mileage")
    }
    
    private var mileageAdjustmentGesture: some Gesture {
        let longPress = LongPressGesture(minimumDuration: 0.22, maximumDistance: 12)
        let drag = DragGesture(minimumDistance: 0)
        return longPress.sequenced(before: drag).onChanged { state in
            switch state {
            case .first(true):
                guard !isDragging else { return }
                onSelect()
                isDragging = true
                dragStartMiles = value
                lastAppliedMiles = value
            case .second(true, let dragValue?):
                if !isDragging {
                    onSelect()
                    isDragging = true
                    dragStartMiles = value
                    lastAppliedMiles = value
                }
                let steps = dragSteps(for: dragValue.translation.height)
                let adjustedMiles = MileageGoalLadder.adjustedMiles(from: dragStartMiles, steps: steps)
                let roundedMiles = (adjustedMiles * 100).rounded() / 100
                let didSnap = MileageGoalLadder.isRaceDistance(roundedMiles)
                guard lastAppliedMiles != roundedMiles else { return }
                lastAppliedMiles = roundedMiles
                value = roundedMiles
                if didSnap { snapFeedbackTrigger += 1 }
            default: break
            }
        }.onEnded { _ in
            isDragging = false
            lastAppliedMiles = nil
        }
    }
    
    private func dragSteps(for translation: CGFloat) -> Int {
        let magnitude = Int((abs(translation) / dragPointsPerStep).rounded(.down))
        if translation < 0 { return magnitude }
        return -magnitude
    }
    
    private var formattedMiles: String { value.formatted(.number.precision(.fractionLength(2))) + " mi" }
}

private struct CompactPillIcon: View {
    @EnvironmentObject private var themeStore: ThemeStore
    let systemName: String
    var body: some View {
        Image(systemName: systemName).font(.system(size: 13, weight: .semibold)).foregroundStyle(
            themeStore.theme.appPrimaryTextColor
        ).frame(width: 32, height: 28).background(
            .thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        ).overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(.white.opacity(0.10), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview("Default") {
    let previewStore = GoalScheduleStore()
    let themeStore = ThemeStore()
    return NavigationStack { TrainingScheduleSettingsView(store: previewStore).environmentObject(themeStore) }
}
