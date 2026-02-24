import SwiftUI
import SwiftData

private nonisolated enum DashboardMode: String, CaseIterable, Identifiable, Sendable {
    case day24 = "24h"
    case day12 = "12h"
    case week = "Week"

    var id: String { rawValue }
}

struct TodayDashboardView: View {
    let baby: Baby
    var onPinchBack: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.henriiReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass

    @Query(sort: \BabyEvent.timestamp, order: .reverse) private var allEvents: [BabyEvent]

    @State private var selectedMode: DashboardMode = .day24
    @State private var isLoading: Bool = true
    @State private var currentTime: Date = Date()
    @GestureState private var pinchScale: CGFloat = 1.0

    private let rowHeight: CGFloat = 40

    private var babyEvents: [BabyEvent] {
        allEvents.filter { $0.baby?.id == baby.id }
    }

    private var todayEvents: [BabyEvent] {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()
        return babyEvents
            .filter { $0.timestamp >= start && $0.timestamp < end }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private var feedCount: Int { todayEvents.filter { $0.category == .feeding }.count }
    private var diaperCount: Int { todayEvents.filter { $0.category == .diaper }.count }
    private var totalSleepMinutes: Double {
        todayEvents.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +)
    }

    private var totalHoursForMode: Int {
        selectedMode == .day12 ? 12 : 24
    }

    private var hourRows: [Int] {
        if selectedMode == .day12 {
            return Array(12...23)
        }
        return Array(0...23)
    }

    private var nowHourPosition: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let normalizedHour: CGFloat
        if selectedMode == .day12 {
            let startHour = 12
            normalizedHour = CGFloat(max(hour - startHour, 0)) + CGFloat(minute) / 60
        } else {
            normalizedHour = CGFloat(hour) + CGFloat(minute) / 60
        }
        return normalizedHour * rowHeight
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HenriiSpacing.lg) {
                modePicker
                summaryRings

                if isLoading {
                    loadingSkeleton
                } else if selectedMode == .week {
                    weekSummary
                } else {
                    timelineSection
                }
            }
            .padding(.horizontal, HenriiSpacing.horizontalMargin(for: sizeClass))
            .padding(.top, HenriiSpacing.lg)
            .padding(.bottom, 100)
        }
        .background(HenriiColors.canvasPrimary)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
        .scaleEffect(pinchScale < 1.0 ? max(pinchScale, 0.85) : 1.0)
        .opacity(pinchScale < 1.0 ? max(pinchScale, 0.5) : 1.0)
        .gesture(pinchBackGesture)
        .task {
            if isLoading {
                try? await Task.sleep(for: .milliseconds(280))
                isLoading = false
            }
        }
        .task {
            while true {
                currentTime = Date()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    private var modePicker: some View {
        Picker("Timeline Mode", selection: $selectedMode) {
            ForEach(DashboardMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    private var pinchBackGesture: some Gesture {
        MagnifyGesture()
            .updating($pinchScale) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                if value.magnification < 0.88 {
                    onPinchBack?()
                }
            }
    }

    private var summaryRings: some View {
        HStack(spacing: HenriiSpacing.xl) {
            ringMetric(value: "\(feedCount)", label: "Feeds", color: HenriiColors.dataFeeding, progress: min(Double(feedCount) / 8.0, 1.0))
            ringMetric(value: formatSleepHours(totalSleepMinutes), label: "Sleep", color: HenriiColors.dataSleep, progress: min(totalSleepMinutes / (14 * 60), 1.0))
            ringMetric(value: "\(diaperCount)", label: "Diapers", color: HenriiColors.dataDiaper, progress: min(Double(diaperCount) / 6.0, 1.0))
        }
        .padding(HenriiSpacing.lg)
        .background(HenriiColors.canvasElevated)
        .clipShape(.rect(cornerRadius: HenriiRadius.large))
    }

    private func ringMetric(value: String, label: String, color: Color, progress: Double) -> some View {
        VStack(spacing: HenriiSpacing.sm) {
            ZStack {
                Circle().stroke(color.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.35, bounce: 0.2), value: progress)

                Text(value)
                    .font(.henriiData(size: 20))
                    .foregroundStyle(HenriiColors.textPrimary)
            }
            .frame(width: 64, height: 64)

            Text(label)
                .font(.henriiCaption)
                .foregroundStyle(HenriiColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Timeline")
                .font(.henriiTitle2)
                .foregroundStyle(HenriiColors.textPrimary)

            if todayEvents.isEmpty {
                emptyTimeline
            } else {
                horizontalTimeline
            }
        }
    }

    private var horizontalTimeline: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: HenriiSpacing.md) {
                timeAxis
                ganttCanvas
            }
            .padding(.vertical, HenriiSpacing.md)
        }
        .contentMargins(.horizontal, 0)
        .scrollIndicators(.hidden)
        .background(HenriiColors.canvasElevated)
        .clipShape(.rect(cornerRadius: HenriiRadius.large))
    }

    private var timeAxis: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(hourRows, id: \.self) { hour in
                Text(hourLabel(hour))
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
                    .frame(width: 44, height: rowHeight, alignment: .trailing)
            }
        }
        .padding(.leading, HenriiSpacing.md)
    }

    private var ganttCanvas: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(hourRows, id: \.self) { _ in
                    Rectangle()
                        .fill(HenriiColors.textTertiary.opacity(0.08))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer(minLength: rowHeight - 1)
                }
            }

            Rectangle()
                .fill(HenriiColors.accentPrimary.opacity(0.35))
                .frame(width: 2, height: 4)
                .overlay(alignment: .top) {
                    Circle()
                        .fill(HenriiColors.accentPrimary)
                        .frame(width: 8, height: 8)
                }
                .offset(x: 0, y: nowHourPosition)

            ForEach(todayEvents) { event in
                EventBlockView(event: event, rowHeight: rowHeight, selectedMode: selectedMode)
            }
        }
        .frame(width: 500, height: CGFloat(totalHoursForMode) * rowHeight, alignment: .topLeading)
        .padding(.trailing, HenriiSpacing.lg)
    }

    private var loadingSkeleton: some View {
        VStack(spacing: HenriiSpacing.sm) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: HenriiRadius.small)
                    .fill(HenriiColors.canvasElevated)
                    .frame(height: 20)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: HenriiRadius.small)
                            .fill(HenriiColors.textTertiary.opacity(0.2))
                            .frame(width: CGFloat(80 + index * 20), height: 20)
                    }
            }
        }
    }

    private var weekSummary: some View {
        let grouped = Dictionary(grouping: babyEvents) { Calendar.current.startOfDay(for: $0.timestamp) }
        let last7Days = (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }
        let days = last7Days.sorted()

        return VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            ForEach(days, id: \.self) { day in
                let events = grouped[Calendar.current.startOfDay(for: day)] ?? []
                HStack {
                    Text(day, format: .dateTime.weekday(.abbreviated).month().day())
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textPrimary)
                    Spacer()
                    Text("\(events.count) logs")
                        .font(.henriiCaption)
                        .foregroundStyle(HenriiColors.textSecondary)
                }
                .padding(HenriiSpacing.md)
                .background(HenriiColors.canvasElevated)
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
            }
        }
    }

    private var emptyTimeline: some View {
        VStack(spacing: HenriiSpacing.lg) {
            Image(systemName: "clock.fill")
                .font(.system(size: 40))
                .foregroundStyle(HenriiColors.textTertiary)
            Text("Nothing logged yet today")
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)
            Text("I'm ready when you are")
                .font(.henriiCaption)
                .foregroundStyle(HenriiColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HenriiSpacing.xxl)
    }

    private func formatSleepHours(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }

    private func hourLabel(_ hour: Int) -> String {
        if selectedMode == .day12 {
            let displayHour = hour == 12 ? 12 : hour - 12
            return "\(displayHour) PM"
        }
        return String(format: "%02d:00", hour)
    }
}

private struct EventBlockView: View {
    let event: BabyEvent
    let rowHeight: CGFloat
    let selectedMode: DashboardMode

    @State private var leadingOffset: CGFloat = 0
    @State private var trailingOffset: CGFloat = 0

    private var startY: CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: event.timestamp)
        let minute = calendar.component(.minute, from: event.timestamp)
        let normalizedHour: CGFloat
        if selectedMode == .day12 {
            normalizedHour = CGFloat(max(hour - 12, 0)) + CGFloat(minute) / 60
        } else {
            normalizedHour = CGFloat(hour) + CGFloat(minute) / 60
        }
        return normalizedHour * rowHeight
    }

    private var blockWidth: CGFloat {
        let durationMinutes = max(event.durationMinutes ?? 20, 10)
        return max(72, durationMinutes * 2.2) + trailingOffset - leadingOffset
    }

    var body: some View {
        HStack(spacing: 0) {
            resizeHandle
                .gesture(DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        leadingOffset = min(max(value.translation.width, -40), 40)
                    }
                    .onEnded { _ in
                        applyLeadingChange()
                        leadingOffset = 0
                    }
                )

            HStack(spacing: HenriiSpacing.xs) {
                Image(systemName: event.icon)
                    .font(.caption)
                Text(event.summaryText)
                    .font(.henriiCaption)
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, HenriiSpacing.sm)
            .frame(width: max(56, blockWidth), height: 28, alignment: .leading)
            .background(Color(event.categoryColor))
            .clipShape(.rect(cornerRadius: HenriiRadius.small))

            resizeHandle
                .gesture(DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        trailingOffset = min(max(value.translation.width, -40), 80)
                    }
                    .onEnded { _ in
                        applyTrailingChange()
                        trailingOffset = 0
                    }
                )
        }
        .offset(x: 8, y: startY + 6)
    }

    private var resizeHandle: some View {
        Circle()
            .fill(Color(event.categoryColor).opacity(0.6))
            .frame(width: 12, height: 12)
            .padding(.horizontal, 2)
    }

    private func applyLeadingChange() {
        guard abs(leadingOffset) > 8 else { return }
        let minutesShift = Double(leadingOffset * 0.8)
        event.timestamp = event.timestamp.addingTimeInterval(minutesShift * 60)
        if let duration = event.durationMinutes {
            event.durationMinutes = max(1, duration - minutesShift)
        }
    }

    private func applyTrailingChange() {
        guard abs(trailingOffset) > 8 else { return }
        let minutesShift = Double(trailingOffset * 0.8)
        let currentDuration = event.durationMinutes ?? 20
        event.durationMinutes = max(1, currentDuration + minutesShift)
        event.endTime = event.timestamp.addingTimeInterval((event.durationMinutes ?? 0) * 60)
    }
}
