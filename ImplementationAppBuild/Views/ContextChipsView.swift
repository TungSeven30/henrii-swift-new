import SwiftUI

nonisolated enum ChipAction: Sendable {
    case startFeed
    case startSleep
    case logDiaper(DiaperType)
    case logBottle(Double?)
    case logBottleCustom
    case logGrowth
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
        .padding(.vertical, HenriiSpacing.sm)
        .background(HenriiColors.canvasElevated)
        .clipShape(Capsule())
    }

    private var suggestedChips: [ChipData] {
        var chips: [ChipData] = []

        chips.append(ChipData(emoji: "\u{1F931}", label: "Feed", action: .startFeed))

        chips.append(ChipData(emoji: "\u{1F4A4}", label: "Sleep", action: .startSleep))

        chips.append(ChipData(emoji: "\u{1F4A9}", label: "Diaper", action: .logDiaper(.wet), isMenu: true, menuType: .diaper))

        chips.append(ChipData(emoji: "\u{1F37C}", label: "Bottle", action: .logBottle(nil), isMenu: true, menuType: .bottle))

        chips.append(ChipData(emoji: "\u{1F4CF}", label: "Growth", action: .logGrowth))

        return chips
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
