import SwiftUI

struct MilestoneTrackerView: View {
    let baby: Baby
    let milestoneCount: Int

    private var expectedCount: Int {
        let months = max(baby.ageInMonths, 1)
        return min(max(months / 2, 1), 12)
    }

    private var progress: Double {
        min(Double(milestoneCount) / Double(max(expectedCount, 1)), 1)
    }

    var body: some View {
        HStack(spacing: HenriiSpacing.lg) {
            ZStack {
                Circle()
                    .stroke(HenriiColors.dataGrowth.opacity(0.15), lineWidth: 8)
                    .frame(width: 74, height: 74)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(HenriiColors.semanticCelebration, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 74, height: 74)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress * 100))%")
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: HenriiSpacing.xs) {
                Text("Milestone Tracker")
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.textPrimary)
                Text("\(milestoneCount) logged \u{2022} expected around \(expectedCount) by now")
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textSecondary)
                Text("Development varies by child. Celebrate momentum over perfection.")
                    .font(.henriiCaption)
                    .foregroundStyle(HenriiColors.textTertiary)
            }
            Spacer()
        }
        .padding(HenriiSpacing.lg)
        .background(HenriiColors.canvasElevated)
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }
}
