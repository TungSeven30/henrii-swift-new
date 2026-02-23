import SwiftUI

struct DoctorReportView: View {
    let baby: Baby
    let events: [BabyEvent]
    @Environment(\.dismiss) private var dismiss
    @State private var reportText: String = ""
    @State private var copied: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HenriiSpacing.lg) {
                    HStack(spacing: HenriiSpacing.md) {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .foregroundStyle(HenriiColors.accentPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Doctor's Report")
                                .font(.henriiHeadline)
                                .foregroundStyle(HenriiColors.textPrimary)
                            Text("Last 7 days summary")
                                .font(.henriiCaption)
                                .foregroundStyle(HenriiColors.textTertiary)
                        }
                    }

                    Text(reportText)
                        .font(.henriiBody)
                        .foregroundStyle(HenriiColors.textPrimary)
                        .textSelection(.enabled)

                    Button {
                        UIPasteboard.general.string = reportText
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    } label: {
                        HStack {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            Text(copied ? "Copied!" : "Copy to Clipboard")
                        }
                        .font(.henriiHeadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(copied ? HenriiColors.dataGrowth : HenriiColors.accentPrimary)
                        .clipShape(Capsule())
                    }
                    .sensoryFeedback(.success, trigger: copied)
                }
                .padding(HenriiSpacing.margin)
            }
            .background(HenriiColors.canvasPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HenriiColors.accentPrimary)
                }
            }
            .onAppear { reportText = generateReport() }
        }
    }

    private func generateReport() -> String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEvents = events.filter { $0.timestamp >= weekAgo }

        let feeds = recentEvents.filter { $0.category == .feeding }
        let sleeps = recentEvents.filter { $0.category == .sleep }
        let diapers = recentEvents.filter { $0.category == .diaper }
        let healthEvents = recentEvents.filter { $0.category == .health }
        let growthEvents = recentEvents.filter { $0.category == .growth }

        let avgFeedsPerDay = feeds.count > 0 ? Double(feeds.count) / 7.0 : 0
        let totalSleepHrs = sleeps.compactMap(\.durationMinutes).reduce(0, +) / 60.0
        let avgSleepPerDay = totalSleepHrs / 7.0
        let avgDiapersPerDay = diapers.count > 0 ? Double(diapers.count) / 7.0 : 0

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        var report = """
        BABY CARE REPORT
        \(baby.name) — \(baby.ageDescription)
        Born: \(formatter.string(from: baby.birthDate))
        Report Period: \(formatter.string(from: weekAgo)) – \(formatter.string(from: Date()))

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━

        FEEDING
        Total feeds: \(feeds.count)
        Average per day: \(String(format: "%.1f", avgFeedsPerDay))
        """

        let bottleFeeds = feeds.filter { $0.feedingType == .bottle }
        let breastFeeds = feeds.filter { $0.feedingType == .breastLeft || $0.feedingType == .breastRight || $0.feedingType == .breastBoth }
        if !bottleFeeds.isEmpty {
            let avgOz = bottleFeeds.compactMap(\.amountOz).reduce(0, +) / Double(max(bottleFeeds.count, 1))
            report += "\nBottle feeds: \(bottleFeeds.count) (avg \(String(format: "%.1f", avgOz))oz)"
        }
        if !breastFeeds.isEmpty {
            report += "\nBreastfeeds: \(breastFeeds.count)"
        }

        report += """


        SLEEP
        Total recorded: \(String(format: "%.1f", totalSleepHrs)) hours
        Average per day: \(String(format: "%.1f", avgSleepPerDay)) hours
        Sessions: \(sleeps.count)
        """

        report += """


        DIAPERS
        Total changes: \(diapers.count)
        Average per day: \(String(format: "%.1f", avgDiapersPerDay))
        Wet: \(diapers.filter { $0.diaperType == .wet }.count)
        Dirty: \(diapers.filter { $0.diaperType == .dirty }.count)
        Both: \(diapers.filter { $0.diaperType == .both }.count)
        """

        if !healthEvents.isEmpty {
            report += "\n\nHEALTH NOTES"
            for event in healthEvents {
                report += "\n• \(formatter.string(from: event.timestamp)): \(event.summaryText)"
            }
        }

        if !growthEvents.isEmpty {
            report += "\n\nGROWTH"
            for event in growthEvents {
                report += "\n• \(formatter.string(from: event.timestamp)): \(event.summaryText)"
            }
        }

        report += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━\nGenerated by Henrii"

        return report
    }
}
