import SwiftUI

struct ObjectsCalibrationScreen: View {
    @Binding var path: NavigationPath
    let profile: TasteProfile
    let recommendations: [RecommendationItem]

    @State private var vector = ObjectVector.zero
    @State private var swipeCount = 0
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragDirection: SwipeDirection?
    @State private var showUpdating = false
    @State private var showResetConfirmation = false
    @State private var didLoadExisting = false

    private let swipeThresholdX: CGFloat = 100
    private let swipeThresholdY: CGFloat = 80

    // MARK: - Calibration Items

    /// Cards from commerce_objects catalog, 2-3 per ObjectAxis, deterministic shuffle.
    private var calibrationItems: [CatalogItem] {
        let catalog = DomainCatalog.items(for: .objects)
        var axisBuckets: [ObjectAxis: [CatalogItem]] = [:]
        for axis in ObjectAxis.allCases { axisBuckets[axis] = [] }

        for item in catalog {
            if let dominant = dominantObjectAxis(item: item),
               var bucket = axisBuckets[dominant], bucket.count < 3 {
                bucket.append(item)
                axisBuckets[dominant] = bucket
            }
        }

        var items: [CatalogItem] = []
        for axis in ObjectAxis.allCases {
            items.append(contentsOf: axisBuckets[axis] ?? [])
        }

        var rng = SeededRNG(seed: profile.id.hashValue)
        items.shuffle(using: &rng)
        return items
    }

    private func dominantObjectAxis(item: CatalogItem) -> ObjectAxis? {
        let weights = item.objectAxisWeights
        guard !weights.isEmpty else { return nil }
        return weights.max(by: { abs($0.value) < abs($1.value) })
            .flatMap { ObjectAxis(rawValue: $0.key) }
    }

    private var totalSwipeCards: Int { calibrationItems.count }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                swipePhaseContent
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
                    path.append(Route.result(profile, recommendations, .objects))
                }
                .foregroundStyle(Theme.muted)
                .font(.callout.weight(.medium))
            }
        }
        .alert("Reset calibration?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                vector = ObjectVector.zero
                swipeCount = 0
                currentIndex = 0
                ObjectCalibrationStore.delete(for: profile.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears all object calibration data and starts fresh.")
        }
        .onAppear {
            guard !didLoadExisting else { return }
            didLoadExisting = true
            if let existing = ObjectCalibrationStore.load(for: profile.id) {
                vector = existing.vector
                swipeCount = existing.swipeCount
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showUpdating)
    }

    // MARK: - Swipe Phase

    private var swipePhaseContent: some View {
        VStack(spacing: 0) {
            headerSection(title: "CALIBRATION", subtitle: "Swipe to map your object taste")
            swipeProgress

            ZStack {
                if currentIndex < totalSwipeCards {
                    if currentIndex + 1 < totalSwipeCards {
                        swipeCardContent(for: calibrationItems[currentIndex + 1])
                            .scaleEffect(0.95)
                            .opacity(0.4)
                    }

                    swipeCardContent(for: calibrationItems[currentIndex])
                        .offset(dragOffset)
                        .rotationEffect(.degrees(Double(dragOffset.width) / 20))
                        .gesture(swipeGesture)
                        .overlay(swipeIndicator)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 12)

            hintSection
        }
    }

    private var swipeProgress: some View {
        VStack(spacing: 6) {
            Text("\(min(currentIndex + 1, totalSwipeCards)) of \(totalSwipeCards)")
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
                                width: totalSwipeCards > 0
                                    ? geo.size.width * CGFloat(currentIndex) / CGFloat(totalSwipeCards)
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

    private func swipeCardContent(for item: CatalogItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
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

                Text(item.category.rawValue.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(0.8)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
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
        guard let dominant = dominantObjectAxis(item: item) else { return }

        Haptics.tap()

        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = flyOut
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            vector.applySwipe(axis: dominant, direction: direction)
            swipeCount += 1
            currentIndex += 1
            dragOffset = .zero
            dragDirection = nil

            if currentIndex >= totalSwipeCards {
                finishCalibration()
            }
        }
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

    // MARK: - Completion

    private func finishCalibration() {
        Haptics.success()

        let record = ObjectCalibrationRecord(
            tasteProfileId: profile.id,
            vector: vector.normalized(),
            swipeCount: swipeCount,
            createdAt: Date()
        )
        ObjectCalibrationStore.save(record)

        showUpdating = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            path.append(Route.result(profile, recommendations, .objects))
        }
    }

    private var updatingOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Theme.accent)
            Text("Updating\u{2026}")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Shared

    private func headerSection(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.2)
                Spacer()
                if swipeCount > 0 || ObjectCalibrationStore.load(for: profile.id) != nil {
                    Button {
                        showResetConfirmation = true
                    } label: {
                        Text("Reset")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.muted)
                    }
                }
            }

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

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
