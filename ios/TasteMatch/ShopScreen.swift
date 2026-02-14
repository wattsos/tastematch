import SwiftUI

struct ShopScreen: View {
    @Binding var path: NavigationPath
    let profile: TasteProfile
    @Environment(\.openURL) private var openURL

    @State private var searchText = ""
    @State private var selectedCategory: ItemCategory? = nil
    @State private var selectedMaterial: String? = nil
    @State private var allRanked: [RecommendationItem] = []
    @State private var displayedItems: [RecommendationItem] = []
    @State private var favoritedIds: Set<String> = []
    @State private var hasMore = true

    private let pageSize = 20

    // MARK: - Computed

    private var filteredItems: [RecommendationItem] {
        var items = allRanked
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            items = items.filter {
                $0.title.lowercased().contains(query)
                || $0.brand.lowercased().contains(query)
            }
        }
        return items
    }

    private var materialChips: [String] {
        let catalog = MockCatalog.items
        let topSkus = Set(allRanked.prefix(60).map(\.skuId))
        var freq: [String: Int] = [:]
        for item in catalog where topSkus.contains(item.skuId) {
            for mat in item.materialTags {
                let key = mat.lowercased()
                freq[key, default: 0] += 1
            }
        }
        return freq.sorted { $0.value > $1.value }
            .prefix(8)
            .map(\.key)
            .sorted()
    }

    private var categoryChips: [ItemCategory] {
        [.lighting, .textile]
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                searchBar
                filterChips

                if displayedItems.isEmpty {
                    emptyState
                } else {
                    gridSection
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCatalog()
            refreshFavorites()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SHOP")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(1.2)

            Text("Inventory ranked to your profile.")
                .font(.system(.subheadline, design: .serif, weight: .medium))
                .foregroundStyle(Theme.ink)
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(Theme.muted)

            TextField("Search by name or brand", text: $searchText)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: searchText) { _, _ in
                    resetPagination()
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categoryChips, id: \.self) { cat in
                    chipButton(
                        label: cat.rawValue.capitalized,
                        isSelected: selectedCategory == cat
                    ) {
                        if selectedCategory == cat {
                            selectedCategory = nil
                        } else {
                            selectedCategory = cat
                        }
                        EventLogger.shared.logEvent(
                            "shop_filtered",
                            tasteProfileId: profile.id,
                            metadata: ["filter": "category", "value": cat.rawValue]
                        )
                        reloadRanked()
                    }
                }

                if !materialChips.isEmpty {
                    chipDivider
                }

                ForEach(materialChips, id: \.self) { mat in
                    chipButton(
                        label: mat.capitalized,
                        isSelected: selectedMaterial == mat
                    ) {
                        if selectedMaterial == mat {
                            selectedMaterial = nil
                        } else {
                            selectedMaterial = mat
                        }
                        EventLogger.shared.logEvent(
                            "shop_filtered",
                            tasteProfileId: profile.id,
                            metadata: ["filter": "material", "value": mat]
                        )
                        reloadRanked()
                    }
                }
            }
        }
    }

    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isSelected ? .white : Theme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.ink : Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(isSelected ? .clear : Theme.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var chipDivider: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(width: 1, height: 20)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No items found.")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Grid

    private var gridSection: some View {
        VStack(spacing: 16) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(displayedItems) { item in
                    Button {
                        EventLogger.shared.logEvent(
                            "shop_item_opened",
                            tasteProfileId: profile.id,
                            metadata: ["skuId": item.skuId, "title": item.title]
                        )
                        path.append(Route.recommendationDetail(item, tasteProfileId: profile.id))
                    } label: {
                        shopCard(item)
                    }
                    .buttonStyle(.plain)
                }
            }

            if hasMore {
                Color.clear
                    .frame(height: 1)
                    .onAppear { loadNextPage() }
            }
        }
    }

    // MARK: - Shop Card

    private func shopCard(_ item: RecommendationItem) -> some View {
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

            VStack(alignment: .leading, spacing: 4) {
                Text(item.brand)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)

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

            Button {
                EventLogger.shared.logEvent(
                    "shop_cta_clicked",
                    tasteProfileId: profile.id,
                    metadata: ["skuId": item.skuId]
                )
                let urlString = item.affiliateURL ?? item.productURL
                if let url = URL(string: urlString) {
                    openURL(url)
                }
            } label: {
                Text("View")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .overlay(alignment: .top) { HairlineDivider() }
            }
            .buttonStyle(.plain)
        }
        .labSurface(padded: false, bordered: true)
    }

    // MARK: - Data

    private func loadCatalog() {
        reloadRanked()
    }

    private func reloadRanked() {
        let vector = resolveVector()
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        allRanked = RecommendationEngine.rankCommerceItems(
            vector: vector,
            axisScores: axisScores,
            items: MockCatalog.items,
            materialFilter: selectedMaterial,
            categoryFilter: selectedCategory
        )
        resetPagination()
    }

    private func resetPagination() {
        let source = filteredItems
        displayedItems = Array(source.prefix(pageSize))
        hasMore = source.count > pageSize
    }

    private func loadNextPage() {
        let source = filteredItems
        let currentCount = displayedItems.count
        guard currentCount < source.count else {
            hasMore = false
            return
        }
        let nextBatch = Array(source[currentCount..<min(currentCount + pageSize, source.count)])
        displayedItems.append(contentsOf: nextBatch)
        hasMore = displayedItems.count < source.count
    }

    private func resolveVector() -> TasteVector {
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

    // MARK: - Favorites

    private func isFavorited(_ item: RecommendationItem) -> Bool {
        favoritedIds.contains(favoriteKey(item))
    }

    private func toggleFavorite(_ item: RecommendationItem) {
        Haptics.tap()
        let key = favoriteKey(item)
        if favoritedIds.contains(key) {
            favoritedIds.remove(key)
            let stored = FavoritesStore.loadAll()
            if let match = stored.first(where: { $0.title == item.title && $0.subtitle == item.subtitle }) {
                FavoritesStore.remove(id: match.id)
            }
        } else {
            favoritedIds.insert(key)
            FavoritesStore.add(item)
        }
    }

    private func refreshFavorites() {
        let stored = FavoritesStore.loadAll()
        favoritedIds = Set(stored.map { "\($0.title)|\($0.subtitle)" })
    }

    private func favoriteKey(_ item: RecommendationItem) -> String {
        "\(item.title)|\(item.subtitle)"
    }
}
