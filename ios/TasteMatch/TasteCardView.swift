import SwiftUI

// MARK: - Taste Card (Shareable Visual)

struct TasteCardView: View {
    let profile: TasteProfile

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                Text("ItMe")
                    .font(.system(.caption, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.clay)
                    .tracking(2)

                if let primary = profile.tags.first {
                    TasteBadge(tagKey: primary.key, size: .featured)
                } else {
                    Text(primaryLabel)
                        .font(.system(.title, design: .serif, weight: .bold))
                        .foregroundStyle(Theme.espresso)
                        .multilineTextAlignment(.center)
                }

                if let secondary = profile.tags.dropFirst().first {
                    TasteBadge(tagKey: secondary.key, size: .compact)
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            // Divider
            Rectangle()
                .fill(Theme.blush)
                .frame(width: 40, height: 2)
                .padding(.bottom, 16)

            // Tags
            VStack(spacing: 10) {
                ForEach(profile.tags.prefix(3)) { tag in
                    HStack(spacing: 10) {
                        Text(tag.label)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.espresso)
                            .frame(width: 120, alignment: .trailing)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Theme.blush.opacity(0.4))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Theme.accent)
                                    .frame(width: geo.size.width * tag.confidence, height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text("\(Int(tag.confidence * 100))%")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.clay)
                            .frame(width: 36, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)

            // Story excerpt
            if !profile.story.isEmpty {
                Text("\"" + storyExcerpt + "\"")
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
                Text("itme2.com")
                    .font(.caption2)
                    .foregroundStyle(Theme.clay)
                Spacer()
                Text("Discover your taste")
                    .font(.caption2)
                    .foregroundStyle(Theme.clay)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(Theme.cream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.blush, lineWidth: 1)
        )
        .frame(width: 320)
    }

    private var primaryLabel: String {
        profile.tags.first?.label ?? "Your Style"
    }

    private var storyExcerpt: String {
        let story = profile.story
        if story.count <= 120 { return story }
        let trimmed = String(story.prefix(117))
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
