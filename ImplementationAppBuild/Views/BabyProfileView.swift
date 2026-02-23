import SwiftUI
import SwiftData

struct BabyProfileView: View {
    @Bindable var baby: Baby
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BabyEvent.timestamp, order: .reverse) private var allEvents: [BabyEvent]

    @State private var showSettings: Bool = false

    private var growthEvents: [BabyEvent] {
        allEvents.filter { $0.category == .growth }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HenriiSpacing.xl) {
                profileHeader
                vitalStatsSection
                recentGrowthSection
                quickActionsSection
            }
            .padding(.horizontal, HenriiSpacing.margin)
            .padding(.top, HenriiSpacing.lg)
            .padding(.bottom, 100)
        }
        .background(HenriiColors.canvasPrimary)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSettings) {
            SettingsView(baby: baby)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(HenriiColors.textSecondary)
                }
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: HenriiSpacing.md) {
            Circle()
                .fill(HenriiColors.accentPrimary.opacity(0.12))
                .frame(width: 88, height: 88)
                .overlay {
                    Text(baby.name.prefix(1))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(HenriiColors.accentPrimary)
                }

            Text(baby.name)
                .font(.henriiLargeTitle)
                .foregroundStyle(HenriiColors.textPrimary)

            Text(baby.ageDescription)
                .font(.henriiCallout)
                .foregroundStyle(HenriiColors.textSecondary)

            Text("Born \(baby.birthDate, format: .dateTime.month(.wide).day().year())")
                .font(.henriiCaption)
                .foregroundStyle(HenriiColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HenriiSpacing.lg)
    }

    private var vitalStatsSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Quick Stats")
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)

            let todayStart = Calendar.current.startOfDay(for: Date())
            let todayEvents = allEvents.filter { $0.timestamp >= todayStart }

            HStack(spacing: HenriiSpacing.md) {
                statCard(
                    value: "\(todayEvents.filter { $0.category == .feeding }.count)",
                    label: "Feeds today",
                    icon: "cup.and.saucer.fill",
                    color: HenriiColors.dataFeeding
                )
                statCard(
                    value: "\(todayEvents.filter { $0.category == .diaper }.count)",
                    label: "Diapers today",
                    icon: "leaf.fill",
                    color: HenriiColors.dataDiaper
                )
            }

            HStack(spacing: HenriiSpacing.md) {
                let sleepMins = todayEvents.filter { $0.category == .sleep }.compactMap(\.durationMinutes).reduce(0, +)
                statCard(
                    value: formatDuration(sleepMins),
                    label: "Sleep today",
                    icon: "moon.fill",
                    color: HenriiColors.dataSleep
                )
                statCard(
                    value: "\(allEvents.count)",
                    label: "Total entries",
                    icon: "chart.bar.fill",
                    color: HenriiColors.accentPrimary
                )
            }
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.sm) {
            HStack(spacing: HenriiSpacing.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(label)
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
            }
            Text(value)
                .font(.henriiData(size: 28))
                .foregroundStyle(HenriiColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HenriiSpacing.lg)
        .background(HenriiColors.canvasElevated)
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }

    private var recentGrowthSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Growth")
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)

            if growthEvents.isEmpty {
                HStack {
                    Image(systemName: "ruler.fill")
                        .foregroundStyle(HenriiColors.dataGrowth)
                    Text("No growth measurements yet. Tell me a weight or height to start tracking.")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textSecondary)
                }
                .padding(HenriiSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HenriiColors.canvasElevated)
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
            } else {
                ForEach(growthEvents.prefix(3)) { event in
                    HStack {
                        Text(event.summaryText)
                            .font(.henriiCallout)
                            .foregroundStyle(HenriiColors.textPrimary)
                        Spacer()
                        Text(event.timestamp, format: .dateTime.month(.abbreviated).day())
                            .font(.henriiCaption)
                            .foregroundStyle(HenriiColors.textTertiary)
                    }
                    .padding(HenriiSpacing.lg)
                    .background(HenriiColors.canvasElevated)
                    .clipShape(.rect(cornerRadius: HenriiRadius.medium))
                }
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            Text("Actions")
                .font(.henriiHeadline)
                .foregroundStyle(HenriiColors.textPrimary)

            Button { } label: {
                HStack(spacing: HenriiSpacing.md) {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(HenriiColors.accentPrimary)
                    Text("Generate Doctor's Report")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(HenriiColors.textTertiary)
                }
                .padding(HenriiSpacing.lg)
                .background(HenriiColors.canvasElevated)
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
            }

            Button { } label: {
                HStack(spacing: HenriiSpacing.md) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(HenriiColors.accentPrimary)
                    Text("Export Data")
                        .font(.henriiCallout)
                        .foregroundStyle(HenriiColors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(HenriiColors.textTertiary)
                }
                .padding(HenriiSpacing.lg)
                .background(HenriiColors.canvasElevated)
                .clipShape(.rect(cornerRadius: HenriiRadius.medium))
            }
        }
    }

    private func formatDuration(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }
}
