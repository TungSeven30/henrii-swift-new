import SwiftUI

nonisolated enum ChipAction: Sendable {
    case startFeed
    case startSleep
    case logDiaper(DiaperType)
    case logBottle(Double?)
    case logBottleCustom
    case logGrowth
    case logBurp
    case logSpitUp
}

struct ContextChipsView: View {
    let baby: Baby
    let events: [BabyEvent]
    let onAction: (ChipAction) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: HenriiSpacing.sm) {
                ForEach(suggestedChips, id: \.label) { chip in
                    if chip.isMenu {
                        chipMenuView(chip)
                    } else {
                        chipButton(chip)
                    }
                }
            }
        }
        .contentMargins(.horizontal, HenriiSpacing.margin)
        .scrollIndicators(.hidden)
        .padding(.bottom, HenriiSpacing.sm)
    }

    private func chipButton(_ chip: ChipData) -> some View {
        Button {
            onAction(chip.action)
        } label: {
            chipLabel(chip)
        }
        .sensoryFeedback(.selection, trigger: chip.label)
    }

    private func chipMenuView(_ chip: ChipData) -> some View {
        Menu {
            if chip.menuType == .diaper {
                Button { onAction(.logDiaper(.wet)) } label: {
                    Label("Wet", systemImage: "drop.fill")
                }
                Button { onAction(.logDiaper(.dirty)) } label: {
                    Label("Dirty", systemImage: "leaf.fill")
                }
                Button { onAction(.logDiaper(.both)) } label: {
                    Label("Wet + Dirty", systemImage: "drop.triangle.fill")
                }
            } else if chip.menuType == .bottle {
                Button { onAction(.logBottle(2)) } label: { Text("2 oz") }
                Button { onAction(.logBottle(3)) } label: { Text("3 oz") }
                Button { onAction(.logBottle(4)) } label: { Text("4 oz") }
                Button { onAction(.logBottle(5)) } label: { Text("5 oz") }
                Button { onAction(.logBottle(6)) } label: { Text("6 oz") }
                Button { onAction(.logBottle(8)) } label: { Text("8 oz") }
                Divider()
                Button { onAction(.logBottleCustom) } label: {
                    Label("Custom amount...", systemImage: "pencil")
                }
                Button { onAction(.logBottle(nil)) } label: {
                    Label("Log without amount", systemImage: "drop.fill")
                }
            }
        } label: {
            chipLabel(chip)
        }
    }

    private func chipLabel(_ chip: ChipData) -> some View {
        HStack(spacing: HenriiSpacing.xs) {
            Text(chip.emoji)
                .font(.henriiCallout)
            Text(chip.label)
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textPrimary)
        }
        .padding(.horizontal, HenriiSpacing.md)
        .frame(height: 40)
        .background(HenriiColors.canvasElevated)
        .clipShape(Capsule())
    }

    private var suggestedChips: [ChipData] {
        let lastEvent = events
            .sorted { $0.timestamp > $1.timestamp }
            .first

        let hoursSinceLastFeed = timeSinceLastEvent(category: .feeding)
        let hoursSinceLastSleep = timeSinceLastSleep()

        if let lastEvent {
            switch lastEvent.category {
            case .feeding:
                return postFeedingChips
            case .sleep where lastEvent.endTime != nil && hoursSinceLastSleep != nil && hoursSinceLastSleep! < 1:
                return postWakeChips
            default:
                break
            }
        }

        if let hrs = hoursSinceLastFeed, hrs >= 3 {
            return hungryChips
        }

        return defaultChips
    }

    private var postFeedingChips: [ChipData] {
        [
            ChipData(emoji: "\u{1F4A8}", label: "Burp", action: .logBurp),
            ChipData(emoji: "\u{1F4A6}", label: "Spit-up", action: .logSpitUp),
            ChipData(emoji: "\u{1F4A9}", label: "Diaper", action: .logDiaper(.wet), isMenu: true, menuType: .diaper),
            ChipData(emoji: "\u{1F4A4}", label: "Sleep", action: .startSleep),
            ChipData(emoji: "\u{1F4CF}", label: "Growth", action: .logGrowth),
        ]
    }

    private var postWakeChips: [ChipData] {
        [
            ChipData(emoji: "\u{1F931}", label: "Start Feed", action: .startFeed),
            ChipData(emoji: "\u{1F37C}", label: "Bottle", action: .logBottle(nil), isMenu: true, menuType: .bottle),
            ChipData(emoji: "\u{1F4A9}", label: "Diaper", action: .logDiaper(.wet), isMenu: true, menuType: .diaper),
            ChipData(emoji: "\u{1F4CF}", label: "Growth", action: .logGrowth),
        ]
    }

    private var hungryChips: [ChipData] {
        [
            ChipData(emoji: "\u{1F931}", label: "Feed", action: .startFeed),
            ChipData(emoji: "\u{1F37C}", label: "Bottle", action: .logBottle(nil), isMenu: true, menuType: .bottle),
            ChipData(emoji: "\u{1F4A9}", label: "Diaper", action: .logDiaper(.wet), isMenu: true, menuType: .diaper),
            ChipData(emoji: "\u{1F4A4}", label: "Sleep", action: .startSleep),
            ChipData(emoji: "\u{1F4CF}", label: "Growth", action: .logGrowth),
        ]
    }

    private var defaultChips: [ChipData] {
        [
            ChipData(emoji: "\u{1F931}", label: "Feed", action: .startFeed),
            ChipData(emoji: "\u{1F4A4}", label: "Sleep", action: .startSleep),
            ChipData(emoji: "\u{1F4A9}", label: "Diaper", action: .logDiaper(.wet), isMenu: true, menuType: .diaper),
            ChipData(emoji: "\u{1F37C}", label: "Bottle", action: .logBottle(nil), isMenu: true, menuType: .bottle),
            ChipData(emoji: "\u{1F4CF}", label: "Growth", action: .logGrowth),
        ]
    }

    private func timeSinceLastEvent(category: EventCategory) -> Double? {
        let matching = events.filter { $0.category == category }
            .sorted { $0.timestamp > $1.timestamp }
        guard let last = matching.first else { return nil }
        return Date().timeIntervalSince(last.timestamp) / 3600
    }

    private func timeSinceLastSleep() -> Double? {
        let sleeps = events.filter { $0.category == .sleep && $0.endTime != nil }
            .sorted { ($0.endTime ?? $0.timestamp) > ($1.endTime ?? $1.timestamp) }
        guard let last = sleeps.first, let endTime = last.endTime else { return nil }
        return Date().timeIntervalSince(endTime) / 3600
    }
}

nonisolated enum ChipMenuType: Sendable {
    case none
    case diaper
    case bottle
}

private struct ChipData: Sendable {
    let emoji: String
    let label: String
    let action: ChipAction
    var isMenu: Bool = false
    var menuType: ChipMenuType = .none
}
