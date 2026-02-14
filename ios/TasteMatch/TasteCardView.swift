import SwiftUI

// MARK: - Taste Card (Shareable Visual)

struct TasteCardView: View {
    let profile: TasteProfile

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                Text(Brand.name.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(2)

                Text(profile.displayName)
                    .font(.system(.title, design: .serif, weight: .bold))
                    .foregroundStyle(Theme.espresso)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            // Divider
            Rectangle()
                .fill(Theme.blush)
                .frame(width: 40, height: 2)
                .padding(.bottom, 16)

            // Axis Influences
            VStack(alignment: .leading, spacing: 8) {
                let vector = TasteEngine.vectorFromProfile(profile)
                let axisScores = AxisMapping.computeAxisScores(from: vector)
                let phrases = AxisPresentation.influencePhrases(axisScores: axisScores)

                ForEach(phrases, id: \.self) { phrase in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Theme.muted.opacity(0.3))
                            .frame(width: 4, height: 4)
                        Text(phrase)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.espresso)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            // Reading excerpt
            let reading = computeReading()
            if !reading.isEmpty {
                Text("\"" + readingExcerpt(reading) + "\"")
                    .font(.system(.footnote, design: .serif))
                    .foregroundStyle(Theme.clay)
                    .italic()
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 20)
            }

            // Footer
            Rectangle()
                .fill(Theme.blush)
                .frame(height: 1)

            HStack {
                Text(Brand.domain)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                Spacer()
                Text(Brand.tagline)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius)
                .stroke(Theme.blush, lineWidth: 1)
        )
        .frame(width: 320)
    }

    private func computeReading() -> String {
        let vector = TasteEngine.vectorFromProfile(profile)
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        return AxisPresentation.oneLineReading(
            profileName: profile.displayName,
            axisScores: axisScores
        )
    }

    private func readingExcerpt(_ text: String) -> String {
        if text.count <= 120 { return text }
        let trimmed = String(text.prefix(117))
        if let lastSpace = trimmed.lastIndex(of: " ") {
            return String(trimmed[...lastSpace]) + "..."
        }
        return trimmed + "..."
    }
}

// MARK: - Render to UIImage

extension TasteCardView {
    @MainActor
    func renderImage() -> UIImage? {
        let renderer = ImageRenderer(content: self.padding(16).background(Color.white))
        renderer.scale = 3.0
        return renderer.uiImage
    }
}
