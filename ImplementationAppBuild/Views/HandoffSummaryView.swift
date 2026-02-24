import SwiftUI
import SwiftData

struct HandoffSummaryView: View {
    let baby: Baby
    let events: [BabyEvent]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showShareSheet: Bool = false

    private var recentEvents: [BabyEvent] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
        return events.filter { $0.timestamp >= cutoff }.sorted { $0.timestamp > $1.timestamp }
    }

    private var lastFeed: BabyEvent? {
        recentEvents.first { $0.category == .feeding }
    }

    private var lastSleep: BabyEvent? {
        recentEvents.first { $0.category == .sleep }
    }

    private var lastDiaper: BabyEvent? {
        recentEvents.first { $0.category == .diaper }
    }

    private var lastMedication: BabyEvent? {
        recentEvents.first { $0.category == .health && $0.medicationName != nil }
    }

    private var activeSleep: BabyEvent? {
        recentEvents.first { $0.category == .sleep && $0.endTime == nil }
    }

    private var summaryText: String {
        var lines: [String] = []
        lines.append("Handoff Summary for \(baby.name)")
        lines.append("Generated \(Date().formatted(.dateTime.month().day().hour().minute()))")
        lines.append("")

        if let activeSleep {
            let mins = Int(Date().timeIntervalSince(activeSleep.timestamp) / 60)
            lines.append("Currently sleeping (started \(mins)m ago)")
            lines.append("")
        }

        if let feed = lastFeed {
            let ago = timeSince(feed.timestamp)
            var detail = "Last feed: \(ago) ago"
            if let oz = feed.amountOz { detail += " — \(String(format: "%.1f", oz))oz" }
            if let ft = feed.feedingType { detail += " (\(ft.rawValue))" }
            lines.append(detail)
        } else {
            lines.append("No feeds in the last 12 hours")
        }

        if let sleep = lastSleep, sleep.endTime != nil {
            let ago = timeSince(sleep.endTime ?? sleep.timestamp)
            let dur = sleep.durationMinutes.map { String(format: "%.0f", $0) + "m" } ?? "?"
            lines.append("Last sleep: woke \(ago) ago (slept \(dur))")
        }

        if let diaper = lastDiaper {
            let ago = timeSince(diaper.timestamp)
            let type = diaper.diaperType?.rawValue ?? "change"
            var detail = "Last diaper: \(type) \(ago) ago"
            if let color = diaper.diaperColor { detail += " — \(color)" }
            lines.append(detail)
        }

        if let med = lastMedication {
            let ago = timeSince(med.timestamp)
            var detail = "Last medication: \(med.medicationName ?? "medication") \(ago) ago"
            if let dose = med.medicationDose { detail += " (\(dose))" }
            lines.append(detail)
        }

        let healthFlags = recentEvents.filter { $0.category == .health && $0.temperatureF != nil }
        if let latest = healthFlags.first, let temp = latest.temperatureF, temp >= 100.4 {
            lines.append("")
            lines.append("⚠️ Elevated temperature: \(String(format: "%.1f", temp))°F")
        }

        let notes = recentEvents.filter { $0.category == .note || ($0.notes != nil && !($0.notes?.isEmpty ?? true)) }
        if !notes.isEmpty {
            lines.append("")
            lines.append("Notes:")
            for note in notes.prefix(3) {
                lines.append("• \(note.notes ?? note.summaryText)")
            }
        }

        return lines.joined(separator: "\n")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HenriiSpacing.xl) {
                headerSection
                statusCardsSection
                if lastMedication != nil { medicationSection }
                recentActivitySection
            }
            .padding(.horizontal, HenriiSpacing.horizontalMargin(for: sizeClass))
            .padding(.top, HenriiSpacing.lg)
            .padding(.bottom, 100)
        }
        .background(HenriiColors.canvasPrimary)
        .navigationTitle("Handoff Summary")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: summaryText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(HenriiColors.accentPrimary)
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(HenriiColors.textTertiary)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.sm) {
            if let activeSleep {
                let mins = Int(Date().timeIntervalSince(activeSleep.timestamp) / 60)
                HStack(spacing: HenriiSpacing.sm) {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(HenriiColors.dataSleep)
                    Text("\(baby.name) is currently sleeping (\(mins)m)")
                        .font(.henriiHeadline)
                        .foregroundStyle(HenriiColors.textPrimary)
                }
                .padding(HenriiSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HenriiColors.dataSleep.opacity(0.1))
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
            }

            Text("Last 12 hours at a glance")
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)
        }
    }

    private var statusCardsSection: some View {
        VStack(spacing: HenriiSpacing.md) {
            HStack(spacing: HenriiSpacing.md) {
                handoffCard(
                    icon: "drop.fill",
                    color: HenriiColors.dataFeeding,
                    title: "Last Feed",
                    detail: lastFeed.map { feedDetail($0) } ?? "No feeds",
                    time: lastFeed.map { timeSince($0.timestamp) + " ago" } ?? "--"
                )
                handoffCard(
                    icon: "moon.fill",
                    color: HenriiColors.dataSleep,
                    title: "Last Sleep",
                    detail: lastSleep.map { sleepDetail($0) } ?? "No sleep",
                    time: lastSleep.map { timeSince($0.endTime ?? $0.timestamp) + " ago" } ?? "--"
                )
            }
            HStack(spacing: HenriiSpacing.md) {
                handoffCard(
                    icon: "leaf.fill",
                    color: HenriiColors.dataDiaper,
                    title: "Last Diaper",
                    detail: lastDiaper.map { diaperDetail($0) } ?? "No changes",
                    time: lastDiaper.map { timeSince($0.timestamp) + " ago" } ?? "--"
                )
                let feedCount = recentEvents.filter { $0.category == .feeding }.count
                let diaperCount = recentEvents.filter { $0.category == .diaper }.count
                handoffCard(
                    icon: "chart.bar.fill",
                    color: HenriiColors.accentPrimary,
                    title: "12h Totals",
                    detail: "\(feedCount) feeds, \(diaperCount) diapers",
                    time: ""
                )
            }
        }
    }

    private var medicationSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Medication")
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)

            if let med = lastMedication {
                HStack(spacing: HenriiSpacing.md) {
                    Image(systemName: "pills.fill")
                        .font(.title3)
                        .foregroundStyle(HenriiColors.semanticAlert)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(med.medicationName ?? "Medication")
                            .font(.henriiHeadline)
                            .foregroundStyle(HenriiColors.textPrimary)
                        HStack(spacing: HenriiSpacing.xs) {
                            if let dose = med.medicationDose {
                                Text(dose)
                                    .font(.henriiCallout)
                                    .foregroundStyle(HenriiColors.textSecondary)
                            }
                            Text(timeSince(med.timestamp) + " ago")
                                .font(.henriiCaption)
                                .foregroundStyle(HenriiColors.textTertiary)
                        }
                    }
                    Spacer()
                }
                .padding(HenriiSpacing.lg)
                .background(HenriiColors.semanticAlert.opacity(0.08))
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Recent Activity")
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)

            ForEach(recentEvents.prefix(8)) { event in
                HStack(spacing: HenriiSpacing.md) {
                    Circle()
                        .fill(Color(event.categoryColor))
                        .frame(width: 8, height: 8)

                    Text(event.summaryText)
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textPrimary)

                    Spacer()

                    Text(event.timestamp, format: .dateTime.hour().minute())
                        .font(.henriiCaption)
                        .foregroundStyle(HenriiColors.textTertiary)
                }
                .padding(.vertical, HenriiSpacing.xs)
            }

            if recentEvents.isEmpty {
                Text("No activity in the last 12 hours.")
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HenriiSpacing.xl)
            }
        }
    }

    private func handoffCard(icon: String, color: Color, title: String, detail: String, time: String) -> some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.sm) {
            HStack(spacing: HenriiSpacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
            }
            Text(detail)
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textPrimary)
                .lineLimit(2)
            if !time.isEmpty {
                Text(time)
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HenriiSpacing.lg)
        .background(HenriiColors.canvasElevated)
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }

    private func feedDetail(_ event: BabyEvent) -> String {
        var parts: [String] = []
        if let ft = event.feedingType {
            switch ft {
            case .breastLeft: parts.append("Left breast")
            case .breastRight: parts.append("Right breast")
            case .breastBoth: parts.append("Both sides")
            case .bottle: parts.append("Bottle")
            case .solids: parts.append("Solids")
            case .combo: parts.append("Combo")
            }
        }
        if let oz = event.amountOz { parts.append(String(format: "%.1foz", oz)) }
        if let dur = event.durationMinutes { parts.append(String(format: "%.0fm", dur)) }
        return parts.isEmpty ? "Fed" : parts.joined(separator: " · ")
    }

    private func sleepDetail(_ event: BabyEvent) -> String {
        if event.endTime == nil { return "Currently sleeping" }
        if let dur = event.durationMinutes {
            let h = Int(dur) / 60
            let m = Int(dur) % 60
            return h > 0 ? "Slept \(h)h \(m)m" : "Slept \(m)m"
        }
        return "Sleep ended"
    }

    private func diaperDetail(_ event: BabyEvent) -> String {
        var base: String
        switch event.diaperType {
        case .wet: base = "Wet"
        case .dirty: base = "Dirty"
        case .both: base = "Wet + dirty"
        case nil: base = "Changed"
        }
        if let color = event.diaperColor { base += " · \(color)" }
        return base
    }

    private func timeSince(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let remainingMins = minutes % 60
        if remainingMins == 0 { return "\(hours)h" }
        return "\(hours)h \(remainingMins)m"
    }
}
