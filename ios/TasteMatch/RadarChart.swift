import SwiftUI

struct RadarChart: View {
    let axisScores: AxisScores
    var size: CGFloat = 200

    private let axisCount = 7
    private let gridLevels: [CGFloat] = [0.33, 0.66, 1.0]

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2 - 24

            // Grid rings
            for level in gridLevels {
                let r = radius * level
                var gridPath = Path()
                for i in 0..<axisCount {
                    let pt = point(at: i, distance: r, center: center)
                    if i == 0 { gridPath.move(to: pt) } else { gridPath.addLine(to: pt) }
                }
                gridPath.closeSubpath()
                context.stroke(gridPath, with: .color(Theme.hairline), lineWidth: 1)
            }

            // Spokes
            for i in 0..<axisCount {
                var spoke = Path()
                spoke.move(to: center)
                spoke.addLine(to: point(at: i, distance: radius, center: center))
                context.stroke(spoke, with: .color(Theme.hairline), lineWidth: 1)
            }

            // Data polygon
            let scores = axisValues
            var dataPath = Path()
            for i in 0..<axisCount {
                let normalizedScore = (scores[i] + 1) / 2 // map [-1,+1] → [0,1]
                let r = radius * CGFloat(normalizedScore)
                let pt = point(at: i, distance: r, center: center)
                if i == 0 { dataPath.move(to: pt) } else { dataPath.addLine(to: pt) }
            }
            dataPath.closeSubpath()

            context.fill(dataPath, with: .color(Theme.accent.opacity(0.15)))
            context.stroke(dataPath, with: .color(Theme.accent), lineWidth: 2)
        }
        .frame(width: size, height: size)
        .overlay { axisLabelsOverlay }
    }

    // MARK: - Axis Values

    private var axisValues: [Double] {
        Axis.allCases.map { axisScores.value(for: $0) }
    }

    // MARK: - Geometry

    private func angle(at index: Int) -> CGFloat {
        let slice = (2 * .pi) / CGFloat(axisCount)
        return slice * CGFloat(index) - .pi / 2
    }

    private func point(at index: Int, distance: CGFloat, center: CGPoint) -> CGPoint {
        let a = angle(at: index)
        return CGPoint(
            x: center.x + cos(a) * distance,
            y: center.y + sin(a) * distance
        )
    }

    // MARK: - Labels

    private var axisLabelsOverlay: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 4

            ForEach(0..<axisCount, id: \.self) { i in
                let axis = Axis.allCases[i]
                let score = axisScores.value(for: axis)
                let label = AxisPresentation.influenceWord(axis: axis, positive: score >= 0)
                let pt = point(at: i, distance: radius, center: center)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .position(pt)
            }
        }
    }
}
