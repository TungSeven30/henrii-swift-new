import SwiftUI

struct GrowthChartView: View {
    let baby: Baby
    let growthEvents: [BabyEvent]
    var useMetric: Bool = false

    @State private var selectedPoint: BabyEvent?

    private var weightEvents: [BabyEvent] {
        growthEvents
            .filter { $0.weightLbs != nil }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private func displayWeight(_ lbs: Double) -> Double {
        useMetric ? lbs * 0.453592 : lbs
    }

    private var weightUnit: String {
        useMetric ? "kg" : "lbs"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HenriiSpacing.md) {
            HStack {
                Text("Growth Percentiles")
                    .font(.henriiHeadline)
                    .foregroundStyle(HenriiColors.textPrimary)
                Spacer()
                if let latest = weightEvents.last, let weight = latest.weightLbs {
                    let who = WHOGrowthData.percentile(weightLbs: weight, ageMonths: baby.ageInMonths, gender: baby.gender)
                    Text("~\(who.percentile)th %ile")
                        .font(.henriiCaption)
                        .foregroundStyle(HenriiColors.textSecondary)
                    Text(String(format: "%.1f %@", displayWeight(weight), weightUnit))
                        .font(.henriiCaption)
                        .foregroundStyle(HenriiColors.textTertiary)
                }
            }

            if weightEvents.isEmpty {
                Text("No weight measurements yet.")
                    .font(.henriiCallout)
                    .foregroundStyle(HenriiColors.textSecondary)
            } else {
                GeometryReader { proxy in
                    let chartHeight = max(proxy.size.height, 180)
                    let maxWeight = (weightEvents.compactMap(\.weightLbs).max() ?? 10) + 1
                    let minWeight = max((weightEvents.compactMap(\.weightLbs).min() ?? 5) - 1, 1)

                    ZStack(alignment: .topLeading) {
                        percentileBand(yStart: yPosition(for: minWeight + ((maxWeight - minWeight) * 0.85), in: chartHeight, minWeight: minWeight, maxWeight: maxWeight), yEnd: yPosition(for: minWeight + ((maxWeight - minWeight) * 0.97), in: chartHeight, minWeight: minWeight, maxWeight: maxWeight), color: HenriiColors.dataGrowth.opacity(0.10))
                        percentileBand(yStart: yPosition(for: minWeight + ((maxWeight - minWeight) * 0.50), in: chartHeight, minWeight: minWeight, maxWeight: maxWeight), yEnd: yPosition(for: minWeight + ((maxWeight - minWeight) * 0.85), in: chartHeight, minWeight: minWeight, maxWeight: maxWeight), color: HenriiColors.dataGrowth.opacity(0.06))

                        Path { path in
                            for (index, event) in weightEvents.enumerated() {
                                guard let weight = event.weightLbs else { continue }
                                let x = xPosition(for: index, total: weightEvents.count, width: proxy.size.width)
                                let y = yPosition(for: weight, in: chartHeight, minWeight: minWeight, maxWeight: maxWeight)
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    let previousX = xPosition(for: index - 1, total: weightEvents.count, width: proxy.size.width)
                                    let previousY = yPosition(for: weightEvents[index - 1].weightLbs ?? weight, in: chartHeight, minWeight: minWeight, maxWeight: maxWeight)
                                    let controlX = (previousX + x) / 2
                                    path.addCurve(to: CGPoint(x: x, y: y), control1: CGPoint(x: controlX, y: previousY), control2: CGPoint(x: controlX, y: y))
                                }
                            }
                        }
                        .stroke(HenriiColors.dataGrowth, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                        ForEach(weightEvents) { event in
                            if let weight = event.weightLbs,
                               let idx = weightEvents.firstIndex(where: { $0.id == event.id }) {
                                let x = xPosition(for: idx, total: weightEvents.count, width: proxy.size.width)
                                let y = yPosition(for: weight, in: chartHeight, minWeight: minWeight, maxWeight: maxWeight)
                                Circle()
                                    .fill(HenriiColors.dataGrowth)
                                    .frame(width: 10, height: 10)
                                    .position(x: x, y: y)
                                    .onLongPressGesture(minimumDuration: 0.2) {
                                        selectedPoint = event
                                    }
                            }
                        }
                    }
                }
                .frame(height: 190)

                if let selectedPoint, let weight = selectedPoint.weightLbs {
                    Text("\(selectedPoint.timestamp, format: .dateTime.month().day()): \(String(format: "%.1f", displayWeight(weight))) \(weightUnit)")
                        .font(.henriiCaption)
                        .foregroundStyle(HenriiColors.textSecondary)
                }
            }
        }
        .padding(HenriiSpacing.lg)
        .background(HenriiColors.canvasElevated)
        .clipShape(.rect(cornerRadius: HenriiRadius.medium))
    }

    private func xPosition(for index: Int, total: Int, width: CGFloat) -> CGFloat {
        guard total > 1 else { return width / 2 }
        let progress = CGFloat(index) / CGFloat(total - 1)
        return 12 + progress * max(width - 24, 1)
    }

    private func yPosition(for weight: Double, in height: CGFloat, minWeight: Double, maxWeight: Double) -> CGFloat {
        let normalized = (weight - minWeight) / max((maxWeight - minWeight), 1)
        return height - CGFloat(normalized) * (height - 12) - 6
    }

    private func percentileBand(yStart: CGFloat, yEnd: CGFloat, color: Color) -> some View {
        color
            .frame(height: abs(yEnd - yStart))
            .offset(y: min(yStart, yEnd))
    }
}
