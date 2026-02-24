import SwiftUI
import SwiftData

struct BabyProfileView: View {
    @Bindable var baby: Baby
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BabyEvent.timestamp, order: .reverse) private var allEvents: [BabyEvent]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var showSettings: Bool = false
    @State private var showAddBaby: Bool = false
    @State private var showReport: Bool = false
    @State private var showExportSheet: Bool = false
    @State private var exportCSV: String = ""
    @State private var showHandoff: Bool = false

    private var babyEvents: [BabyEvent] {
        allEvents.filter { $0.baby?.id == baby.id }
    }

    private var growthEvents: [BabyEvent] {
        babyEvents.filter { $0.category == .growth }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HenriiSpacing.xl) {
                profileHeader
                vitalStatsSection
                recentGrowthSection
                quickActionsSection
            }
            .padding(.horizontal, HenriiSpacing.horizontalMargin(for: sizeClass))
            .padding(.top, HenriiSpacing.lg)
            .padding(.bottom, 100)
        }
        .background(HenriiColors.canvasPrimary)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSettings) {
            SettingsView(baby: baby)
        }
        .sheet(isPresented: $showAddBaby) {
            AddBabyView { _ in }
        }
        .sheet(isPresented: $showReport) {
            DoctorReportView(baby: baby, events: babyEvents)
        }
        .sheet(isPresented: $showExportSheet) {
            ExportShareView(csv: exportCSV, babyName: baby.name)
        }
        .sheet(isPresented: $showHandoff) {
            NavigationStack {
                HandoffSummaryView(baby: baby, events: babyEvents)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(HenriiColors.textTertiary)
                }
            }
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

            Text("\(baby.gender.displayName) \u{2022} \(baby.ageDescription)")
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
            let todayEvents = babyEvents.filter { $0.timestamp >= todayStart }

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
                    value: "\(babyEvents.count)",
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

            Button { showReport = true } label: {
                actionRow(icon: "doc.text.fill", title: "Generate Doctor's Report")
            }

            Button { generateAndShowExport() } label: {
                actionRow(icon: "square.and.arrow.up", title: "Export Data")
            }

            Button { showHandoff = true } label: {
                actionRow(icon: "arrow.right.arrow.left", title: "Handoff Summary")
            }

            Button { showAddBaby = true } label: {
                actionRow(icon: "plus.circle.fill", title: "Add Another Baby")
            }
        }
    }

    private func actionRow(icon: String, title: String) -> some View {
        HStack(spacing: HenriiSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(HenriiColors.accentPrimary)
            Text(title)
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

    private func generateAndShowExport() {
        exportCSV = generateCSV()
        showExportSheet = true
    }

    private func generateCSV() -> String {
        var lines: [String] = ["Date,Time,Category,Details,Duration (min),Amount (oz)"]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for event in babyEvents.reversed() {
            let date = formatter.string(from: event.timestamp)
            let time = timeFormatter.string(from: event.timestamp)
            let cat = event.category.rawValue
            let details = event.summaryText.replacingOccurrences(of: ",", with: ";")
            let dur = event.durationMinutes.map { String(format: "%.1f", $0) } ?? ""
            let amt = event.amountOz.map { String(format: "%.1f", $0) } ?? ""
            lines.append("\(date),\(time),\(cat),\(details),\(dur),\(amt)")
        }
        return lines.joined(separator: "\n")
    }

    private func formatDuration(_ minutes: Double) -> String {
        let hours = Int(minutes) / 60
        let mins = Int(minutes) % 60
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }
}
