import SwiftUI

struct BezierTrendChart: View {
    let dataPoints: [(label: String, value: Double)]
    let color: Color
    let icon: String
    var valueSuffix: String = ""

    private var maxVal: Double {
        max(dataPoints.map(\.value).max() ?? 1, 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let insetTop: CGFloat = 20
            let insetBottom: CGFloat = 24
            let chartHeight = height - insetTop - insetBottom
            let points = computePoints(width: width, chartHeight: chartHeight, insetTop: insetTop)

            ZStack(alignment: .topLeading) {
                fillPath(points: points, chartHeight: chartHeight, insetTop: insetTop, width: width)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.25), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                linePath(points: points)
                    .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                ForEach(Array(points.enumerated()), id: \.offset) { index, pt in
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .position(x: pt.x, y: pt.y)

                    Text(formatValue(dataPoints[index].value))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(HenriiColors.textTertiary)
                        .position(x: pt.x, y: pt.y - 12)

                    Text(dataPoints[index].label)
                        .font(.system(size: 10))
                        .foregroundStyle(HenriiColors.textTertiary)
                        .position(x: pt.x, y: height - 8)
                }
            }
        }
    }

    private func computePoints(width: CGFloat, chartHeight: CGFloat, insetTop: CGFloat) -> [CGPoint] {
        guard dataPoints.count > 1 else {
            if dataPoints.count == 1 {
                return [CGPoint(x: width / 2, y: insetTop + chartHeight / 2)]
            }
            return []
        }
        let spacing = width / CGFloat(dataPoints.count - 1)
        return dataPoints.enumerated().map { index, dp in
            let x = CGFloat(index) * spacing
            let normalized = dp.value / maxVal
            let y = insetTop + chartHeight * (1 - CGFloat(normalized))
            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(points: [CGPoint]) -> Path {
        Path { path in
            guard points.count >= 2 else { return }
            path.move(to: points[0])
            for i in 1..<points.count {
                let prev = points[i - 1]
                let curr = points[i]
                let cx = (prev.x + curr.x) / 2
                path.addCurve(to: curr, control1: CGPoint(x: cx, y: prev.y), control2: CGPoint(x: cx, y: curr.y))
            }
        }
    }

    private func fillPath(points: [CGPoint], chartHeight: CGFloat, insetTop: CGFloat, width: CGFloat) -> Path {
        Path { path in
            guard points.count >= 2 else { return }
            let bottom = insetTop + chartHeight

            path.move(to: CGPoint(x: points[0].x, y: bottom))
            path.addLine(to: points[0])

            for i in 1..<points.count {
                let prev = points[i - 1]
                let curr = points[i]
                let cx = (prev.x + curr.x) / 2
                path.addCurve(to: curr, control1: CGPoint(x: cx, y: prev.y), control2: CGPoint(x: cx, y: curr.y))
            }

            path.addLine(to: CGPoint(x: points.last!.x, y: bottom))
            path.closeSubpath()
        }
    }

    private func formatValue(_ value: Double) -> String {
        if valueSuffix.isEmpty {
            if value == value.rounded() {
                return "\(Int(value))"
            }
            return String(format: "%.1f", value)
        }
        return String(format: "%.1f%@", value, valueSuffix)
    }
}
