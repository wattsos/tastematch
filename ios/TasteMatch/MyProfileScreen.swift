import SwiftUI

private struct ShiftDirection: Identifiable {
    let id: String
    let label: String
    let axis: Axis
    let delta: Double
    let products: [RecommendationItem]
}

private struct MaterialGroup: Identifiable {
    let id: String
    let name: String
    let items: [RecommendationItem]
}

struct MyProfileScreen: View {
    let profileId: UUID
    @Binding var path: NavigationPath

    @State private var saved: SavedProfile?
    @State private var calibrationRecord: CalibrationRecord?
    @State private var vector: TasteVector = .zero
    @State private var axisScores: AxisScores = .zero
    @State private var namingResult: ProfileNamingResult?
    @State private var topCommerce: [RecommendationItem] = []
    @State private var topDiscovery: [DiscoveryItem] = []
    @State private var showShareSheet = false
    @State private var favoritedIds: Set<String> = []
    @State private var discoveryRelated: [String: [RecommendationItem]] = [:]
    @State private var toastMessage: String? = nil
    @State private var heroObjects: [RecommendationItem] = []
    @State private var shiftDirections: [ShiftDirection] = []
    @State private var materialSections: [MaterialGroup] = []
    @State private var pulseRadar = false
    @State private var signalShopItem: DiscoveryItem? = nil
    @State private var currentDomain: TasteDomain = DomainStore.current
    @State private var domainName: String? = nil
    @State private var currentCatalog: [CatalogItem] = []
    @State private var showDomainPrompt = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    if let saved {
                        VStack(alignment: .leading, spacing: 32) {
                            identitySection(saved)

                            Button {
                                Haptics.tap()
                                withAnimation {
                                    proxy.scrollTo("radar", anchor: .top)
                                }
                                pulseRadar = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                                    pulseRadar = false
                                }
                            } label: {
                                Text("Run today's scan")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Theme.ink)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                            }
                            .buttonStyle(.plain)

                            worldSection
                            evolutionSection(saved)
                            radarSection(saved)
                                .id("radar")
                            materialsSection
                        }
                        .padding(16)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 120)
                    }
                }
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
                    .padding(.bottom, 16)
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.tap()
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
                    let enabled = DomainPreferencesStore.enabledDomains
                    if enabled.count > 1 {
                        showDomainPrompt = true
                    } else {
                        path.append(Route.newScan(enabled.first ?? .space))
                    }
                }
                .foregroundStyle(Theme.ink)
                .font(.callout.weight(.semibold))
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let saved {
                ShareSheet(text: ShareTextBuilder.build(
                    profile: saved.tasteProfile,
                    recommendations: saved.recommendations
                ))
            }
        }
        .sheet(item: $signalShopItem) { item in
            MaterialShopSheet(material: item)
        }
        .confirmationDialog("What are we reading today?", isPresented: $showDomainPrompt, titleVisibility: .visible) {
            let enabled = DomainPreferencesStore.enabledDomains
            ForEach(TasteDomain.allCases.filter { enabled.contains($0) }) { d in
                Button(d.displayLabel) {
                    path.append(Route.newScan(d))
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear { loadData() }
    }

    // MARK: - Data Loading

    private func loadData() {
        guard let s = ProfileStore.loadAll().first(where: { $0.id == profileId }) else { return }
        saved = s
        let profile = s.tasteProfile

        // Resolve default domain: lastViewed → primaryDomain → .space
        let resolved = DomainPreferencesStore.lastViewed(for: profileId)
            ?? DomainPreferencesStore.primaryDomain
        currentDomain = resolved
        DomainStore.current = resolved

        calibrationRecord = CalibrationStore.load(for: profileId)
        vector = resolveBaseVector(profile: profile)
        axisScores = AxisMapping.computeAxisScores(from: vector)

        let swipeCount = calibrationRecord?.swipeCount ?? 0
        let existingProfile = s.tasteProfile
        let result = ProfileNamingEngine.resolve(
            vector: vector, swipeCount: swipeCount, existingProfile: existingProfile
        )
        namingResult = result
        if result.didUpdate {
            ProfileStore.updateNaming(profileId: profileId, result: result)
        }

        currentCatalog = DomainCatalog.items(for: currentDomain)

        topCommerce = Array(RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: currentCatalog,
            domain: currentDomain, swipeCount: swipeCount
        ).prefix(20))

        heroObjects = computeHeroObjects(catalog: currentCatalog)

        let domainCluster = DomainDiscovery.identifyCluster(axisScores, domain: currentDomain)
        let allDiscovery = DomainDiscovery.items(for: currentDomain)
        let signals = DiscoverySignalStore.load(for: profileId)
        topDiscovery = DiscoveryEngine.dailyRadar(
            items: allDiscovery,
            axisScores: axisScores,
            signals: signals,
            profileId: profileId,
            vector: vector,
            dominantCluster: domainCluster
        )

        computeDiscoveryRelated(catalog: currentCatalog)
        shiftDirections = computeShiftDirections(catalog: currentCatalog)
        materialSections = computeMaterialSections(catalog: currentCatalog)
        favoritedIds = Set(FavoritesStore.loadAll().map { "\($0.title)|\($0.subtitle)" })

        if currentDomain != .space {
            let domainResult = ProfileNamingEngine.resolve(
                vector: vector, swipeCount: swipeCount,
                existingProfile: existingProfile, domain: currentDomain
            )
            domainName = domainResult.domainName
        } else {
            domainName = nil
        }
    }

    private func reloadForDomain(_ domain: TasteDomain) {
        let swipeCount = calibrationRecord?.swipeCount ?? 0

        currentCatalog = DomainCatalog.items(for: domain)

        topCommerce = Array(RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: currentCatalog,
            domain: domain, swipeCount: swipeCount
        ).prefix(20))

        heroObjects = computeHeroObjects(catalog: currentCatalog)

        let domainCluster = DomainDiscovery.identifyCluster(axisScores, domain: domain)
        let allDiscovery = DomainDiscovery.items(for: domain)
        let signals = DiscoverySignalStore.load(for: profileId)
        topDiscovery = DiscoveryEngine.dailyRadar(
            items: allDiscovery,
            axisScores: axisScores,
            signals: signals,
            profileId: profileId,
            vector: vector,
            dominantCluster: domainCluster
        )

        computeDiscoveryRelated(catalog: currentCatalog)
        shiftDirections = computeShiftDirections(catalog: currentCatalog)
        materialSections = computeMaterialSections(catalog: currentCatalog)

        if domain != .space, let saved {
            let domainResult = ProfileNamingEngine.resolve(
                vector: vector, swipeCount: swipeCount,
                existingProfile: saved.tasteProfile, domain: domain
            )
            domainName = domainResult.domainName
        } else {
            domainName = nil
        }
    }

    private func resolveBaseVector(profile: TasteProfile) -> TasteVector {
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

    private func computeHeroObjects(catalog: [CatalogItem]) -> [RecommendationItem] {
        let sorted = Axis.allCases.sorted { abs(axisScores.value(for: $0)) > abs(axisScores.value(for: $1)) }
        let topAxes = Array(sorted.prefix(3))
        let swipeCount = calibrationRecord?.swipeCount ?? 0
        let allRanked = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: catalog,
            domain: currentDomain, swipeCount: swipeCount
        )
        var usedSkus: Set<String> = []
        var heroes: [RecommendationItem] = []

        for axis in topAxes {
            let positive = axisScores.value(for: axis) >= 0
            if let hero = allRanked.first(where: { item in
                guard !usedSkus.contains(item.skuId) else { return false }
                guard let cat = catalog.first(where: { $0.skuId == item.skuId }) else { return false }
                let weight = cat.commerceAxisWeights[axis.rawValue] ?? 0
                return positive ? weight > 0 : weight < 0
            }) {
                heroes.append(hero)
                usedSkus.insert(hero.skuId)
            }
        }

        for item in allRanked where heroes.count < 3 && !usedSkus.contains(item.skuId) {
            heroes.append(item)
            usedSkus.insert(item.skuId)
        }

        return heroes
    }

    private func computeShiftDirections(catalog: [CatalogItem]) -> [ShiftDirection] {
        let sorted = Axis.allCases
            .sorted { abs(axisScores.value(for: $0)) > abs(axisScores.value(for: $1)) }
        let candidates = Array(sorted.dropFirst().prefix(4))
        var usedSkus = Set(topCommerce.map(\.skuId) + heroObjects.map(\.skuId))
        let swipeCount = calibrationRecord?.swipeCount ?? 0

        return candidates.map { axis in
            let score = axisScores.value(for: axis)
            let positive = score >= 0
            let delta: Double = positive ? 0.3 : -0.3
            let word = AxisPresentation.influenceWord(axis: axis, positive: positive)
            let prefix = abs(score) < 0.3 ? "Lean" : "Go"

            var shiftedAxes: [String: Double] = [:]
            for a in Axis.allCases {
                shiftedAxes[a.rawValue] = axisScores.value(for: a)
            }
            shiftedAxes[axis.rawValue]! += delta
            let shiftedVector = AxisMapping.syntheticVector(fromAxes: shiftedAxes)
            let shiftedScores = AxisMapping.computeAxisScores(from: shiftedVector)
            let ranked = RecommendationEngine.rankCommerceItems(
                vector: shiftedVector, axisScores: shiftedScores, items: catalog,
                domain: currentDomain, swipeCount: swipeCount
            )
            let products = Array(ranked.filter { !usedSkus.contains($0.skuId) }.prefix(3))
            for p in products { usedSkus.insert(p.skuId) }

            return ShiftDirection(
                id: axis.rawValue,
                label: "\(prefix) \(word)",
                axis: axis,
                delta: delta,
                products: products
            )
        }
    }

    private func computeDiscoveryRelated(catalog: [CatalogItem]) {
        var related: [String: [RecommendationItem]] = [:]
        let topCommerceIds = Set(topCommerce.map(\.skuId))
        let swipeCount = calibrationRecord?.swipeCount ?? 0
        for disc in topDiscovery {
            let sv = AxisMapping.syntheticVector(fromAxes: disc.axisWeights)
            let ss = AxisMapping.computeAxisScores(from: sv)
            let mf = disc.type == .material
                ? disc.title.split(separator: " ").last.map(String.init)
                : nil
            var ranked = RecommendationEngine.rankCommerceItems(
                vector: sv, axisScores: ss, items: catalog, materialFilter: mf,
                domain: currentDomain, swipeCount: swipeCount
            )
            var filtered = ranked.filter { !topCommerceIds.contains($0.skuId) }
            if filtered.count < 3, mf != nil {
                ranked = RecommendationEngine.rankCommerceItems(
                    vector: sv, axisScores: ss, items: catalog,
                    domain: currentDomain, swipeCount: swipeCount
                )
                filtered = ranked.filter { !topCommerceIds.contains($0.skuId) }
            }
            related[disc.id] = Array(filtered.prefix(3))
        }
        discoveryRelated = related
    }

    private func computeMaterialSections(catalog: [CatalogItem]) -> [MaterialGroup] {
        var tagCounts: [String: Int] = [:]
        for item in catalog {
            for mat in item.materialTags {
                tagCounts[mat, default: 0] += 1
            }
        }
        let topMaterials = tagCounts
            .filter { $0.value >= 4 }
            .sorted { $0.value > $1.value }
            .prefix(4)
        let usedSkus = Set(topCommerce.map(\.skuId))
        let swipeCount = calibrationRecord?.swipeCount ?? 0

        return topMaterials.compactMap { mat, _ in
            let ranked = RecommendationEngine.rankCommerceItems(
                vector: vector, axisScores: axisScores, items: catalog,
                materialFilter: mat, domain: currentDomain, swipeCount: swipeCount
            )
            let filtered = Array(ranked.filter { !usedSkus.contains($0.skuId) }.prefix(8))
            guard filtered.count >= 3 else { return nil }
            return MaterialGroup(id: mat, name: mat.uppercased(), items: filtered)
        }
    }

    private func rerank() {
        let swipeCount = calibrationRecord?.swipeCount ?? 0
        topCommerce = Array(RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: currentCatalog,
            domain: currentDomain, swipeCount: swipeCount
        ).prefix(20))
        heroObjects = computeHeroObjects(catalog: currentCatalog)
        computeDiscoveryRelated(catalog: currentCatalog)
        shiftDirections = computeShiftDirections(catalog: currentCatalog)
        materialSections = computeMaterialSections(catalog: currentCatalog)
    }

    // MARK: - Favorites & Save Shift

    private func isFavorited(_ item: RecommendationItem) -> Bool {
        favoritedIds.contains("\(item.title)|\(item.subtitle)")
    }

    private func toggleFavorite(_ item: RecommendationItem) {
        Haptics.tap()
        let key = "\(item.title)|\(item.subtitle)"
        if favoritedIds.contains(key) {
            favoritedIds.remove(key)
            FavoritesStore.remove(id: item.id)
        } else {
            favoritedIds.insert(key)
            FavoritesStore.add(item)
            applySaveShift(item)
        }
    }

    private func applySaveShift(_ item: RecommendationItem) {
        guard let catalogItem = currentCatalog.first(where: { $0.skuId == item.skuId }) else { return }
        for tag in catalogItem.tags {
            let key = String(describing: tag)
            vector.weights[key] = (vector.weights[key] ?? 0.0) + 0.05
        }
        vector = vector.normalized()
        axisScores = AxisMapping.computeAxisScores(from: vector)
        rerank()
        showToast("Saved. Your world updates.")
    }

    private func applyShift(_ direction: ShiftDirection) {
        Haptics.impact()
        for (tagKey, axisContrib) in AxisMapping.contributions {
            let contribution = axisContrib.value(for: direction.axis)
            if direction.delta * contribution > 0 {
                vector.weights[tagKey] = (vector.weights[tagKey] ?? 0) + 0.08
            }
        }
        vector = vector.normalized()
        axisScores = AxisMapping.computeAxisScores(from: vector)
        rerank()
        showToast("Profile shifted.")
    }

    private func showToast(_ message: String) {
        withAnimation {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                toastMessage = nil
            }
        }
    }

    // MARK: - Stability

    private var stability: String {
        guard let record = calibrationRecord else { return "Low" }
        return record.vector.stabilityLevel(swipeCount: record.swipeCount)
    }

    private var refineCTALabel: String {
        switch stability {
        case "Stable": return "Explore variations"
        case "Developing": return "Refine a bit more"
        default: return "Refine your profile"
        }
    }

    // MARK: - Domain Picker

    @ViewBuilder
    private var domainPicker: some View {
        let enabled = DomainPreferencesStore.enabledDomains
        let enabledList = TasteDomain.allCases.filter { enabled.contains($0) }
        if enabledList.count > 1 {
            Picker("Domain", selection: $currentDomain) {
                ForEach(enabledList) { d in Text(d.displayLabel).tag(d) }
            }
            .pickerStyle(.segmented)
            .onChange(of: currentDomain) { _, newDomain in
                DomainStore.current = newDomain
                DomainPreferencesStore.setLastViewed(domain: newDomain, for: profileId)
                reloadForDomain(newDomain)
            }
        }
    }

    // MARK: - Section A: Identity

    private func identitySection(_ saved: SavedProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROFILE 01")
                .sectionLabel()

            domainPicker

            if let naming = namingResult, !naming.name.isEmpty {
                Text(naming.name)
                    .font(.system(size: 48, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(saved.tasteProfile.displayName)
                    .font(.system(size: 48, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let dn = domainName, currentDomain != .space {
                Text(dn)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.0)
            }

            RadarChart(axisScores: axisScores)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

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

            let swipeCount = calibrationRecord?.swipeCount ?? 0
            let level = vector.confidenceLevel(swipeCount: swipeCount)
            HStack(spacing: 10) {
                Text("CONFIDENCE")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.0)
                Text(level)
                    .font(.caption2)
                    .foregroundStyle(Theme.ink)
            }

            if !heroObjects.isEmpty {
                Text(DomainLayout.config(for: currentDomain).heroLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.0)
                    .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(heroObjects) { item in
                            heroCard(item)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }

    private func heroCard(_ item: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Button {
                    path.append(Route.recommendationDetail(item, tasteProfileId: profileId))
                } label: {
                    CachedImage(url: item.resolvedImageURL, height: 200, width: 200)
                }
                .buttonStyle(.plain)

                Button {
                    toggleFavorite(item)
                } label: {
                    Image(systemName: isFavorited(item) ? "bookmark.fill" : "bookmark")
                        .font(.caption)
                        .foregroundStyle(Theme.ink)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.brand)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("$\(Int(item.price))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(width: 200)
        .labSurface(padded: false, bordered: true)
    }

    // MARK: - Section B: Your World / Uniform / Rarity

    @ViewBuilder
    private var worldSection: some View {
        let config = DomainLayout.config(for: currentDomain)
        if config.showWorldGrid {
            spaceWorldSection
        } else if config.showUniform {
            uniformSection
        } else if config.showRarityLanes {
            raritySection
        }
    }

    private var spaceWorldSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("YOUR WORLD")
                .sectionLabel()

            if topCommerce.isEmpty {
                Text("No pieces matched your profile.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(topCommerce) { item in
                        commerceCard(item)
                    }
                }
            }
        }
    }

    private var uniformItems: [RecommendationItem] {
        var seen = Set<ItemCategory>()
        var result: [RecommendationItem] = []
        for item in topCommerce {
            let cat = currentCatalog.first(where: { $0.skuId == item.skuId })?.category ?? .unknown
            if !seen.contains(cat) {
                seen.insert(cat)
                result.append(item)
            }
            if result.count >= 6 { break }
        }
        return result
    }

    private var uniformSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("UNIFORM")
                .sectionLabel()

            if uniformItems.isEmpty {
                Text("No pieces matched your profile.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(uniformItems) { item in
                            commerceCard(item, width: 160)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }

    private struct RarityLane: Identifiable {
        let id: String
        let tier: ArtRarityTier
        let label: String
        let items: [RecommendationItem]
    }

    private var rarityLanes: [RarityLane] {
        let tierLabels: [(ArtRarityTier, String)] = [
            (.archive, "ARCHIVE"),
            (.contemporary, "CONTEMPORARY"),
            (.emergent, "EMERGENT"),
        ]
        return tierLabels.compactMap { tier, label in
            let items = topCommerce.filter { item in
                currentCatalog.first(where: { $0.skuId == item.skuId })?.rarityTier == tier
            }
            guard !items.isEmpty else { return nil }
            return RarityLane(id: tier.rawValue, tier: tier, label: label, items: Array(items.prefix(8)))
        }
    }

    private var raritySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("RARITY")
                .sectionLabel()

            if rarityLanes.isEmpty {
                Text("No pieces matched your profile.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ForEach(rarityLanes) { lane in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(lane.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                            .tracking(1.0)

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 10) {
                                ForEach(lane.items) { item in
                                    commerceCard(item, width: 140)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }
            }
        }
    }

    private func commerceCard(_ item: RecommendationItem, width: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Button {
                    path.append(Route.recommendationDetail(item, tasteProfileId: profileId))
                } label: {
                    CachedImage(url: item.resolvedImageURL, height: 150, width: width)
                }
                .buttonStyle(.plain)

                Button {
                    toggleFavorite(item)
                } label: {
                    Image(systemName: isFavorited(item) ? "bookmark.fill" : "bookmark")
                        .font(.caption)
                        .foregroundStyle(Theme.ink)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.brand)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("$\(Int(item.price))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(width: width)
        .labSurface(padded: false, bordered: true)
    }

    // MARK: - Section C: Evolution

    private func evolutionSection(_ saved: SavedProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EVOLUTION")
                .sectionLabel()

            HStack(spacing: 10) {
                Text("STABILITY")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.0)
                Text(stability)
                    .font(.caption2)
                    .foregroundStyle(Theme.ink)
            }

            Button {
                Haptics.tap()
                path.append(Route.calibration(saved.tasteProfile, saved.recommendations))
            } label: {
                Text(refineCTALabel)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.ink)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            }
            .buttonStyle(.plain)

            if stability == "Stable" {
                Button {
                    Haptics.tap()
                    path.append(Route.board(saved.recommendations))
                } label: {
                    Text("Generate a board")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                                .stroke(Theme.hairline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            let savedCount = FavoritesStore.loadAll().count
            if savedCount < 3 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nothing saved yet")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.muted)
                    Text("Save 3 pieces to unlock your board.")
                        .font(.caption2)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 4)
            }

            if !shiftDirections.isEmpty {
                Text("SHIFT DIRECTIONS")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.muted)
                    .tracking(1.0)
                    .padding(.top, 8)

                ForEach(shiftDirections) { direction in
                    shiftCard(direction)
                }
            }
        }
        .labSurface(padded: true, bordered: true)
    }

    private func shiftCard(_ direction: ShiftDirection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(direction.label.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.ink)
                .tracking(0.8)

            if !direction.products.isEmpty {
                HStack(spacing: 8) {
                    ForEach(direction.products) { item in
                        miniCommerceCard(item)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onLongPressGesture {
            applyShift(direction)
        }
    }

    // MARK: - Section D: Radar

    private func radarSection(_ saved: SavedProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("RADAR")
                    .sectionLabel()

                Text(DomainLayout.config(for: currentDomain).radarSubtitle)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
            }

            if topDiscovery.isEmpty {
                Text("No signals found.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .padding(.vertical, 16)
            } else {
                ForEach(topDiscovery) { item in
                    let related = discoveryRelated[item.id] ?? []

                    VStack(alignment: .leading, spacing: 10) {
                        radarCard(item, related: related)

                        if !related.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(related) { relItem in
                                        miniCommerceCard(relItem)
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }

                        Button {
                            Haptics.tap()
                            signalShopItem = item
                        } label: {
                            Text("Shop this signal")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                                        .stroke(Theme.hairline, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .stroke(Theme.accent.opacity(pulseRadar ? 1 : 0), lineWidth: 2)
                    )
                    .animation(.easeInOut(duration: 0.8).repeatCount(3, autoreverses: true), value: pulseRadar)
                }
            }

            Button {
                Haptics.tap()
                path.append(Route.result(saved.tasteProfile, saved.recommendations))
            } label: {
                Text("See more")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func radarCard(_ item: DiscoveryItem, related: [RecommendationItem]) -> some View {
        let heroImage = item.imageURL ?? related.first?.resolvedImageURL

        return Button {
            path.append(Route.discoveryDetail(item))
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let url = heroImage {
                    CachedImage(url: url, height: 260)
                } else {
                    Rectangle()
                        .fill(Theme.surface)
                        .frame(height: 260)
                }

                LinearGradient(
                    colors: [.black.opacity(0.6), .clear],
                    startPoint: .bottom,
                    endPoint: .center
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.type.rawValue.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1.0)

                    Text(item.title)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(.white)

                    if !item.primaryRegion.isEmpty {
                        Text(item.primaryRegion)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func miniCommerceCard(_ item: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Button {
                    path.append(Route.recommendationDetail(item, tasteProfileId: profileId))
                } label: {
                    CachedImage(url: item.resolvedImageURL, height: 110, width: 110)
                }
                .buttonStyle(.plain)

                Button {
                    toggleFavorite(item)
                } label: {
                    Image(systemName: isFavorited(item) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.ink)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.brand)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("$\(Int(item.price))")
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
        }
        .frame(width: 110)
        .labSurface(padded: false, bordered: true)
    }

    // MARK: - Section E: Materials

    @ViewBuilder
    private var materialsSection: some View {
        if DomainLayout.config(for: currentDomain).showMaterials && !materialSections.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                Text("MATERIALS")
                    .sectionLabel()

                ForEach(materialSections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.name)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                            .tracking(1.0)

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 10) {
                                ForEach(section.items) { item in
                                    commerceCard(item, width: 140)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }
            }
        }
    }
}
