import SwiftUI

struct ResultScreen: View {
    @Binding var path: NavigationPath
    let profile: TasteProfile
    let recommendations: [RecommendationItem]
    @Environment(\.openURL) private var openURL
    @State private var showShareSheet = false
    @State private var showCardShareSheet = false
    @State private var cardImage: UIImage?
    @State private var favoritedIds: Set<String> = []
    @State private var sortMode: SortMode = .match
    @State private var revealHero = false
    @State private var revealStory = false
    @State private var revealPicks = false
    @State private var showDetails = false
    @State private var calibrationRecord: CalibrationRecord?
    @State private var variants: [TasteVariant] = []
    @State private var variantLabels: [String] = []
    @State private var discoveryRanked: [DiscoveryItem] = []
    @State private var discoveryLoaded: [DiscoveryItem] = []
    @State private var discoveryOffset = 0
    @State private var discoveryHasMore = false
    @State private var discoverySignals: DiscoverySignals?
    @State private var namingResult: ProfileNamingResult?
    @State private var readingText: String = ""
    @State private var expandedMaterialIds: Set<String> = []
    @State private var materialShopItem: DiscoveryItem? = nil
    @State private var toastMessage: String? = nil

    private enum SortMode: String, CaseIterable {
        case match = "Best Match"
        case priceLow = "Price ↑"
        case priceHigh = "Price ↓"
    }

    private var sortedRecommendations: [RecommendationItem] {
        var items = recommendations
        switch sortMode {
        case .match: break
        case .priceLow: items.sort { $0.price < $1.price }
        case .priceHigh: items.sort { $0.price > $1.price }
        }
        return items
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                    readingSection
                    calibrationInfoSection
                    inYourWorldSection
                    justOutsideSection
                    outThereSection
                    shopEntrySection
                    detailsSection

                    if favoritedIds.count >= 3 {
                        Spacer().frame(height: 52)
                    }
                }
                .padding(16)
            }

            if favoritedIds.count >= 3 {
                boardDock
            }

            if let toast = toastMessage {
                Text(toast)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, favoritedIds.count >= 3 ? 60 : 16)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.tap()
                    EventLogger.shared.logEvent("share_profile_tapped", tasteProfileId: profile.id)
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.callout)
                        .foregroundStyle(Theme.ink)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("New") {
                    Haptics.tap()
                    path = NavigationPath()
                }
                .foregroundStyle(Theme.ink)
                .font(.callout.weight(.semibold))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: shareSummary)
        }
        .sheet(isPresented: $showCardShareSheet) {
            if let image = cardImage {
                ImageShareSheet(image: image)
            }
        }
        .sheet(item: $materialShopItem) { material in
            MaterialShopSheet(material: material)
        }
        .onAppear {
            EventLogger.shared.logEvent("results_viewed", tasteProfileId: profile.id)
            refreshFavorites()
            calibrationRecord = CalibrationStore.load(for: profile.id)
            computeVariants()
            computeDiscovery()
            resolveProfileName()
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) { revealHero = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.45)) { revealStory = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.75)) { revealPicks = true }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let naming = namingResult, naming.didUpdate, naming.version > 1 {
                Text("PROFILE UPDATED")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.2)
            } else {
                Text("PROFILE 01")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.2)
            }

            if let naming = namingResult, !naming.name.isEmpty {
                Text(naming.name)
                    .font(.system(size: 48, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text(naming.description)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                if naming.didUpdate, naming.version > 1, let prev = naming.previousNames.last {
                    Text("Evolved from: \(prev)")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
            } else {
                Text(profile.displayName)
                    .font(.system(size: 48, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let primary = profile.tags.first {
                HStack(spacing: 10) {
                    Text("ALIGNMENT")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .tracking(1.2)
                    Text(alignmentWord(primary.confidence))
                        .font(.caption)
                        .foregroundStyle(Theme.ink)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Alignment \(alignmentWord(primary.confidence))")
            }
        }
        .padding(.top, 6)
        .opacity(revealHero ? 1 : 0)
        .offset(y: revealHero ? 0 : 18)
    }

    // MARK: - Reading

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("READING")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(1.2)

            Text(readingText.isEmpty ? profile.story : readingText)
                .foregroundStyle(Theme.ink)
                .font(.system(size: 18, weight: .regular))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .labSurface()
        .opacity(revealStory ? 1 : 0)
        .offset(y: revealStory ? 0 : 14)
    }

    // MARK: - Calibration Info

    @ViewBuilder
    private var calibrationInfoSection: some View {
        if let record = calibrationRecord {
            let level = record.vector.confidenceLevel(swipeCount: record.swipeCount)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("CALIBRATION")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .tracking(1.2)
                    Spacer()
                    Button {
                        Haptics.tap()
                        CalibrationStore.delete(for: profile.id)
                        calibrationRecord = nil
                    } label: {
                        Text("Reset")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Theme.muted)
                    }
                }

                let axisScores = AxisMapping.computeAxisScores(from: record.vector)
                let influencePhrases = AxisPresentation.influencePhrases(axisScores: axisScores)
                if !influencePhrases.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("INFLUENCES")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                            .tracking(1.0)

                        FlowLayout(spacing: 6) {
                            ForEach(influencePhrases, id: \.self) { phrase in
                                Text(phrase)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.bg)
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                        }
                    }
                }

                let avoidPhrases = AxisPresentation.avoidPhrases(axisScores: axisScores)
                if !avoidPhrases.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AVOIDS")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                            .tracking(1.0)

                        FlowLayout(spacing: 6) {
                            ForEach(avoidPhrases, id: \.self) { phrase in
                                Text(phrase)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(Theme.muted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.bg)
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                        }
                    }
                }

                HStack(spacing: 10) {
                    Text("CONFIDENCE")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .tracking(1.0)
                    Text(level)
                        .font(.caption2)
                        .foregroundStyle(Theme.ink)
                }
            }
            .labSurface(padded: true, bordered: true)
        }
    }

    // MARK: - In Your World

    private var inYourWorldSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("IN YOUR WORLD")
                    .sectionLabel()
                Spacer()
                Picker("Sort", selection: $sortMode) {
                    ForEach(SortMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.muted)
            }

            if sortedRecommendations.isEmpty {
                Text("No pieces matched your profile.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    ForEach(sortedRecommendations) { item in
                        Button {
                            EventLogger.shared.logEvent("pick_tapped", tasteProfileId: profile.id, metadata: ["skuId": item.skuId])
                            path.append(Route.recommendationDetail(item, tasteProfileId: profile.id))
                        } label: {
                            pickCard(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, 8)
        .opacity(revealPicks ? 1 : 0)
        .offset(y: revealPicks ? 0 : 12)
    }

    // MARK: - Just Outside

    private var justOutsideSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("JUST OUTSIDE")
                .sectionLabel()

            ForEach(Array(variants.enumerated()), id: \.offset) { index, variant in
                VStack(alignment: .leading, spacing: 10) {
                    Text(index < variantLabels.count ? variantLabels[index] : variant.label)
                        .font(.system(.subheadline, design: .serif, weight: .medium))
                        .foregroundStyle(Theme.ink)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(variantItems(for: variant).prefix(8))) { item in
                                Button {
                                    path.append(Route.recommendationDetail(item, tasteProfileId: profile.id))
                                } label: {
                                    compactCard(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private func variantItems(for variant: TasteVariant) -> [RecommendationItem] {
        RecommendationEngine.rankWithVector(
            recommendations,
            vector: variant.vector,
            catalog: MockCatalog.items,
            context: nil,
            goal: nil
        )
    }

    private func compactCard(_ item: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedImage(url: item.imageURL, height: 110, width: 140)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text("$\(Int(item.price))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Theme.muted)
            }
            .padding(8)
        }
        .frame(width: 140)
        .labSurface(padded: false, bordered: true)
    }

    // MARK: - Out There

    @ViewBuilder
    private var outThereSection: some View {
        if !discoveryLoaded.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                Text("OUT THERE")
                    .sectionLabel()

                let cultural = discoveryLoaded.filter { $0.layer == .culturalSignals }
                if !cultural.isEmpty {
                    discoverySubsection("CULTURAL SIGNALS", items: cultural)
                }

                let objects = discoveryLoaded.filter { $0.layer == .objectsInTheWild }
                if !objects.isEmpty {
                    discoverySubsection("OBJECTS IN THE WILD", items: objects)
                }

                let materials = discoveryLoaded.filter { $0.layer == .materialIntelligence }
                if !materials.isEmpty {
                    discoverySubsection("MATERIAL INTELLIGENCE", items: materials)
                }

                if discoveryHasMore {
                    Color.clear
                        .frame(height: 1)
                        .onAppear { loadMoreDiscovery() }
                }
            }
            .padding(.top, 8)
        }
    }

    private func discoverySubsection(_ header: String, items: [DiscoveryItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(header)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(0.8)
                .padding(.top, 4)

            ForEach(items) { item in
                if item.type == .material {
                    materialCard(item)
                } else {
                    Button {
                        DiscoverySignalStore.recordViewed(item.id, profileId: profile.id, item: item)
                        path.append(Route.discoveryDetail(item))
                    } label: {
                        discoveryCard(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func discoveryCard(_ item: DiscoveryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.type.rawValue.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.0)
                Spacer()
                Button {
                    Haptics.tap()
                    toggleDiscoverySaved(item)
                } label: {
                    Image(systemName: isDiscoverySaved(item) ? "bookmark.fill" : "bookmark")
                        .font(.caption2)
                        .foregroundStyle(isDiscoverySaved(item) ? Theme.accent : Theme.muted)
                }
                .buttonStyle(.plain)
            }

            Text(item.title)
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)

            if !item.primaryRegion.isEmpty {
                Text(item.primaryRegion)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }

            Text(item.body)
                .font(.caption)
                .foregroundStyle(Theme.muted)
                .lineLimit(3)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .labSurface(padded: true, bordered: true)
        .contextMenu {
            Button(role: .destructive) {
                dismissDiscoveryItem(item)
            } label: {
                Label("Not for me", systemImage: "hand.thumbsdown")
            }
        }
    }

    private func materialCard(_ item: DiscoveryItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.type.rawValue.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.0)
                Spacer()
                Button {
                    Haptics.tap()
                    toggleDiscoverySaved(item)
                } label: {
                    Image(systemName: isDiscoverySaved(item) ? "bookmark.fill" : "bookmark")
                        .font(.caption2)
                        .foregroundStyle(isDiscoverySaved(item) ? Theme.accent : Theme.muted)
                }
                .buttonStyle(.plain)
            }

            Text(item.title)
                .font(.system(.subheadline, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)

            if !item.primaryRegion.isEmpty {
                Text(item.primaryRegion)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }

            Button {
                EventLogger.shared.logEvent(
                    "material_shop_tapped",
                    tasteProfileId: profile.id,
                    metadata: ["itemId": item.id, "title": item.title]
                )
                materialShopItem = item
            } label: {
                Text("Shop With This")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if expandedMaterialIds.contains(item.id) {
                        expandedMaterialIds.remove(item.id)
                    } else {
                        expandedMaterialIds.insert(item.id)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .rotationEffect(expandedMaterialIds.contains(item.id) ? .degrees(90) : .degrees(0))
                    Text("Why this matters")
                        .font(.caption)
                }
                .foregroundStyle(Theme.muted)
            }
            .buttonStyle(.plain)

            if expandedMaterialIds.contains(item.id) {
                Text(item.body)
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(2)
            }

            HStack {
                Spacer()
                Button {
                    applyMaterialShift(item)
                } label: {
                    Text("Lean into this")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .labSurface(padded: true, bordered: true)
        .contextMenu {
            Button(role: .destructive) {
                dismissDiscoveryItem(item)
            } label: {
                Label("Not for me", systemImage: "hand.thumbsdown")
            }
        }
    }

    private func applyMaterialShift(_ item: DiscoveryItem) {
        let synthetic = AxisMapping.syntheticVector(fromAxes: item.axisWeights)
        var scaled: [String: Double] = [:]
        for (key, val) in synthetic.weights {
            scaled[key] = val * 0.15
        }

        var record = calibrationRecord ?? CalibrationRecord(
            tasteProfileId: profile.id,
            vector: resolveBaseVector(),
            swipeCount: 0,
            createdAt: Date()
        )

        for (key, val) in scaled {
            record.vector.weights[key, default: 0] += val
        }
        record.vector = record.vector.normalized()

        CalibrationStore.save(record)
        calibrationRecord = record

        EventLogger.shared.logEvent(
            "material_shift_applied",
            tasteProfileId: profile.id,
            metadata: ["itemId": item.id, "title": item.title]
        )

        Haptics.success()
        withAnimation { toastMessage = "Profile shifted." }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastMessage = nil }
        }
    }

    private func isDiscoverySaved(_ item: DiscoveryItem) -> Bool {
        discoverySignals?.savedIds.contains(item.id) ?? false
    }

    private func toggleDiscoverySaved(_ item: DiscoveryItem) {
        if isDiscoverySaved(item) {
            discoverySignals?.savedIds.remove(item.id)
        } else {
            DiscoverySignalStore.recordSaved(item.id, profileId: profile.id, item: item)
            discoverySignals?.savedIds.insert(item.id)
        }
    }

    private func dismissDiscoveryItem(_ item: DiscoveryItem) {
        Haptics.tap()
        DiscoverySignalStore.recordDismissed(item.id, profileId: profile.id, item: item)
        discoverySignals?.dismissedIds.insert(item.id)
        discoveryLoaded.removeAll { $0.id == item.id }
    }

    // MARK: - Board Dock

    private var boardDock: some View {
        HStack {
            Text("\(favoritedIds.count) SAVED")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(1.0)
            Spacer()
            Button {
                Haptics.tap()
                path.append(Route.board(sortedRecommendations))
            } label: {
                Text("[ Open Board ]")
                    .font(.caption.weight(.medium).monospaced())
                    .foregroundStyle(Theme.ink)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .overlay(alignment: .top) {
            HairlineDivider()
        }
    }

    // MARK: - Pick Card

    private func pickCard(_ item: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CachedImage(url: item.imageURL, height: 150)

                Button {
                    toggleFavorite(item)
                } label: {
                    Image(systemName: isFavorited(item) ? "bookmark.fill" : "bookmark")
                        .font(.caption)
                        .foregroundStyle(isFavorited(item) ? Theme.accent : Theme.ink.opacity(0.55))
                        .padding(6)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                                .stroke(Theme.hairline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(6)
                .accessibilityLabel(isFavorited(item) ? "Saved" : "Save")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(.subheadline, design: .default, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)

                Text("$\(Int(item.price))")
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .labSurface(padded: false, bordered: true)
    }

    // MARK: - Shop Entry

    private var shopEntrySection: some View {
        Button {
            Haptics.tap()
            EventLogger.shared.logEvent("shop_opened", tasteProfileId: profile.id)
            path.append(Route.shop(profile))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("ENTER SHOP")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.2)

                Text("Browse inside your profile.")
                    .font(.system(.subheadline, design: .serif, weight: .medium))
                    .foregroundStyle(Theme.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .labSurface(padded: true, bordered: true)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    // MARK: - Details (Collapsed)

    private var detailsSection: some View {
        DisclosureGroup(isExpanded: $showDetails) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 8) {
                    ForEach(profile.signals) { signal in
                        HStack {
                            Text(signal.key.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .foregroundStyle(Theme.muted)
                            Spacer()
                            Text(signal.value.capitalized)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }

                let tips = DesignTipsEngine.tips(for: profile)
                if !tips.isEmpty {
                    HairlineDivider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Design Tips")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.ink)

                        ForEach(tips) { tip in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: tip.icon)
                                    .font(.caption)
                                    .foregroundStyle(Theme.muted)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tip.headline)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Theme.ink)
                                    Text(tip.body)
                                        .font(.caption2)
                                        .foregroundStyle(Theme.muted)
                                        .lineSpacing(2)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 14)
        } label: {
            Text("Details")
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.ink)
        }
        .tint(Theme.muted)
        .labSurface(padded: true, bordered: true)
    }

    // MARK: - Compute

    private func computeVariants() {
        let baseVector = resolveBaseVector()
        variants = baseVector.generateVariants()
        let baseScores = AxisMapping.computeAxisScores(from: baseVector)
        variantLabels = variants.map { variant in
            let variantScores = AxisMapping.computeAxisScores(from: variant.vector)
            var maxDelta = 0.0
            var maxAxis: Axis = .minimalOrnate
            for axis in Axis.allCases {
                let delta = variantScores.value(for: axis) - baseScores.value(for: axis)
                if abs(delta) > abs(maxDelta) {
                    maxDelta = delta
                    maxAxis = axis
                }
            }
            return axisPoetPhrase(maxAxis, positive: maxDelta >= 0)
        }
    }

    private func computeDiscovery() {
        let baseVector = resolveBaseVector()
        let scores = AxisMapping.computeAxisScores(from: baseVector)
        let allItems = DiscoveryEngine.loadAll()
        let signals = DiscoverySignalStore.load(for: profile.id)
        discoverySignals = signals
        discoveryRanked = DiscoveryEngine.rank(items: allItems, axisScores: scores, signals: signals)
        discoveryOffset = 0
        discoveryLoaded = []
        loadMoreDiscovery()
    }

    private func loadMoreDiscovery() {
        let result = DiscoveryEngine.page(discoveryRanked, offset: discoveryOffset)
        discoveryLoaded.append(contentsOf: result.items)
        discoveryHasMore = result.hasMore
        discoveryOffset += result.items.count
    }

    private func resolveBaseVector() -> TasteVector {
        if let record = CalibrationStore.load(for: profile.id) {
            let imageVector = TasteEngine.vectorFromProfile(profile)
            return TasteVector.blend(
                image: imageVector,
                swipe: record.vector.normalized(),
                mode: .wantMore
            )
        } else {
            return TasteEngine.vectorFromProfile(profile)
        }
    }

    private func axisPoetPhrase(_ axis: Axis, positive: Bool) -> String {
        switch (axis, positive) {
        case (.minimalOrnate, false): return "Strip Back"
        case (.minimalOrnate, true): return "Layer In"
        case (.warmCool, true): return "Add Warmth"
        case (.warmCool, false): return "Cool Down"
        case (.softStructured, true): return "Sharpen Edges"
        case (.softStructured, false): return "Soften"
        case (.organicIndustrial, true): return "Go Raw"
        case (.organicIndustrial, false): return "Go Natural"
        case (.lightDark, true): return "Lean Darker"
        case (.lightDark, false): return "Lighten Up"
        case (.neutralSaturated, true): return "Add Color"
        case (.neutralSaturated, false): return "Desaturate"
        case (.sparseLayered, true): return "Build Density"
        case (.sparseLayered, false): return "Open Up"
        }
    }

    // MARK: - Profile Naming

    private func resolveProfileName() {
        let stored = ProfileStore.loadAll().first(where: { $0.id == profile.id })
        let existingProfile = stored?.tasteProfile ?? profile
        let vector = resolveBaseVector()
        let swipeCount = calibrationRecord?.swipeCount ?? 0
        let result = ProfileNamingEngine.resolve(
            vector: vector, swipeCount: swipeCount, existingProfile: existingProfile
        )
        namingResult = result
        if result.didUpdate {
            ProfileStore.updateNaming(profileId: profile.id, result: result)
        }

        // Compute axis-based reading text
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        let name = result.name.isEmpty ? profile.displayName : result.name
        readingText = AxisPresentation.oneLineReading(
            profileName: name,
            axisScores: axisScores
        )
    }

    // MARK: - Favorites

    private func isFavorited(_ item: RecommendationItem) -> Bool {
        favoritedIds.contains(favoriteKey(item))
    }

    private func toggleFavorite(_ item: RecommendationItem) {
        Haptics.tap()
        let meta = ["skuId": item.skuId, "merchant": item.merchant, "source": "results_grid"]
        let key = favoriteKey(item)
        if favoritedIds.contains(key) {
            favoritedIds.remove(key)
            let stored = FavoritesStore.loadAll()
            if let match = stored.first(where: { $0.title == item.title && $0.subtitle == item.subtitle }) {
                FavoritesStore.remove(id: match.id)
            }
            EventLogger.shared.logEvent("product_unsaved", tasteProfileId: profile.id, metadata: meta)
        } else {
            favoritedIds.insert(key)
            FavoritesStore.add(item)
            EventLogger.shared.logEvent("product_saved", tasteProfileId: profile.id, metadata: meta)
        }
    }

    private func refreshFavorites() {
        let stored = FavoritesStore.loadAll()
        favoritedIds = Set(stored.map { "\($0.title)|\($0.subtitle)" })
    }

    private func favoriteKey(_ item: RecommendationItem) -> String {
        "\(item.title)|\(item.subtitle)"
    }

    // MARK: - Helpers

    private func alignmentWord(_ confidence: Double) -> String {
        switch confidence {
        case 0.8...: return "High"
        case 0.5...: return "Moderate"
        default:     return "Low"
        }
    }

    private func confidenceColor(_ value: Double) -> Color {
        switch value {
        case 0.8...: return Theme.strongMatch
        case 0.5...: return Theme.goodMatch
        default:     return Theme.partialMatch
        }
    }

    // MARK: - Share

    private var shareSummary: String {
        ShareTextBuilder.build(profile: profile, recommendations: sortedRecommendations)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Image Share Sheet

struct ImageShareSheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (i, row) in rows.enumerated() {
            let maxH = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            height += maxH
            if i > 0 { height += spacing }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for (i, row) in rows.enumerated() {
            if i > 0 { y += spacing }
            var x = bounds.minX
            let maxH = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += maxH
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[LayoutSubview]] = [[]]
        var currentWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentWidth += size.width + spacing
        }
        return rows
    }
}
