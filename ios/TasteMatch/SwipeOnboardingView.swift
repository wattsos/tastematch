import SwiftUI

struct SwipeOnboardingView: View {
    @Binding var path: NavigationPath

    @State private var deckKind: StyleDeckKind?
    @State private var currentIndex = 0
    @State private var decisions: [Bool] = []

    private var cards: [StyleCard] {
        guard let kind = deckKind else { return [] }
        return StyleSeedDeck.deck(for: kind)
    }

    private var progress: CGFloat {
        guard !cards.isEmpty else { return 0 }
        return CGFloat(currentIndex) / CGFloat(cards.count)
    }

    var body: some View {
        Group {
            if deckKind == nil {
                deckSelector
            } else {
                swipeDeck
            }
        }
        .background(Theme.bone.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: deckKind != nil)
        .onAppear {
            if deckKind == nil, let saved = StyleDeckKind.stored {
                deckKind = saved
            }
        }
    }

    // MARK: - Deck Selector

    private var deckSelector: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("BUILD YOUR STYLE IDENTITY")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.burgundy)
                    .tracking(1.4)

                Text("What are you dressing?")
                    .font(Theme.identityHeadline)
                    .foregroundStyle(Theme.charcoal)
            }

            Spacer()

            VStack(spacing: 0) {
                deckButton("Menswear", kind: .menswear)
                HairlineDivider()
                deckButton("Womenswear", kind: .womenswear)
                HairlineDivider()
                deckButton("Any", kind: .any)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    private func deckButton(_ label: String, kind: StyleDeckKind) -> some View {
        Button {
            kind.save()
            Haptics.tap()
            withAnimation { deckKind = kind }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.charcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Swipe Deck

    private var swipeDeck: some View {
        VStack(spacing: 0) {
            // Burgundy progress bar
            progressBar
                .padding(.top, 4)

            // Minimal header
            Text("Which looks feel like you?")
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.charcoal.opacity(0.6))
                .tracking(0.4)
                .padding(.top, 14)
                .padding(.bottom, 10)

            // Full-bleed image
            if currentIndex < cards.count {
                fullBleedCard(cards[currentIndex])
                    .id(currentIndex)
                    .transition(.opacity)
            }

            Spacer(minLength: 0)

            // Bottom controls
            buttonRow
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .animation(.easeInOut(duration: 0.2), value: currentIndex)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Theme.charcoal.opacity(0.08))

                Rectangle()
                    .fill(Theme.burgundy)
                    .frame(width: geo.size.width * progress)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Full-bleed Card

    private func fullBleedCard(_ card: StyleCard) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Image fills entire area — no rounded corners, no card container
                if UIImage(named: card.imageName) != nil {
                    Image(card.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    // Placeholder: symbol on bone
                    ZStack {
                        Theme.bone

                        Image(systemName: card.symbol)
                            .font(.system(size: 80, weight: .thin))
                            .foregroundStyle(Theme.charcoal.opacity(0.18))
                    }
                }

                // Title overlay at bottom edge
                VStack(spacing: 2) {
                    Text(card.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.charcoal)
                    Text(card.subtitle.uppercased())
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.charcoal.opacity(0.5))
                        .tracking(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.bone.opacity(0.92))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Buttons

    private var buttonRow: some View {
        HStack(spacing: 0) {
            Button {
                recordDecision(false)
            } label: {
                Text("Not me")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.charcoal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .overlay(
                        Rectangle()
                            .stroke(Theme.charcoal.opacity(0.15), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button {
                recordDecision(true)
            } label: {
                Text("This is me")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.burgundy)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Logic

    private func recordDecision(_ isMe: Bool) {
        decisions.append(isMe)
        Haptics.tap()

        if decisions.count >= cards.count {
            path.append(Route.identityReveal)
        } else {
            currentIndex = decisions.count
        }
    }
}
