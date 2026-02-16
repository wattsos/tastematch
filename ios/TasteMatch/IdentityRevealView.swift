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

    // Collage placeholder symbols + aspect hints
    private let collageSlots: [(symbol: String, ratio: CGFloat)] = [
        ("figure.stand", 0.65),
        ("tshirt", 1.2),
        ("square.stack.3d.up", 0.8),
        ("hammer", 1.0),
        ("chair", 0.75),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {

                // Collage
                collageGrid
                    .padding(.bottom, 2)

                // Identity name overlay
                identityTitle
                    .padding(.top, 32)
                    .padding(.bottom, 28)

                // Divider
                Rectangle()
                    .fill(Theme.charcoal.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                // Influences
                influenceList
                    .padding(.top, 24)
                    .padding(.bottom, 28)

                // Confidence line
                confidenceLine
                    .padding(.bottom, 40)

                // CTAs
                ctaRow
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .background(Theme.bone.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Collage Grid

    private var collageGrid: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let gap: CGFloat = 2

            ZStack(alignment: .topLeading) {
                // Row 1: two images
                collageTile(collageSlots[0])
                    .frame(width: w * 0.58 - gap, height: w * 0.72)

                collageTile(collageSlots[1])
                    .frame(width: w * 0.42, height: w * 0.72)
                    .offset(x: w * 0.58 + gap)

                // Row 2: three images
                collageTile(collageSlots[2])
                    .frame(width: w * 0.34 - gap, height: w * 0.44)
                    .offset(y: w * 0.72 + gap)

                collageTile(collageSlots[3])
                    .frame(width: w * 0.34 - gap, height: w * 0.44)
                    .offset(x: w * 0.34 + gap, y: w * 0.72 + gap)

                collageTile(collageSlots[4])
                    .frame(width: w * 0.32, height: w * 0.44)
                    .offset(x: w * 0.68 + gap, y: w * 0.72 + gap)
            }
        }
        .frame(height: UIScreen.main.bounds.width * 1.16 + 4)
    }

    private func collageTile(_ slot: (symbol: String, ratio: CGFloat)) -> some View {
        ZStack {
            Theme.charcoal.opacity(0.04)

            Image(systemName: slot.symbol)
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(Theme.charcoal.opacity(0.15))
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
        VStack(spacing: 16) {
            ForEach(Array(influences.enumerated()), id: \.offset) { _, pair in
                HStack {
                    Text(pair.0)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.charcoal.opacity(0.35))
                        .tracking(1.2)
                        .frame(width: 80, alignment: .leading)

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
