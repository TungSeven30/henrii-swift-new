import SwiftUI
import SwiftData

struct TodayDashboardView: View {
    let baby: Baby
    var onPinchBack: (() -> Void)?
    @Query(sort: \BabyEvent.timestamp, order: .reverse) private var allEvents: [BabyEvent]
    @GestureState private var pinchScale: CGFloat = 1.0
    @Environment(\.henriiReduceMotion) private var reduceMotion

    private var babyEvents: [BabyEvent] {
        allEvents.filter { $0.baby?.id == baby.id }
    }

    private var todayEvents: [BabyEvent] {
        let start = Calendar.current.startOfDay(for: Date())
        return babyEvents.filter { $0.timestamp >= start }.reversed()
    }

    private var feedCount: Int { todayEvents.filter { $0.category == .feeding }.count }
    private var diaperCount: Int { todayEvents.filter { $0.category == .diaper }.count }
    private var totalSleepMinutes: Double {
        todayEvents.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HenriiSpacing.xl) {
                summaryRings
                timelineSection
            }
            .padding(.horizontal, HenriiSpacing.margin)
            .padding(.top, HenriiSpacing.lg)
            .padding(.bottom, 100)
        }
        .background(HenriiColors.canvasPrimary)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
        .scaleEffect(pinchScale < 1.0 ? max(pinchScale, 0.85) : 1.0)
        .opacity(pinchScale < 1.0 ? max(pinchScale, 0.5) : 1.0)
        .gesture(pinchBackGesture)
    }

    private var pinchBackGesture: some Gesture {
        MagnifyGesture()
            .updating($pinchScale) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                if value.magnification < 0.85 {
                    onPinchBack?()
                }
            }
    }

    private var summaryRings: some View {
        HStack(spacing: HenriiSpacing.xl) {
            ringMetric(
                value: "\(feedCount)",
                label: "Feeds",
                color: HenriiColors.dataFeeding,
                progress: min(Double(feedCount) / 8.0, 1.0)
            )
            ringMetric(
                value: formatSleepHours(totalSleepMinutes),
                label: "Sleep",
                color: HenriiColors.dataSleep,
                progress: min(totalSleepMinutes / (14 * 60), 1.0)
            )
            ringMetric(
                value: "\(diaperCount)",
                label: "Diapers",
                color: HenriiColors.dataDiaper,
                progress: min(Double(diaperCount) / 6.0, 1.0)
            )
        }
        .padding(HenriiSpacing.lg)
        .background(HenriiColors.canvasElevated)
        .clipShape(.rect(cornerRadius: HenriiRadius.large))
    }

    private func ringMetric(value: String, label: String, color: Color, progress: Double) -> some View {
        VStack(spacing: HenriiSpacing.sm) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.6), value: progress)

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
                LazyVStack(spacing: 0) {
                    ForEach(todayEvents) { event in
                        timelineRow(event)
                    }
                }
            }
        }
    }

    private func timelineRow(_ event: BabyEvent) -> some View {
        HStack(spacing: HenriiSpacing.md) {
            VStack {
                Text(event.timestamp, format: .dateTime.hour().minute())
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
                    .frame(width: 50, alignment: .trailing)
            }

            Circle()
                .fill(Color(event.categoryColor))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.summaryText)
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textPrimary)
            }

            Spacer()

            if let dur = event.durationMinutes, dur > 0 {
                durationBar(minutes: dur, color: Color(event.categoryColor))
            }
        }
        .padding(.vertical, HenriiSpacing.md)
        .overlay(alignment: .bottom) {
            Divider()
                .padding(.leading, 76)
        }
    }

    private func durationBar(minutes: Double, color: Color) -> some View {
        let width = min(max(minutes / 2, 20), 100)
        return RoundedRectangle(cornerRadius: 4)
            .fill(color.opacity(0.3))
            .frame(width: width, height: 20)
            .overlay {
                Text(String(format: "%.0fm", minutes))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(color)
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
            Text("I'm ready when you are.")
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
}
