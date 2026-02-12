import SwiftUI

struct ResultScreen: View {
    @Binding var path: NavigationPath
    let profile: TasteProfile
    let recommendations: [RecommendationItem]
    @State private var showShareSheet = false
    @State private var showCardShareSheet = false
    @State private var cardImage: UIImage?
    @State private var favoritedIds: Set<String> = []
    @State private var maxBudget: Double = 0
    @State private var sortMode: SortMode = .match
    @State private var revealBadge = false
    @State private var revealTags = false
    @State private var revealStory = false
    @State private var revealPicks = false
    @State private var isGridMode = false

    private enum SortMode: String, CaseIterable {
        case match = "Best Match"
        case priceLow = "Price ↑"
        case priceHigh = "Price ↓"
    }

    private var priceRange: ClosedRange<Double> {
        let prices = recommendations.map(\.price)
        let lo = prices.min() ?? 0
        let hi = prices.max() ?? 1
        return lo == hi ? lo...(hi + 1) : lo...hi
    }

    private var filteredRecommendations: [RecommendationItem] {
        var items = maxBudget > 0 ? recommendations.filter { $0.price <= maxBudget } : recommendations
        switch sortMode {
        case .match:
            break // Already sorted by match from engine
        case .priceLow:
            items.sort { $0.price < $1.price }
        case .priceHigh:
            items.sort { $0.price > $1.price }
        }
        return items
    }

    var body: some View {
        List {
            // Featured badge for primary style
            if let primaryTag = profile.tags.first {
                Section {
                    VStack(spacing: 12) {
                        TasteBadge(tagKey: primaryTag.key, size: .featured)
                        if let secondary = profile.tags.dropFirst().first {
                            TasteBadge(tagKey: secondary.key, size: .compact)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                    .opacity(revealBadge ? 1 : 0)
                    .offset(y: revealBadge ? 0 : 20)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Taste")
                        .font(Theme.headlineFont)
                        .foregroundStyle(Theme.espresso)
                    ForEach(profile.tags) { tag in
                        HStack(spacing: 12) {
                            Text(tag.label)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Theme.espresso)
                            Spacer()
                            ProgressView(value: tag.confidence)
                                .tint(Theme.accent)
                                .frame(width: 80)
                            Text("\(Int(tag.confidence * 100))%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Theme.clay)
                                .frame(width: 36, alignment: .trailing)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(tag.label), \(Int(tag.confidence * 100)) percent confidence")
                    }
                }
                .opacity(revealTags ? 1 : 0)
                .offset(y: revealTags ? 0 : 16)
            }

            Section {
                Text(profile.story)
                    .font(.body)
                    .foregroundStyle(Theme.espresso)
                    .lineSpacing(4)
                    .italic()
                    .opacity(revealStory ? 1 : 0)
                    .offset(y: revealStory ? 0 : 12)
            } header: {
                Text("Your Story")
            }

            Section("Signals") {
                ForEach(profile.signals) { signal in
                    HStack {
                        Text(signal.key.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundStyle(Theme.clay)
                            .frame(width: 120, alignment: .leading)
                        Spacer()
                        Text(signal.value.capitalized)
                            .font(.body)
                            .foregroundStyle(Theme.espresso)
                    }
                }
            }

            if recommendations.count > 1 {
                Section("Budget") {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Max price")
                                .font(.subheadline)
                                .foregroundStyle(Theme.clay)
                            Spacer()
                            Text(maxBudget >= priceRange.upperBound ? "Any" : "$\(Int(maxBudget))")
                                .font(.subheadline.monospacedDigit().weight(.medium))
                                .foregroundStyle(Theme.espresso)
                        }
                        Slider(value: $maxBudget, in: priceRange, step: 25)
                            .tint(Theme.accent)
                        HStack {
                            Text("$\(Int(priceRange.lowerBound))")
                                .font(.caption2)
                                .foregroundStyle(Theme.clay)
                            Spacer()
                            Text("$\(Int(priceRange.upperBound))")
                                .font(.caption2)
                                .foregroundStyle(Theme.clay)
                        }
                    }
                }
            }

            Section {
                if filteredRecommendations.isEmpty {
                    Text(recommendations.isEmpty
                        ? "No picks matched your profile. Try a different room or goal."
                        : "No picks within this budget. Try raising your max price.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.clay)
                }

                if isGridMode {
                    // Moodboard grid
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(filteredRecommendations) { item in
                            Button {
                                path.append(Route.recommendationDetail(item))
                            } label: {
                                moodboardCard(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    .opacity(revealPicks ? 1 : 0)
                    .offset(y: revealPicks ? 0 : 10)
                } else {
                    // List view
                    ForEach(filteredRecommendations) { item in
                        Button {
                            path.append(Route.recommendationDetail(item))
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundStyle(Theme.espresso)
                                    Spacer()
                                    Text(confidenceLabel(item.attributionConfidence))
                                        .font(.caption2.weight(.medium))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(confidenceColor(item.attributionConfidence).opacity(0.15))
                                        .foregroundStyle(confidenceColor(item.attributionConfidence))
                                        .clipShape(Capsule())
                                }
                                Text(item.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.clay)
                                HStack {
                                    Text(item.reason)
                                        .font(.callout)
                                        .italic()
                                        .foregroundStyle(Theme.clay)
                                    Spacer()
                                    Button {
                                        toggleFavorite(item)
                                    } label: {
                                        Image(systemName: isFavorited(item) ? "heart.fill" : "heart")
                                            .foregroundStyle(isFavorited(item) ? Theme.favorite : Theme.clay)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(isFavorited(item) ? "Remove from favorites" : "Add to favorites")
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .foregroundStyle(.primary)
                    }
                    .opacity(revealPicks ? 1 : 0)
                    .offset(y: revealPicks ? 0 : 10)
                }
            } header: {
                HStack {
                    Text("Picks for You")
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { isGridMode.toggle() }
                    } label: {
                        Image(systemName: isGridMode ? "list.bullet" : "square.grid.2x2")
                            .font(.subheadline)
                            .foregroundStyle(Theme.accent)
                    }
                    .textCase(nil)
                    .accessibilityLabel(isGridMode ? "Switch to list" : "Switch to grid")
                    Picker("Sort", selection: $sortMode) {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .textCase(nil)
                }
            }
        }
        .navigationTitle("Results")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share as Text", systemImage: "doc.plaintext")
                    }
                    Button {
                        cardImage = TasteCardView(profile: profile).renderImage()
                        if cardImage != nil {
                            showCardShareSheet = true
                        }
                    } label: {
                        Label("Share Taste Card", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .tint(Theme.accent)
                .accessibilityLabel("Share results")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Start Over") {
                    Haptics.warning()
                    ProfileStore.clear()
                    path = NavigationPath()
                }
                .font(.subheadline)
                .tint(Theme.accent)
            }
        }
        .tint(Theme.accent)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: shareSummary)
        }
        .sheet(isPresented: $showCardShareSheet) {
            if let image = cardImage {
                ImageShareSheet(image: image)
            }
        }
        .onAppear {
            EventLogger.shared.logEvent("results_viewed", tasteProfileId: profile.id)
            refreshFavorites()
            if maxBudget == 0 {
                maxBudget = priceRange.upperBound
            }
            // Staggered reveal
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { revealBadge = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) { revealTags = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) { revealStory = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.85)) { revealPicks = true }
        }
    }

    // MARK: - Moodboard Card

    private func moodboardCard(_ item: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Color swatch placeholder based on match strength
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [confidenceColor(item.attributionConfidence).opacity(0.25), Theme.blush.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 80)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(confidenceColor(item.attributionConfidence).opacity(0.5))
                )

            Text(item.title)
                .font(.system(.caption, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.espresso)
                .lineLimit(2)

            HStack {
                Text("$\(Int(item.price))")
                    .font(.caption2.monospacedDigit().weight(.medium))
                    .foregroundStyle(Theme.accent)
                Spacer()
                Text(confidenceLabel(item.attributionConfidence))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(confidenceColor(item.attributionConfidence))
            }

            HStack(spacing: 4) {
                Button {
                    toggleFavorite(item)
                } label: {
                    Image(systemName: isFavorited(item) ? "heart.fill" : "heart")
                        .font(.caption2)
                        .foregroundStyle(isFavorited(item) ? Theme.favorite : Theme.clay)
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
        .padding(10)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.blush.opacity(0.4), lineWidth: 1)
        )
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

    // MARK: - Attribution Helpers

    private func confidenceLabel(_ value: Double) -> String {
        switch value {
        case 0.8...: return "Strong match"
        case 0.5...: return "Good match"
        default:     return "Partial match"
        }
    }

    private func confidenceColor(_ value: Double) -> Color {
        switch value {
        case 0.8...: return Theme.strongMatch
        case 0.5...: return Theme.goodMatch
        default:     return Theme.partialMatch
        }
    }

    // MARK: - Share Summary

    private var shareSummary: String {
        var lines: [String] = []

        lines.append("My ItMe Results")
        lines.append("")

        let tagLine = profile.tags.map { "\($0.label) (\(Int($0.confidence * 100))%)" }.joined(separator: ", ")
        lines.append("Style: \(tagLine)")
        lines.append("")

        lines.append(profile.story)
        lines.append("")

        lines.append("Top Picks:")
        for item in filteredRecommendations {
            lines.append("- \(item.title) — \(item.subtitle)")
        }

        lines.append("")
        lines.append("Discovered on ItMe — itme2.com")

        return lines.joined(separator: "\n")
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
