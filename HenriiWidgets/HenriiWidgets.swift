import WidgetKit
import SwiftUI
import ActivityKit

nonisolated struct HenriiTimerActivityAttributes: ActivityAttributes, Sendable {
    public nonisolated struct ContentState: Codable, Hashable, Sendable {
        let elapsedSeconds: Int
        let categoryRawValue: String
        let isPaused: Bool
        let sideRawValue: String
    }

    let babyName: String
}

nonisolated struct HenriiWidgetEntry: TimelineEntry {
    let date: Date
    let lastFeedText: String
    let statusText: String
    let feedCount: Int
    let sleepHours: Double
    let diaperCount: Int
    let timerText: String
}

nonisolated struct HenriiWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HenriiWidgetEntry {
        HenriiWidgetEntry(
            date: .now,
            lastFeedText: "Last feed 1h ago",
            statusText: "Everything looks steady",
            feedCount: 6,
            sleepHours: 11.5,
            diaperCount: 5,
            timerText: "00:14:22"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HenriiWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HenriiWidgetEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> HenriiWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.app.rork.henrii") ?? .standard
        return HenriiWidgetEntry(
            date: .now,
            lastFeedText: defaults.string(forKey: "widgetLastFeedText") ?? "Last feed unavailable",
            statusText: defaults.string(forKey: "widgetStatusText") ?? "Open Henrii to refresh latest stats",
            feedCount: defaults.integer(forKey: "widgetFeedCount"),
            sleepHours: defaults.double(forKey: "widgetSleepHours"),
            diaperCount: defaults.integer(forKey: "widgetDiaperCount"),
            timerText: defaults.string(forKey: "widgetTimerText") ?? "--:--"
        )
    }
}

struct HenriiWidgets: Widget {
    private let kind: String = "HenriiWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HenriiWidgetProvider()) { entry in
            HenriiWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Henrii Snapshot")
        .description("Last feed, daily totals, and active timer state.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct HenriiWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HenriiWidgetEntry

    private let terracotta = Color(red: 0.851, green: 0.424, blue: 0.322)
    private let feedingAmber = Color(red: 0.890, green: 0.655, blue: 0.478)
    private let sleepSlate = Color(red: 0.420, green: 0.478, blue: 0.561)
    private let diaperSage = Color(red: 0.545, green: 0.604, blue: 0.518)

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            largeView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.caption2)
                    .foregroundStyle(feedingAmber)
                Text("Last feed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(entry.lastFeedText)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
            Spacer()
            Text(entry.timerText)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
                .foregroundStyle(terracotta)
        }
    }

    private var mediumView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.lastFeedText)
                    .font(.system(.headline, design: .rounded))
                Text(entry.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Spacer()
                Text(entry.timerText)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .foregroundStyle(terracotta)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                metricRow(icon: "drop.fill", title: "Feeds", value: "\(entry.feedCount)", color: feedingAmber)
                metricRow(icon: "moon.fill", title: "Sleep", value: String(format: "%.1fh", entry.sleepHours), color: sleepSlate)
                metricRow(icon: "leaf.fill", title: "Diapers", value: "\(entry.diaperCount)", color: diaperSage)
            }
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today at a glance")
                .font(.system(.headline, design: .rounded))
            Text(entry.statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            metricRow(icon: "drop.fill", title: "Last feed", value: entry.lastFeedText, color: feedingAmber)
            metricRow(icon: "timer", title: "Active timer", value: entry.timerText, color: terracotta)
            metricRow(icon: "chart.bar.fill", title: "Feeds", value: "\(entry.feedCount)", color: feedingAmber)
            metricRow(icon: "moon.fill", title: "Sleep", value: String(format: "%.1f hours", entry.sleepHours), color: sleepSlate)
            metricRow(icon: "leaf.fill", title: "Diapers", value: "\(entry.diaperCount)", color: diaperSage)
            Spacer(minLength: 0)
        }
    }

    private func metricRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 6)
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.caption)
    }
}

nonisolated struct HenriiTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HenriiTimerActivityAttributes.self) { context in
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.categoryRawValue == "sleep" ? "moon.fill" : "drop.fill")
                            .font(.caption)
                            .foregroundStyle(context.state.categoryRawValue == "sleep" ? .indigo : .orange)
                        Text(context.attributes.babyName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(context.state.categoryRawValue == "sleep" ? "Sleep Timer" : "Feed Timer")
                        .font(.headline)
                    Text(formatDuration(context.state.elapsedSeconds))
                        .font(.system(.title, design: .monospaced).weight(.bold))
                        .contentTransition(.numericText())
                    Text(context.state.isPaused ? "Paused" : "Running")
                        .font(.caption2)
                        .foregroundStyle(context.state.isPaused ? .orange : .green)
                }

                Spacer()

                if context.state.categoryRawValue == "feeding" && !context.state.sideRawValue.isEmpty {
                    VStack(spacing: 4) {
                        Text(context.state.sideRawValue == "breastLeft" ? "L" : "R")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.white.opacity(0.15)))
                        Text("Side")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .activityBackgroundTint(.black.opacity(0.6))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: context.state.categoryRawValue == "sleep" ? "moon.fill" : "drop.fill")
                            .font(.title3)
                            .foregroundStyle(context.state.categoryRawValue == "sleep" ? .indigo : .orange)
                        Text(context.attributes.babyName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatDuration(context.state.elapsedSeconds))
                            .font(.system(.title3, design: .monospaced).weight(.bold))
                            .contentTransition(.numericText())
                        Text(context.state.isPaused ? "Paused" : "Running")
                            .font(.caption2)
                            .foregroundStyle(context.state.isPaused ? .orange : .green)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        if context.state.categoryRawValue == "feeding" {
                            Text(context.state.sideRawValue == "breastLeft" ? "Left side" : "Right side")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(context.state.categoryRawValue == "sleep" ? "Sleep" : "Feed")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.1), in: Capsule())
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.categoryRawValue == "sleep" ? "moon.fill" : "drop.fill")
                    .foregroundStyle(context.state.categoryRawValue == "sleep" ? .indigo : .orange)
            } compactTrailing: {
                Text(shortDuration(context.state.elapsedSeconds))
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
                    .contentTransition(.numericText())
            } minimal: {
                Image(systemName: context.state.categoryRawValue == "sleep" ? "moon.fill" : "drop.fill")
                    .foregroundStyle(context.state.categoryRawValue == "sleep" ? .indigo : .orange)
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainder = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainder)
        }
        return String(format: "%02d:%02d", minutes, remainder)
    }

    private func shortDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }
}
