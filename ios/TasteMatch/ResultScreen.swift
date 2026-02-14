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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroSection
                readingSection
                calibrationInfoSection
                selectionHeader
                selectionGrid
                detailsSection
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .onAppear {
            EventLogger.shared.logEvent("results_viewed", tasteProfileId: profile.id)
            refreshFavorites()
            calibrationRecord = CalibrationStore.load(for: profile.id)
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) { revealHero = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.45)) { revealStory = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.75)) { revealPicks = true }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROFILE 01")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(1.2)

            if let primary = profile.tags.first {
                Text(primary.label)
                    .font(.system(size: 48, weight: .semibold, design: .serif))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

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

            Text(profile.story)
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
            let normalized = record.vector.normalized()
            let level = record.vector.confidenceLevel(swipeCount: record.swipeCount)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("CALIBRATION")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.muted)
                        .tracking(1.2)
                    Spacer()
                    HStack(spacing: 12) {
                        Button {
                            Haptics.tap()
                            CalibrationStore.delete(for: profile.id)
                            calibrationRecord = nil
                        } label: {
                            Text("Reset")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Theme.muted)
                        }
                        Button {
                            Haptics.tap()
                            path.append(Route.calibration(profile, recommendations))
                        } label: {
                            Text("Refine")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }

                if !normalized.influences.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("INFLUENCES")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                            .tracking(1.0)

                        FlowLayout(spacing: 6) {
                            ForEach(normalized.influences, id: \.self) { tag in
                                Text(tagLabel(tag))
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

                if !normalized.avoids.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AVOIDS")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                            .tracking(1.0)

                        FlowLayout(spacing: 6) {
                            ForEach(normalized.avoids, id: \.self) { tag in
                                Text(tagLabel(tag))
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

    private func tagLabel(_ key: String) -> String {
        TasteEngine.CanonicalTag.allCases
            .first { String(describing: $0) == key }?
            .rawValue ?? key
    }

    // MARK: - Selection Header

    private var selectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("SELECTION")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.muted)
                .tracking(1.2)
            Spacer()
            Picker("Sort", selection: $sortMode) {
                ForEach(SortMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.muted)
        }
        .padding(.top, 8)
    }

    // MARK: - Selection Grid

    private var selectionGrid: some View {
        Group {
            if sortedRecommendations.isEmpty {
                Text("No picks matched your profile. Try a different room or goal.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ],
                    spacing: 14
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
        .opacity(revealPicks ? 1 : 0)
        .offset(y: revealPicks ? 0 : 12)
    }

    // MARK: - Pick Card

    private func pickCard(_ item: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: item.imageURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        Color(white: 0.94)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.title3)
                                    .foregroundStyle(Theme.muted.opacity(0.25))
                            )
                    }
                }
                .frame(height: 150)
                .clipped()

                Button {
                    toggleFavorite(item)
                } label: {
                    Image(systemName: isFavorited(item) ? "bookmark.fill" : "bookmark")
                        .font(.caption)
                        .foregroundStyle(isFavorited(item) ? Theme.accent : Theme.ink.opacity(0.55))
                        .padding(6)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
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
