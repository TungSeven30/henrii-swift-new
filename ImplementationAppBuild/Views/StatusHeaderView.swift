import SwiftUI

struct StatusHeaderView: View {
    let baby: Baby
    let events: [BabyEvent]
    @State private var showSettings: Bool = false

    var body: some View {
        VStack(spacing: HenriiSpacing.xs) {
            HStack(spacing: HenriiSpacing.lg) {
                statusPill(icon: "cup.and.saucer.fill", time: timeSince(.feeding), color: HenriiColors.dataFeeding)
                statusPill(icon: "moon.fill", time: timeSince(.sleep), color: HenriiColors.dataSleep)
                statusPill(icon: "leaf.fill", time: timeSince(.diaper), color: HenriiColors.dataDiaper)

                Spacer()

                Button { showSettings = true } label: {
                    Circle()
                        .fill(HenriiColors.accentPrimary.opacity(0.15))
                        .frame(width: 36, height: 36)
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
        .sheet(isPresented: $showSettings) {
            SettingsView(baby: baby)
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
