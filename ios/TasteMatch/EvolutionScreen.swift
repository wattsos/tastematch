import SwiftUI

struct EvolutionScreen: View {
    @State private var history: [SavedProfile] = []

    var body: some View {
        Group {
            if history.count < 2 {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.blush)
                    Text("Your taste is evolving")
                        .font(Theme.headlineFont)
                        .foregroundStyle(Theme.espresso)
                    Text("Analyze at least two rooms and\nwe'll map how your style shifts.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.clay)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        chartSection
                        legendSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Evolution")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            history = ProfileStore.loadAll()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("OVER TIME")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(1.2)
            Text("How your primary style has shifted across \(history.count) analyses.")
                .font(.subheadline)
                .foregroundStyle(Theme.clay)
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        let points = dataPoints
        let maxConf = points.map(\.confidence).max() ?? 1

        return VStack(spacing: 0) {
            // Chart area
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let stepX = points.count > 1 ? width / CGFloat(points.count - 1) : width / 2

                ZStack {
                    // Grid lines
                    ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { level in
                        let y = height - (CGFloat(level / maxConf) * height)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                        .stroke(Theme.blush.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    }

                    // Line path
                    if points.count > 1 {
                        Path { path in
                            for (i, point) in points.enumerated() {
                                let x = CGFloat(i) * stepX
                                let y = height - (CGFloat(point.confidence / maxConf) * height)
                                if i == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                        // Fill under the line
                        Path { path in
                            for (i, point) in points.enumerated() {
                                let x = CGFloat(i) * stepX
                                let y = height - (CGFloat(point.confidence / maxConf) * height)
                                if i == 0 {
                                    path.move(to: CGPoint(x: x, y: height))
                                    path.addLine(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            path.addLine(to: CGPoint(x: CGFloat(points.count - 1) * stepX, y: height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.25), Theme.accent.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    // Data points
                    ForEach(Array(points.enumerated()), id: \.offset) { i, point in
                        let x = points.count > 1 ? CGFloat(i) * stepX : width / 2
                        let y = height - (CGFloat(point.confidence / maxConf) * height)

                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 10, height: 10)
                            .position(x: x, y: y)

                        Text(point.tagLabel)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Theme.espresso)
                            .position(x: x, y: y - 14)
                    }
                }
            }
            .frame(height: 180)
            .padding(.vertical, 8)

            // X-axis labels
            let points2 = dataPoints
            HStack {
                ForEach(Array(points2.enumerated()), id: \.offset) { i, point in
                    if i > 0 { Spacer() }
                    Text(shortDate(point.date))
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.clay)
                }
            }
        }
        .labSurface()
    }

    // MARK: - Legend

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.espresso)

            ForEach(Array(dataPoints.enumerated()), id: \.offset) { i, point in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(point.tagLabel)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.espresso)
                        Text("\(fullDate(point.date))")
                            .font(.caption2)
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    if i > 0 {
                        let prev = dataPoints[i - 1]
                        let delta = point.confidence - prev.confidence
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                            .foregroundStyle(delta >= 0 ? Theme.sage : Theme.rose)
                    }
                }
            }
        }
    }

    // MARK: - Data

    private struct DataPoint {
        let tagLabel: String
        let confidence: Double
        let date: Date
    }

    private var dataPoints: [DataPoint] {
        history.compactMap { saved in
            guard let primary = saved.tasteProfile.tags.first else { return nil }
            return DataPoint(
                tagLabel: saved.tasteProfile.displayName,
                confidence: primary.confidence,
                date: saved.savedAt
            )
        }
    }

    // MARK: - Formatting

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    private func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
