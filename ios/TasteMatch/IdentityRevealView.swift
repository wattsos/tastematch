import SwiftUI

struct IdentityRevealView: View {
    @Binding var path: NavigationPath
    @Environment(\.openURL) private var openURL

    // MARK: - Placeholder data

    private let identityName = "Quiet\nBrutalist"
    private let influences = [
        ("PRIMARY", "Industrial Minimalism"),
        ("SECONDARY", "Heritage Craft"),
        ("TERTIARY", "Utilitarian Edge"),
    ]
    private let confidence = 42
    private let signals = 10

    // Images from deck
    private var heroImage: String { IdentityFitsCatalog.all[0] }
    private var supportLeftImage: String { IdentityFitsCatalog.all[4] }
    private var supportRightImage: String { IdentityFitsCatalog.all[8] }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Identity title at top
                    identityTitle
                        .padding(.top, 20)
                        .padding(.bottom, 24)

                    // Hero image — full width, ~60% viewport
                    heroImageView

                    // Two supporting images
                    supportingImages
                        .padding(.top, 2)

                    // Divider
                    Rectangle()
                        .fill(Theme.charcoal.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // Influences
                    influenceList
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                    // Confidence
                    confidenceLine
                        .padding(.bottom, 100) // space for sticky bar
                }
            }

            // Sticky bottom bar
            stickyBar
        }
        .background(Theme.bone.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Identity Title (at top)

    private var identityTitle: some View {
        VStack(spacing: 6) {
            Text("YOUR IDENTITY")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.burgundy)
                .tracking(1.6)

            Text(identityName)
                .font(.system(size: 44, weight: .regular, design: .serif))
                .foregroundStyle(Theme.charcoal)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Hero Image

    private var heroImageView: some View {
        GeometryReader { geo in
            Image(heroImage)
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.width * 1.3)
                .clipped()
        }
        .frame(height: UIScreen.main.bounds.width * 1.3)
    }

    // MARK: - Supporting Images

    private var supportingImages: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let gap: CGFloat = 2
            let tileW = (w - gap) / 2
            let tileH = tileW * 0.75

            HStack(spacing: gap) {
                Image(supportLeftImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: tileW, height: tileH)
                    .clipped()

                Image(supportRightImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: tileW, height: tileH)
                    .clipped()
            }
        }
        .frame(height: (UIScreen.main.bounds.width - 2) / 2 * 0.75)
    }

    // MARK: - Influences

    private var influenceList: some View {
        VStack(spacing: 14) {
            ForEach(Array(influences.enumerated()), id: \.offset) { _, pair in
                HStack(spacing: 0) {
                    Text(pair.0)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.charcoal.opacity(0.35))
                        .tracking(1.2)
                        .frame(width: 84, alignment: .leading)

                    Text(pair.1)
                        .font(.subheadline)
                        .foregroundStyle(Theme.charcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Confidence

    private var confidenceLine: some View {
        Text("Identity Confidence \(confidence)%  (Based on \(signals) signals)")
            .font(.caption2)
            .foregroundStyle(Theme.charcoal.opacity(0.4))
            .tracking(0.3)
    }

    // MARK: - Sticky Bottom Bar

    private var stickyBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Theme.charcoal.opacity(0.08))
                .frame(height: 1)

            HStack(spacing: 0) {
                Button {
                    // Pop back to swipe deck — it will extend by 10 more cards
                    path.removeLast()
                } label: {
                    Text("REFINE +10 SWIPES")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.charcoal)
                        .tracking(1.0)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .overlay(
                            Rectangle()
                                .stroke(Theme.charcoal.opacity(0.12), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    // Open demo shop URL
                    if let url = URL(string: "https://example.com/shop-identity") {
                        openURL(url)
                    }
                } label: {
                    Text("SHOP THIS IDENTITY")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .tracking(1.0)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.burgundy)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Theme.bone)
    }
}
