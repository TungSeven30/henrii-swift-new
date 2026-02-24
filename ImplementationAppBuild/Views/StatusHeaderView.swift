import SwiftUI

struct StatusHeaderView: View {
    let baby: Baby
    var babies: [Baby] = []
    let events: [BabyEvent]
    let onTapStatus: () -> Void
    let onTapInsights: () -> Void
    let onTapAvatar: () -> Void
    var onTapSearch: (() -> Void)?
    var onSwitchBaby: ((Baby) -> Void)?

    var body: some View {
        VStack(spacing: HenriiSpacing.xs) {
            HStack(spacing: HenriiSpacing.sm) {
                if babies.count > 1 {
                    babySwitcherMenu
                }

                Button { onTapStatus() } label: {
                    HStack(spacing: HenriiSpacing.lg) {
                        statusPill(icon: "drop.fill", time: timeSince(.feeding), color: HenriiColors.dataFeeding)
                        statusPill(icon: "moon.fill", time: timeSince(.sleep), color: HenriiColors.dataSleep)
                        statusPill(icon: "leaf.fill", time: timeSince(.diaper), color: HenriiColors.dataDiaper)
                    }
                }

                Spacer()

                if let onTapSearch {
                    Button { onTapSearch() } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.callout)
                            .foregroundStyle(HenriiColors.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(HenriiColors.canvasElevated)
                            .clipShape(Circle())
                    }
                }

                Button { onTapInsights() } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.callout)
                        .foregroundStyle(HenriiColors.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(HenriiColors.canvasElevated)
                        .clipShape(Circle())
                }

                Button { onTapAvatar() } label: {
                    Circle()
                        .fill(HenriiColors.accentPrimary.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Text(baby.name.prefix(1))
                                .font(.henriiHeadline)
                                .foregroundStyle(HenriiColors.accentPrimary)
                        }
                }
            }
            .padding(.horizontal, HenriiSpacing.margin)
            .padding(.vertical, HenriiSpacing.sm)
        }
        .background(.ultraThinMaterial)
    }

    private var babySwitcherMenu: some View {
        Menu {
            ForEach(babies) { b in
                Button {
                    onSwitchBaby?(b)
                } label: {
                    Label {
                        Text(b.name)
                    } icon: {
                        if b.id == baby.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: HenriiSpacing.xs) {
                Circle()
                    .fill(HenriiColors.accentPrimary)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Text(baby.name.prefix(1))
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                    }

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(HenriiColors.textTertiary)
            }
            .frame(height: 44)
        }
    }

    private func statusPill(icon: String, time: String, color: Color) -> some View {
        HStack(spacing: HenriiSpacing.xs) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(time)
                .font(.henriiCaption)
                .foregroundStyle(HenriiColors.textSecondary)
        }
    }

    private func timeSince(_ category: EventCategory) -> String {
        guard let lastEvent = events.first(where: { $0.category == category }) else {
            return "--"
        }
        let interval = Date().timeIntervalSince(lastEvent.timestamp)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "now" }
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        let remainingMins = minutes % 60
        if remainingMins == 0 { return "\(hours)h" }
        return "\(hours)h \(remainingMins)m"
    }
}
