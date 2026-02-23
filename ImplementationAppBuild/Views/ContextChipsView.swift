import SwiftUI

nonisolated enum ChipAction: Sendable {
    case startFeed
    case startSleep
    case logDiaper
    case logBottle
}

struct ContextChipsView: View {
    let baby: Baby
    let events: [BabyEvent]
    let onAction: (ChipAction) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: HenriiSpacing.sm) {
                ForEach(suggestedChips, id: \.label) { chip in
                    Button {
                        onAction(chip.action)
                    } label: {
                        HStack(spacing: HenriiSpacing.xs) {
                            Text(chip.emoji)
                                .font(.henriiCallout)
                            Text(chip.label)
                                .font(.henriiCallout)
                                .foregroundStyle(HenriiColors.textPrimary)
                        }
                        .padding(.horizontal, HenriiSpacing.md)
                        .padding(.vertical, HenriiSpacing.sm)
                        .background(HenriiColors.canvasElevated)
                        .clipShape(Capsule())
                    }
                    .sensoryFeedback(.selection, trigger: chip.label)
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding(.bottom, HenriiSpacing.sm)
    }

    private var suggestedChips: [ChipData] {
        let hour = Calendar.current.component(.hour, from: Date())
        let isNightTime = hour >= 22 || hour < 6

        var chips: [ChipData] = []

        let lastFeed = events.first { $0.category == .feeding }
        let feedInterval = lastFeed.map { Date().timeIntervalSince($0.timestamp) / 3600 }

        if feedInterval == nil || (feedInterval ?? 0) > 2 {
            chips.append(ChipData(emoji: "\u{1F37C}", label: "Start Feed", action: .startFeed))
        }

        if isNightTime || events.first(where: { $0.category == .sleep })?.endTime != nil {
            chips.append(ChipData(emoji: "\u{1F4A4}", label: "Sleep", action: .startSleep))
        }

        chips.append(ChipData(emoji: "\u{1F4A9}", label: "Diaper", action: .logDiaper))

        if chips.count < 3 {
            chips.append(ChipData(emoji: "\u{1F37C}", label: "Bottle", action: .logBottle))
        }

        return chips
    }
}

private struct ChipData: Sendable {
    let emoji: String
    let label: String
    let action: ChipAction
}
