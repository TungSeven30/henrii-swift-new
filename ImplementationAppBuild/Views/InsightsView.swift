import SwiftUI
import SwiftData

struct InsightsView: View {
    let baby: Baby
    @Query(sort: \BabyEvent.timestamp, order: .reverse) private var allEvents: [BabyEvent]

    private var babyEvents: [BabyEvent] {
        allEvents.filter { $0.baby?.id == baby.id }
    }

    private var last7DaysEvents: [BabyEvent] {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return babyEvents.filter { $0.timestamp >= start }
    }

    private var hasEnoughData: Bool { last7DaysEvents.count >= 5 }

    var body: some View {
        ScrollView {
            VStack(spacing: HenriiSpacing.xl) {
                if hasEnoughData {
                    growthChartCard
                    milestoneTrackerCard
                    feedingTrendCard
                    sleepTrendCard
                    diaperSummaryCard
                    weeklySummaryCard
                } else {
                    insufficientDataView
                }
            }
            .padding(.horizontal, HenriiSpacing.margin)
            .padding(.top, HenriiSpacing.lg)
            .padding(.bottom, 100)
        }
        .background(HenriiColors.canvasPrimary)
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.large)
    }

    private var growthChartCard: some View {
        GrowthChartView(baby: baby, growthEvents: babyEvents.filter { $0.category == .growth })
    }

    private var milestoneTrackerCard: some View {
        MilestoneTrackerView(
            baby: baby,
            milestoneCount: babyEvents.filter { $0.category == .milestone }.count
        )
    }

    private var feedingTrendCard: some View {
        let feeds = last7DaysEvents.filter { $0.category == .feeding }
        let dailyCounts = feedsByDay(feeds)

        return InsightCardContainer(
            title: "Feeding Pattern",
            icon: "cup.and.saucer.fill",
            color: HenriiColors.dataFeeding
        ) {
            VStack(alignment: .leading, spacing: HenriiSpacing.md) {
                if !dailyCounts.isEmpty {
                    let avg = dailyCounts.map(\.count).reduce(0, +) / max(dailyCounts.count, 1)
                    Text("Averaging \(avg) feeds per day this week")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)

                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(dailyCounts, id: \.day) { item in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(HenriiColors.dataFeeding)
                                    .frame(width: 28, height: max(8, CGFloat(item.count) * 12))

                                Text(item.dayLabel)
                                    .font(.system(size: 10))
                                    .foregroundStyle(HenriiColors.textTertiary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120, alignment: .bottom)
                }
            }
        }
    }

    private var sleepTrendCard: some View {
        let sleeps = last7DaysEvents.filter { $0.category == .sleep }
        let dailyMinutes = sleepByDay(sleeps)

        return InsightCardContainer(
            title: "Sleep Trends",
            icon: "moon.fill",
            color: HenriiColors.dataSleep
        ) {
            VStack(alignment: .leading, spacing: HenriiSpacing.md) {
                if !dailyMinutes.isEmpty {
                    let totalHours = dailyMinutes.map(\.minutes).reduce(0, +) / 60.0
                    let avgHours = totalHours / Double(max(dailyMinutes.count, 1))
                    Text(String(format: "Averaging %.1f hours per day", avgHours))
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)

                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(dailyMinutes, id: \.day) { item in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(HenriiColors.dataSleep)
                                    .frame(width: 28, height: max(8, CGFloat(item.minutes / 60) * 8))

                                Text(item.dayLabel)
                                    .font(.system(size: 10))
                                    .foregroundStyle(HenriiColors.textTertiary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120, alignment: .bottom)
                }
            }
        }
    }

    private var diaperSummaryCard: some View {
        let diapers = last7DaysEvents.filter { $0.category == .diaper }
        let wet = diapers.filter { $0.diaperType == .wet }.count
        let dirty = diapers.filter { $0.diaperType == .dirty }.count
        let both = diapers.filter { $0.diaperType == .both }.count

        return InsightCardContainer(
            title: "Diaper Log",
            icon: "leaf.fill",
            color: HenriiColors.dataDiaper
        ) {
            HStack(spacing: HenriiSpacing.xl) {
                diaperStat(value: "\(wet)", label: "Wet")
                diaperStat(value: "\(dirty)", label: "Dirty")
                diaperStat(value: "\(both)", label: "Both")
                diaperStat(value: "\(diapers.count)", label: "Total")
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func diaperStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.henriiData(size: 24))
                .foregroundStyle(HenriiColors.textPrimary)
            Text(label)
                .font(.henriiCaption)
                .foregroundStyle(HenriiColors.textTertiary)
        }
    }

    private var weeklySummaryCard: some View {
        let totalFeeds = last7DaysEvents.filter { $0.category == .feeding }.count
        let totalDiapers = last7DaysEvents.filter { $0.category == .diaper }.count
        let totalSleepHrs = last7DaysEvents.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +) / 60

        return InsightCardContainer(
            title: "Weekly Summary",
            icon: "chart.bar.fill",
            color: HenriiColors.accentPrimary
        ) {
            Text("\(baby.name) had \(totalFeeds) feeds, \(totalDiapers) diaper changes, and about \(String(format: "%.0f", totalSleepHrs)) hours of sleep this week.")
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)
        }
    }

    private var insufficientDataView: some View {
        VStack(spacing: HenriiSpacing.xl) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 56))
                .foregroundStyle(HenriiColors.textTertiary)

            Text("Need a few more days")
                .font(.henriiTitle2)
                .foregroundStyle(HenriiColors.textPrimary)

            Text("Keep logging and I'll have insights for you soon. Patterns usually emerge after 3-5 days of data.")
                .font(.henriiBody)
                .foregroundStyle(HenriiColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, HenriiSpacing.xxl)
    }

    private struct DayCount {
        let day: Date
        let dayLabel: String
        let count: Int
    }

    private struct DaySleep {
        let day: Date
        let dayLabel: String
        let minutes: Double
    }

    private func feedsByDay(_ events: [BabyEvent]) -> [DayCount] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        var result: [DayCount] = []
        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let start = calendar.startOfDay(for: day)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            let count = events.filter { $0.timestamp >= start && $0.timestamp < end }.count
            result.append(DayCount(day: start, dayLabel: formatter.string(from: start), count: count))
        }
        return result
    }

    private func sleepByDay(_ events: [BabyEvent]) -> [DaySleep] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        var result: [DaySleep] = []
        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            let start = calendar.startOfDay(for: day)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            let minutes = events.filter { $0.timestamp >= start && $0.timestamp < end }.compactMap(\.durationMinutes).reduce(0, +)
            result.append(DaySleep(day: start, dayLabel: formatter.string(from: start), minutes: minutes))
        }
        return result
    }
}

struct InsightCardContainer<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            HStack(spacing: HenriiSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.textPrimary)
            }
            content
        }
        .padding(HenriiSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HenriiColors.canvasElevated)
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }
}
