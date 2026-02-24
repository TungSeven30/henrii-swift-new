import SwiftUI

struct ConversationBubbleView: View {
    @Environment(\.henriiReduceMotion) private var reduceMotion
    let entry: ConversationEntry
    let event: BabyEvent?
    let onDelete: () -> Void

    var body: some View {
        Group {
            switch entry.type {
            case .userMessage:
                userBubble
            case .confirmation:
                confirmationCard
            case .insight:
                insightCard
            case .nudge:
                nudgeCard
            case .celebration:
                celebrationCard
            case .system:
                systemBubble
            case .daySeparator:
                daySeparator
            case .queryResponse:
                queryResponseCard
            }
        }
    }

    private var userBubble: some View {
        HStack {
            Spacer()
            Text(entry.text)
                .font(.henriiBody)
                .foregroundStyle(.white)
                .padding(.horizontal, HenriiSpacing.lg)
                .padding(.vertical, HenriiSpacing.md)
                .background(HenriiColors.accentPrimary)
                .clipShape(.rect(cornerRadius: 20, style: .continuous))
        }
    }

    private var confirmationCard: some View {
        HStack(spacing: HenriiSpacing.md) {
            if let event {
                Circle()
                    .fill(Color(event.categoryColor).opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: event.icon)
                            .font(.callout)
                            .foregroundStyle(Color(event.categoryColor))
                    }
            }

            VStack(alignment: .leading, spacing: HenriiSpacing.xs) {
                Text(entry.text)
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.textPrimary)
                Text(entry.timestamp, style: .time)
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(HenriiColors.dataGrowth)
                .font(.title3)
        }
        .padding(HenriiSpacing.lg)
        .background(HenriiColors.canvasElevated)
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var insightCard: some View {
        HStack(spacing: HenriiSpacing.md) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(HenriiColors.semanticCelebration)

            Text(entry.text)
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textPrimary)
        }
        .padding(HenriiSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HenriiColors.semanticCelebration.opacity(0.08))
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }

    private var nudgeCard: some View {
        HStack(spacing: HenriiSpacing.md) {
            Image(systemName: "bell.fill")
                .font(.callout)
                .foregroundStyle(HenriiColors.accentSecondary)

            Text(entry.text)
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)
        }
        .padding(HenriiSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HenriiColors.canvasElevated.opacity(0.5))
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }

    private var celebrationCard: some View {
        HStack(spacing: HenriiSpacing.md) {
            Image(systemName: "party.popper")
                .font(.title2)
                .foregroundStyle(HenriiColors.semanticCelebration)

            Text(entry.text)
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)
        }
        .padding(HenriiSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [HenriiColors.semanticCelebration.opacity(0.12), HenriiColors.semanticCelebration.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }

    private var systemBubble: some View {
        HStack {
            Text(entry.text)
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(.horizontal, HenriiSpacing.sm)
    }

    private var queryResponseCard: some View {
        let dataPoints = parseChartData(entry.chartData)
        let topicColor = colorForTopic(entry.queryTopicRaw)
        let topicIcon = iconForTopic(entry.queryTopicRaw)

        return VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            HStack(spacing: HenriiSpacing.sm) {
                Image(systemName: topicIcon)
                    .font(.callout)
                    .foregroundStyle(topicColor)
                Text(entry.text)
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textPrimary)
            }

            if !dataPoints.isEmpty {
                chartView(dataPoints: dataPoints, color: topicColor)
                    .frame(height: 100)
                    .padding(.top, HenriiSpacing.xs)
            }
        }
        .padding(HenriiSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(topicColor.opacity(0.08))
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }

    private func chartView(dataPoints: [(label: String, value: Double)], color: Color) -> some View {
        let maxVal = dataPoints.map(\.value).max() ?? 1

        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { _, point in
                VStack(spacing: 4) {
                    Text(formatChartValue(point.value, topic: entry.queryTopicRaw))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(HenriiColors.textTertiary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 28, height: max(8, CGFloat(point.value / maxVal) * 64))

                    Text(point.label)
                        .font(.system(size: 10))
                        .foregroundStyle(HenriiColors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func parseChartData(_ raw: String?) -> [(label: String, value: Double)] {
        guard let raw, !raw.isEmpty else { return [] }
        return raw.components(separatedBy: "|").compactMap { pair in
            let parts = pair.components(separatedBy: ":")
            guard parts.count == 2, let val = Double(parts[1]) else { return nil }
            return (label: parts[0], value: val)
        }
    }

    private func formatChartValue(_ value: Double, topic: String?) -> String {
        switch topic {
        case "weight": return String(format: "%.1f", value)
        case "feeding": return "\(Int(value))"
        case "sleep": return String(format: "%.1f", value / 60)
        case "diaper": return "\(Int(value))"
        default: return String(format: "%.0f", value)
        }
    }

    private func colorForTopic(_ topic: String?) -> Color {
        switch topic {
        case "weight", "growth": return HenriiColors.dataGrowth
        case "feeding": return HenriiColors.dataFeeding
        case "sleep": return HenriiColors.dataSleep
        case "diaper": return HenriiColors.dataDiaper
        case "health": return HenriiColors.semanticAlert
        default: return HenriiColors.accentPrimary
        }
    }

    private func iconForTopic(_ topic: String?) -> String {
        switch topic {
        case "weight", "growth": return "chart.line.uptrend.xyaxis"
        case "feeding": return "drop.fill"
        case "sleep": return "moon.fill"
        case "diaper": return "leaf.fill"
        case "health": return "heart.text.clipboard.fill"
        default: return "chart.bar.fill"
        }
    }

    private var daySeparator: some View {
        HStack {
            VStack { Divider() }
            Text(entry.text)
                .font(.henriiCaption)
                .foregroundStyle(HenriiColors.textTertiary)
            VStack { Divider() }
        }
        .padding(.vertical, HenriiSpacing.sm)
    }
}
