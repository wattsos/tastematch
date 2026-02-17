import SwiftUI

struct SwipeOnboardingView: View {
    @Binding var path: NavigationPath

    @State private var deckKind: StyleDeckKind?
    @State private var deckCards: [StyleCard] = []
    @State private var currentIndex = 0
    @State private var decisions: [Bool] = []
    @State private var dragOffset: CGFloat = 0

    private let initialBatch = 16
    private let refineBatch = 10

    private var progress: CGFloat {
        guard !deckCards.isEmpty else { return 0 }
        return CGFloat(currentIndex) / CGFloat(deckCards.count)
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
                loadBatch(for: saved)
            }
            // Returned from reveal — extend deck with 10 more
            if !deckCards.isEmpty && currentIndex >= deckCards.count {
                extendDeck()
            }
        }
    }

    // MARK: - Deck Selector

    private var deckSelector: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("LET'S MAP YOUR TASTE")
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
            loadBatch(for: kind)
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

            // Header
            VStack(spacing: 4) {
                Text("LET'S MAP YOUR TASTE")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.burgundy)
                    .tracking(1.4)

                Text("Swipe right for you. Left for not you.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.charcoal.opacity(0.5))
                    .tracking(0.2)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Swipeable card
            if currentIndex < deckCards.count {
                swipeableCard(deckCards[currentIndex])
                    .id(currentIndex)
            }

            Spacer(minLength: 0)

            // Fallback buttons
            buttonRow
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
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

    // MARK: - Swipeable Card

    private func swipeableCard(_ card: StyleCard) -> some View {
        GeometryReader { geo in
            ZStack {
                // Full-bleed image
                Image(card.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))

                // Swipe direction indicator
                if dragOffset > 30 {
                    swipeLabel("YES", color: Theme.burgundy)
                        .opacity(Double(min(1, (dragOffset - 30) / 60)))
                } else if dragOffset < -30 {
                    swipeLabel("NOPE", color: Theme.charcoal.opacity(0.6))
                        .opacity(Double(min(1, (-dragOffset - 30) / 60)))
                }
            }
            .offset(x: dragOffset)
            .rotationEffect(.degrees(Double(dragOffset) / 20), anchor: .bottom)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 100
                        if value.translation.width > threshold {
                            swipeAway(isMe: true)
                        } else if value.translation.width < -threshold {
                            swipeAway(isMe: false)
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
    }

    private func swipeLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(color, lineWidth: 3)
            )
            .rotationEffect(.degrees(text == "YES" ? -15 : 15))
            .padding(.bottom, 100)
    }

    // MARK: - Buttons (fallback)

    private var buttonRow: some View {
        HStack(spacing: 0) {
            Button {
                swipeAway(isMe: false)
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
                swipeAway(isMe: true)
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

    private func loadBatch(for kind: StyleDeckKind) {
        let all = StyleSeedDeck.deck(for: kind)
        deckCards = Array(all.prefix(initialBatch))
        currentIndex = 0
        decisions = []
    }

    private func extendDeck() {
        guard let kind = deckKind else { return }
        let all = StyleSeedDeck.deck(for: kind)
        let nextStart = deckCards.count
        let nextEnd = min(nextStart + refineBatch, all.count)
        guard nextStart < all.count else { return }
        deckCards.append(contentsOf: all[nextStart..<nextEnd])
    }

    private func swipeAway(isMe: Bool) {
        let exitX: CGFloat = isMe ? 400 : -400

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            dragOffset = exitX
        }

        Haptics.impact()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            decisions.append(isMe)
            dragOffset = 0

            if decisions.count >= deckCards.count {
                path.append(Route.identityReveal)
            } else {
                currentIndex = decisions.count
            }
        }
    }
}
