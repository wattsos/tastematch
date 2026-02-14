import SwiftUI

struct SwipeDeckView<Content: View>: View {
    let items: [AnyHashable]
    let onSwipe: (SwipeDirection) -> Void
    let content: (AnyHashable) -> Content

    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragDirection: SwipeDirection?

    private let swipeThresholdX: CGFloat = 100
    private let swipeThresholdY: CGFloat = 80

    var body: some View {
        ZStack {
            if currentIndex < items.count {
                // Show next card underneath (preview)
                if currentIndex + 1 < items.count {
                    cardView(for: items[currentIndex + 1])
                        .scaleEffect(0.95)
                        .opacity(0.5)
                }

                // Current card
                cardView(for: items[currentIndex])
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width) / 20))
                    .gesture(dragGesture)
                    .overlay(swipeOverlay)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: dragOffset)
    }

    private func cardView(for item: AnyHashable) -> some View {
        content(item)
            .frame(maxWidth: .infinity)
            .labSurface(padded: true, bordered: true)
    }

    @ViewBuilder
    private var swipeOverlay: some View {
        ZStack {
            if let direction = dragDirection {
                switch direction {
                case .right:
                    overlayLabel("YES", color: Theme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                case .left:
                    overlayLabel("NOPE", color: Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 20)
                case .up:
                    overlayLabel("LOVE", color: Theme.accent)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 20)
                }
            }
        }
    }

    private func overlayLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius)
                    .stroke(color, lineWidth: 2)
            )
            .opacity(min(1, abs(dragOffset.width) / swipeThresholdX))
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                if value.translation.height < -swipeThresholdY && abs(value.translation.width) < swipeThresholdX {
                    dragDirection = .up
                } else if value.translation.width > swipeThresholdX * 0.5 {
                    dragDirection = .right
                } else if value.translation.width < -swipeThresholdX * 0.5 {
                    dragDirection = .left
                } else {
                    dragDirection = nil
                }
            }
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height

                if vertical < -swipeThresholdY && abs(horizontal) < swipeThresholdX {
                    completeSwipe(.up, offset: CGSize(width: 0, height: -600))
                } else if horizontal > swipeThresholdX {
                    completeSwipe(.right, offset: CGSize(width: 500, height: 0))
                } else if horizontal < -swipeThresholdX {
                    completeSwipe(.left, offset: CGSize(width: -500, height: 0))
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = .zero
                        dragDirection = nil
                    }
                }
            }
    }

    private func completeSwipe(_ direction: SwipeDirection, offset: CGSize) {
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = offset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onSwipe(direction)
            currentIndex += 1
            dragOffset = .zero
            dragDirection = nil
        }
    }

    var isComplete: Bool {
        currentIndex >= items.count
    }
}
