import SwiftUI

struct IdentityRevealView: View {

    // MARK: - Placeholder data

    private let identityName = "Quiet\nBrutalist"
    private let influences = [
        ("PRIMARY", "Industrial Minimalism"),
        ("SECONDARY", "Heritage Craft"),
        ("TERTIARY", "Utilitarian Edge"),
    ]
    private let confidence = 42
    private let signals = 10

    // Hero + two supporting image placeholders
    private let heroSymbol = "figure.stand"
    private let supportLeft = "tshirt"
    private let supportRight = "chair"

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .top) {
                Theme.bone.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Image block: hero + two supporting
                    imageBlock(width: w, totalHeight: h)

                    // Content below images
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            identityTitle
                                .padding(.top, 28)
                                .padding(.bottom, 24)

                            Rectangle()
                                .fill(Theme.charcoal.opacity(0.1))
                                .frame(height: 1)
                                .padding(.horizontal, 24)

                            influenceList
                                .padding(.top, 20)
                                .padding(.bottom, 20)

                            confidenceLine
                                .padding(.bottom, 28)

                            ctaRow
                                .padding(.horizontal, 24)
                                .padding(.bottom, 48)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Image Block (Layout C)

    private func imageBlock(width w: CGFloat, totalHeight h: CGFloat) -> some View {
        let heroH = h * 0.52
        let supportH = h * 0.16
        let gap: CGFloat = 2

        return ZStack(alignment: .topLeading) {
            // Hero — full width, top 52%
            imageTile(symbol: heroSymbol)
                .frame(width: w, height: heroH)

            // Supporting left — bottom-left, overlapping hero bottom
            imageTile(symbol: supportLeft)
                .frame(width: w * 0.48 - gap / 2, height: supportH)
                .offset(y: heroH + gap)

            // Supporting right — bottom-right
            imageTile(symbol: supportRight)
                .frame(width: w * 0.52 - gap / 2, height: supportH)
                .offset(x: w * 0.48 + gap / 2, y: heroH + gap)
        }
        .frame(width: w, height: heroH + 2 + supportH)
    }

    private func imageTile(symbol: String) -> some View {
        ZStack {
            Theme.charcoal.opacity(0.04)

            Image(systemName: symbol)
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(Theme.charcoal.opacity(0.14))
        }
        .clipped()
    }

    // MARK: - Identity Title

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
        }
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

    // MARK: - CTAs

    private var ctaRow: some View {
        HStack(spacing: 0) {
            Button {
                // Stub: route back into refine deck
            } label: {
                Text("REFINE")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.charcoal)
                    .tracking(1.2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .overlay(
                        Rectangle()
                            .stroke(Theme.charcoal.opacity(0.15), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button {
                // Stub: route to shop
            } label: {
                Text("SHOP")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .tracking(1.2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Theme.burgundy)
            }
            .buttonStyle(.plain)
        }
    }
}
