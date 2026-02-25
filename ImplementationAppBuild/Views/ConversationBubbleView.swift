import SwiftUI

struct ConversationBubbleView: View {
    @Environment(\.henriiReduceMotion) private var reduceMotion
    let entry: ConversationEntry
    let event: BabyEvent?
    let onDelete: () -> Void
    var onDismissMedical: (() -> Void)?
    var onExpandGroup: (() -> Void)?
    var onEditMilestone: ((BabyEvent) -> Void)?
    @State private var isGroupExpanded: Bool = false

    private var pedButtonLabel: String {
        SettingsManager.shared.pediatricianPhone.isEmpty ? "Add Pediatrician #" : "Call Pediatrician"
    }

    var body: some View {
        Group {
            switch entry.type {
            case .userMessage:
                userBubble
            case .confirmation:
                if event?.category == .milestone {
                    milestoneCard
                } else {
                    confirmationCard
                }
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
            case .medicalFlag:
                medicalFlagCard
            case .dailySummary:
                dailySummaryCard
            case .collapsedGroup:
                collapsedGroupCard
            case .handoffSummary:
                handoffSummaryCard
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
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var milestoneCard: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            HStack(spacing: HenriiSpacing.md) {
                Circle()
                    .fill(HenriiColors.dataGrowth.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay {
                        Image(systemName: "star.fill")
                            .font(.callout)
                            .foregroundStyle(HenriiColors.dataGrowth)
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

            if let event, let photoData = event.milestonePhotoData, let uiImage = UIImage(data: photoData) {
                Color(.secondarySystemBackground)
                    .frame(height: 160)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: HenriiRadius.small))
            }

            if let event, let ctx = event.milestoneContext, !ctx.isEmpty {
                Text(ctx)
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textSecondary)
                    .italic()
            }

            if let event {
                Button {
                    onEditMilestone?(event)
                } label: {
                    HStack(spacing: HenriiSpacing.xs) {
                        Image(systemName: event.milestonePhotoData != nil ? "pencil" : "photo.badge.plus")
                            .font(.caption)
                        Text(event.milestonePhotoData != nil ? "Edit Details" : "Add Photo & Context")
                            .font(.henriiCaption)
                    }
                    .foregroundStyle(HenriiColors.accentPrimary)
                    .padding(.horizontal, HenriiSpacing.md)
                    .frame(height: 32)
                    .background(HenriiColors.accentPrimary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(HenriiSpacing.lg)
        .background(
            LinearGradient(
                colors: [HenriiColors.dataGrowth.opacity(0.08), HenriiColors.canvasElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
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
        .background(HenriiColors.semanticCelebration.opacity(0.06))
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
        .opacity(0.82)
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

    private var medicalFlagCard: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            HStack(spacing: HenriiSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(HenriiColors.semanticAlert)

                Text("Medical Alert")
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.semanticAlert)

                Spacer()
            }

            Text(entry.text)
                .font(.henriiBody)
                .foregroundStyle(HenriiColors.textPrimary)

            HStack(spacing: HenriiSpacing.md) {
                Button {
                    let phone = SettingsManager.shared.pediatricianPhone
                    let cleaned = phone.filter { $0.isNumber || $0 == "+" }
                    if !cleaned.isEmpty, let url = URL(string: "tel://\(cleaned)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label(pedButtonLabel, systemImage: "phone.fill")
                        .font(.henriiCallout)
                        .foregroundStyle(.white)
                        .padding(.horizontal, HenriiSpacing.lg)
                        .frame(height: 44)
                        .background(HenriiColors.semanticAlert)
                        .clipShape(Capsule())
                }
                .disabled(SettingsManager.shared.pediatricianPhone.isEmpty)

                Button {
                    onDismissMedical?()
                } label: {
                    Text("Dismiss")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)
                        .padding(.horizontal, HenriiSpacing.lg)
                        .frame(height: 44)
                }
            }
        }
        .padding(HenriiSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HenriiColors.semanticAlert.opacity(0.1))
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: HenriiRadius.medium)
                .strokeBorder(HenriiColors.semanticAlert.opacity(0.3), lineWidth: 1)
        )
    }

    private var dailySummaryCard: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            HStack(spacing: HenriiSpacing.sm) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.title3)
                    .foregroundStyle(HenriiColors.accentPrimary)

                Text("Daily Summary")
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.textPrimary)

                Spacer()

                Text(entry.timestamp, style: .date)
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
            }

            HStack(spacing: HenriiSpacing.xl) {
                summaryRing(
                    value: Double(entry.summaryFeedCount),
                    maxValue: 10,
                    color: HenriiColors.dataFeeding,
                    icon: "drop.fill",
                    label: "\(entry.summaryFeedCount) feeds"
                )

                summaryRing(
                    value: entry.summarySleepHours,
                    maxValue: 16,
                    color: HenriiColors.dataSleep,
                    icon: "moon.fill",
                    label: String(format: "%.1fh sleep", entry.summarySleepHours)
                )

                summaryRing(
                    value: Double(entry.summaryDiaperCount),
                    maxValue: 12,
                    color: HenriiColors.dataDiaper,
                    icon: "leaf.fill",
                    label: "\(entry.summaryDiaperCount) diapers"
                )
            }
            .frame(maxWidth: .infinity)

            Text(entry.text)
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)
        }
        .padding(HenriiSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }

    private func summaryRing(value: Double, maxValue: Double, color: Color, icon: String, label: String) -> some View {
        VStack(spacing: HenriiSpacing.xs) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 5)
                    .frame(width: 48, height: 48)

                Circle()
                    .trim(from: 0, to: min(value / maxValue, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))

                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
            }

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(HenriiColors.textTertiary)
        }
    }

    private var collapsedGroupCard: some View {
        Button {
            withAnimation(reduceMotion ? .easeInOut(duration: 0.15) : .spring(duration: 0.25)) {
                isGroupExpanded.toggle()
            }
            onExpandGroup?()
        } label: {
            HStack(spacing: HenriiSpacing.md) {
                let count = (entry.groupedEventIDs?.components(separatedBy: ",").count ?? 0)
                Circle()
                    .fill(HenriiColors.accentSecondary.opacity(0.12))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text("\(count)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(HenriiColors.accentSecondary)
                    }

                Text(entry.text)
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textSecondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HenriiColors.textTertiary)
                    .rotationEffect(isGroupExpanded ? .degrees(90) : .zero)
            }
            .padding(.horizontal, HenriiSpacing.lg)
            .padding(.vertical, HenriiSpacing.md)
            .background(HenriiColors.canvasElevated.opacity(0.6))
            .clipShape(.rect(cornerRadius: HenriiRadius.small))
        }
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

    private var handoffSummaryCard: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            HStack(spacing: HenriiSpacing.sm) {
                Image(systemName: "arrow.right.arrow.left.circle.fill")
                    .font(.title3)
                    .foregroundStyle(HenriiColors.accentSecondary)

                Text("Handoff Summary")
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.textPrimary)

                Spacer()

                Text(entry.timestamp, style: .time)
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
            }

            Text(entry.text)
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)

            HStack(spacing: HenriiSpacing.lg) {
                handoffStatPill(
                    icon: "drop.fill",
                    value: "\(entry.handoffFeedCount)",
                    label: "feeds",
                    color: HenriiColors.dataFeeding
                )
                if entry.handoffSleepMinutes > 0 {
                    let hrs = Int(entry.handoffSleepMinutes) / 60
                    let mins = Int(entry.handoffSleepMinutes) % 60
                    let sleepLabel = hrs > 0 ? "\(hrs)h \(mins)m" : "\(mins)m"
                    handoffStatPill(
                        icon: "moon.fill",
                        value: sleepLabel,
                        label: "sleep",
                        color: HenriiColors.dataSleep
                    )
                }
                handoffStatPill(
                    icon: "leaf.fill",
                    value: "\(entry.handoffDiaperCount)",
                    label: "diapers",
                    color: HenriiColors.dataDiaper
                )
            }
        }
        .padding(HenriiSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [HenriiColors.accentSecondary.opacity(0.1), HenriiColors.accentSecondary.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: HenriiRadius.medium)
                .strokeBorder(HenriiColors.accentSecondary.opacity(0.15), lineWidth: 1)
        )
    }

    private func handoffStatPill(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: HenriiSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(HenriiColors.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(HenriiColors.textTertiary)
        }
        .padding(.horizontal, HenriiSpacing.md)
        .padding(.vertical, HenriiSpacing.xs)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
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
