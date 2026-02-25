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
        let defaults = UserDefaults.standard
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
            Label("Last feed", systemImage: "drop.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.lastFeedText)
                .font(.headline)
                .lineLimit(2)
            Spacer()
            Text(entry.timerText)
                .font(.system(.title3, design: .monospaced).weight(.semibold))
        }
    }

    private var mediumView: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.lastFeedText)
                    .font(.headline)
                Text(entry.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Spacer()
                Text(entry.timerText)
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                metricRow(icon: "drop.fill", title: "Feeds", value: "\(entry.feedCount)")
                metricRow(icon: "moon.fill", title: "Sleep", value: String(format: "%.1fh", entry.sleepHours))
                metricRow(icon: "leaf.fill", title: "Diapers", value: "\(entry.diaperCount)")
            }
        }
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today at a glance")
                .font(.headline)
            Text(entry.statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            metricRow(icon: "drop.fill", title: "Last feed", value: entry.lastFeedText)
            metricRow(icon: "timer", title: "Active timer", value: entry.timerText)
            metricRow(icon: "chart.bar.fill", title: "Feeds", value: "\(entry.feedCount)")
            metricRow(icon: "moon.fill", title: "Sleep", value: String(format: "%.1f hours", entry.sleepHours))
            metricRow(icon: "leaf.fill", title: "Diapers", value: "\(entry.diaperCount)")
            Spacer(minLength: 0)
        }
    }

    private func metricRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
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
            VStack(alignment: .leading, spacing: 10) {
                Text(context.attributes.babyName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(context.state.categoryRawValue == "sleep" ? "Sleep Timer" : "Feed Timer")
                    .font(.headline)
                Text(formatDuration(context.state.elapsedSeconds))
                    .font(.system(.title2, design: .monospaced).weight(.bold))
                Text(context.state.isPaused ? "Paused" : "Running")
                    .font(.caption)
                    .foregroundStyle(context.state.isPaused ? .secondary : .primary)
            }
            .padding(.vertical, 4)
            .activityBackgroundTint(.black.opacity(0.15))
            .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.categoryRawValue == "sleep" ? "moon.fill" : "drop.fill")
                        .foregroundStyle(.tint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(formatDuration(context.state.elapsedSeconds))
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.isPaused ? "Paused" : "Running")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Image(systemName: context.state.categoryRawValue == "sleep" ? "moon.fill" : "drop.fill")
            } compactTrailing: {
                Text(shortDuration(context.state.elapsedSeconds))
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
            } minimal: {
                Image(systemName: context.state.categoryRawValue == "sleep" ? "moon.fill" : "drop.fill")
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
