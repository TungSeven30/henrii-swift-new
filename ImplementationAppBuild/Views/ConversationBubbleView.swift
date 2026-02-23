import SwiftUI

struct ConversationBubbleView: View {
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
