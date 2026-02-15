import SwiftUI

struct TasteCalibrationScreen: View {
    @Binding var path: NavigationPath
    let profile: TasteProfile
    let recommendations: [RecommendationItem]

    @State private var vector = TasteVector.zero
    @State private var swipeCount = 0
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragDirection: SwipeDirection?
    @State private var showUpdating = false
    @State private var showResetConfirmation = false
    @State private var didLoadExisting = false

    private let swipeThresholdX: CGFloat = 100
    private let swipeThresholdY: CGFloat = 80

    /// 20 cards: 2 per canonical tag, balanced distribution, deterministic shuffle.
    private var calibrationItems: [CatalogItem] {
        var tagBuckets: [String: [CatalogItem]] = [:]
        for tag in TasteEngine.CanonicalTag.allCases {
            tagBuckets[String(describing: tag)] = []
        }
        for item in MockCatalog.items {
            if let primaryTag = item.tags.first {
                let key = String(describing: primaryTag)
                if var bucket = tagBuckets[key], bucket.count < 2 {
                    bucket.append(item)
                    tagBuckets[key] = bucket
                }
            }
        }

        var items: [CatalogItem] = []
        for tag in TasteEngine.CanonicalTag.allCases {
            let key = String(describing: tag)
            items.append(contentsOf: tagBuckets[key] ?? [])
        }

        var rng = SeededRNG(seed: profile.id.hashValue)
        items.shuffle(using: &rng)
        return items
    }

    private var totalCards: Int { calibrationItems.count }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerSection
                progressSection

                cardSection
                    .padding(.top, 12)

                hintSection
            }
            .padding(.horizontal, 16)
            .opacity(showUpdating ? 0 : 1)

            if showUpdating {
                updatingOverlay
                    .transition(.opacity)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip") {
                    Haptics.tap()
                    path.append(Route.result(profile, recommendations))
                }
                .foregroundStyle(Theme.muted)
                .font(.callout.weight(.medium))
            }
        }
        .alert("Reset calibration?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                vector = TasteVector.zero
                swipeCount = 0
                currentIndex = 0
                CalibrationStore.delete(for: profile.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears all swipe data for this profile and starts fresh.")
        }
        .onAppear {
            guard !didLoadExisting else { return }
            didLoadExisting = true
            if let existing = CalibrationStore.load(for: profile.id) {
                vector = existing.vector
                swipeCount = existing.swipeCount
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showUpdating)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("CALIBRATION")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.2)
                Spacer()
                if swipeCount > 0 || CalibrationStore.load(for: profile.id) != nil {
                    Button {
                        showResetConfirmation = true
                    } label: {
                        Text("Reset")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.muted)
                    }
                }
            }

            Text("Swipe to refine your taste")
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 6) {
            Text("\(min(currentIndex + 1, totalCards)) of \(totalCards)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.muted)

            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.hairline)
                    .frame(height: 3)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.accent)
                            .frame(
                                width: totalCards > 0
                                    ? geo.size.width * CGFloat(currentIndex) / CGFloat(totalCards)
                                    : 0,
                                height: 3
                            )
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    }
            }
            .frame(height: 3)
        }
        .padding(.top, 12)
    }

    // MARK: - Card

    private var cardSection: some View {
        ZStack {
            if currentIndex < totalCards {
                // Next card preview
                if currentIndex + 1 < totalCards {
                    cardContent(for: calibrationItems[currentIndex + 1])
                        .scaleEffect(0.95)
                        .opacity(0.4)
                }

                // Current card
                cardContent(for: calibrationItems[currentIndex])
                    .offset(dragOffset)
                    .rotationEffect(.degrees(Double(dragOffset.width) / 20))
                    .gesture(swipeGesture)
                    .overlay(swipeIndicator)
            } else if !showUpdating {
                completionView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func cardContent(for item: CatalogItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient placeholder for item image — fills available space
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        colors: [Theme.surface, Theme.hairline],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxHeight: .infinity)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.muted.opacity(0.3))
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)

                if let tag = item.tags.first {
                    Text(tag.rawValue.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .tracking(0.8)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.bg)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var swipeIndicator: some View {
        ZStack {
            if let direction = dragDirection {
                switch direction {
                case .right:
                    indicatorLabel("YES", color: Theme.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 24)
                case .left:
                    indicatorLabel("NOPE", color: Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 24)
                case .up:
                    indicatorLabel("LOVE", color: Theme.accent)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 24)
                }
            }
        }
    }

    private func indicatorLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius)
                    .stroke(color, lineWidth: 2)
            )
            .opacity(min(1, max(abs(dragOffset.width), abs(dragOffset.height)) / swipeThresholdX))
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
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
                let h = value.translation.width
                let v = value.translation.height

                if v < -swipeThresholdY && abs(h) < swipeThresholdX {
                    executeSwipe(.up, flyOut: CGSize(width: 0, height: -600))
                } else if h > swipeThresholdX {
                    executeSwipe(.right, flyOut: CGSize(width: 500, height: 0))
                } else if h < -swipeThresholdX {
                    executeSwipe(.left, flyOut: CGSize(width: -500, height: 0))
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dragOffset = .zero
                        dragDirection = nil
                    }
                }
            }
    }

    private func executeSwipe(_ direction: SwipeDirection, flyOut: CGSize) {
        let item = calibrationItems[currentIndex]
        guard let primaryTag = item.tags.first else { return }
        let tagKey = String(describing: primaryTag)

        Haptics.tap()

        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = flyOut
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            vector.applySwipe(tag: tagKey, direction: direction)
            swipeCount += 1
            currentIndex += 1
            dragOffset = .zero
            dragDirection = nil

            if currentIndex >= totalCards {
                finishCalibration()
            }
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent)

            Text("Calibration complete")
                .font(.headline)
                .foregroundStyle(Theme.ink)
        }
        .transition(.opacity)
    }

    // MARK: - Updating Overlay

    private var updatingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Theme.accent)

            Text("Updating profile\u{2026}")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func finishCalibration() {
        Haptics.success()

        let record = CalibrationRecord(
            tasteProfileId: profile.id,
            vector: vector.normalized(),
            swipeCount: swipeCount,
            createdAt: Date()
        )
        CalibrationStore.save(record)

        // Show transition
        showUpdating = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            path.append(Route.result(profile, recommendations))
        }
    }

    // MARK: - Hint

    private var hintSection: some View {
        HStack(spacing: 24) {
            hintItem(icon: "arrow.left", label: "Nope")
            hintItem(icon: "arrow.up", label: "Love")
            hintItem(icon: "arrow.right", label: "Yes")
        }
        .padding(.bottom, 16)
    }

    private func hintItem(icon: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Theme.muted)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Theme.muted)
        }
    }
}

// MARK: - Seeded RNG (deterministic shuffle)

private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
        // Warm up
        for _ in 0..<10 { _ = next() }
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
