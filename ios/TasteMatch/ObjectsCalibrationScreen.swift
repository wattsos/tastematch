import SwiftUI

struct ObjectsCalibrationScreen: View {
    @Binding var path: NavigationPath
    let profile: TasteProfile
    let recommendations: [RecommendationItem]

    @State private var vector = ObjectVector.zero
    @State private var swipeCount = 0
    @State private var duelCount = 0
    @State private var archetypeAffinities: [String: Double] = [:]
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragDirection: SwipeDirection?
    @State private var phase: CalibrationPhase = .swipe
    @State private var showUpdating = false
    @State private var showResetConfirmation = false
    @State private var didLoadExisting = false
    @State private var showTransition = false
    @State private var duelPairs: [(ObjectArchetype, ObjectArchetype)] = []
    @State private var duelIndex = 0

    private let swipeThresholdX: CGFloat = 100
    private let swipeThresholdY: CGFloat = 80
    private let minDuels = 8
    private let maxDuels = 12

    private enum CalibrationPhase {
        case swipe, transition, duel
    }

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
                switch phase {
                case .swipe:
                    swipePhaseContent
                case .transition:
                    EmptyView()
                case .duel:
                    duelPhaseContent
                }
            }
            .padding(.horizontal, 16)
            .opacity(showUpdating || showTransition ? 0 : 1)

            if showTransition {
                transitionOverlay
                    .transition(.opacity)
            }

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
                duelCount = 0
                archetypeAffinities = [:]
                currentIndex = 0
                duelIndex = 0
                phase = .swipe
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
                duelCount = existing.duelCount
                archetypeAffinities = existing.archetypeAffinities
            }
            duelPairs = ObjectArchetype.generateDuelPairs(count: maxDuels, profileId: profile.id)
        }
        .animation(.easeInOut(duration: 0.3), value: showUpdating)
        .animation(.easeInOut(duration: 0.3), value: showTransition)
    }

    // MARK: - Phase A: Swipe

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
                beginDuelPhase()
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

    // MARK: - Phase Transition

    private func beginDuelPhase() {
        showTransition = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showTransition = false
            phase = .duel
        }
    }

    private var transitionOverlay: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Theme.accent)
            Text("Reading your signals\u{2026}")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Phase B: Duel

    private var duelPhaseContent: some View {
        VStack(spacing: 0) {
            headerSection(title: "ARCHETYPE DUEL", subtitle: "Choose the one that fits")
            duelProgress

            if duelIndex < duelPairs.count {
                let pair = duelPairs[duelIndex]
                HStack(spacing: 12) {
                    duelCard(pair.0)
                    duelCard(pair.1)
                }
                .padding(.top, 24)
            }

            Spacer()
        }
    }

    private var duelProgress: some View {
        VStack(spacing: 6) {
            Text("\(duelIndex + 1) of \(requiredDuels)")
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
                                width: requiredDuels > 0
                                    ? geo.size.width * CGFloat(duelIndex) / CGFloat(requiredDuels)
                                    : 0,
                                height: 3
                            )
                            .animation(.easeInOut(duration: 0.3), value: duelIndex)
                    }
            }
            .frame(height: 3)
        }
        .padding(.top, 12)
    }

    private var requiredDuels: Int {
        let topAffinity = archetypeAffinities.values.max() ?? 0
        if duelCount >= minDuels && topAffinity >= 0.3 {
            return duelCount
        }
        return min(maxDuels, max(minDuels, duelCount + 1))
    }

    private func duelCard(_ archetype: ObjectArchetype) -> some View {
        let sig = archetype.signature
        return Button {
            Haptics.tap()
            ObjectArchetype.applyDuelResult(
                winner: archetype,
                vector: &vector,
                affinities: &archetypeAffinities
            )
            duelCount += 1
            duelIndex += 1

            let topAffinity = archetypeAffinities.values.max() ?? 0
            if duelIndex >= maxDuels || (duelIndex >= minDuels && topAffinity >= 0.3) {
                finishCalibration()
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Text(sig.name.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .tracking(0.8)

                Text(sig.tagline)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    ForEach(sig.keywords, id: \.self) { kw in
                        Text(kw)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.muted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Theme.bg)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion

    private func finishCalibration() {
        Haptics.success()

        let record = ObjectCalibrationRecord(
            tasteProfileId: profile.id,
            vector: vector.normalized(),
            swipeCount: swipeCount,
            duelCount: duelCount,
            archetypeAffinities: archetypeAffinities,
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
