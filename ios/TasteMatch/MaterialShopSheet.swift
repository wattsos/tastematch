import SwiftUI

struct MaterialShopSheet: View {
    let material: DiscoveryItem
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    private var rankedItems: [RecommendationItem] {
        let syntheticVector = AxisMapping.syntheticVector(fromAxes: material.axisWeights)
        let axisScores = AxisMapping.computeAxisScores(from: syntheticVector)
        // Derive a material filter from the material title (first word, lowercased)
        let materialFilter = material.title.split(separator: " ").first.map(String.init)
        return Array(
            RecommendationEngine.rankCommerceItems(
                vector: syntheticVector,
                axisScores: axisScores,
                items: MockCatalog.items,
                materialFilter: materialFilter
            ).prefix(20)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("SELECTION")
                        .sectionLabel()
                        .padding(.top, 8)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(rankedItems) { item in
                            Button {
                                let urlString = item.affiliateURL ?? item.productURL
                                if let url = URL(string: urlString) {
                                    openURL(url)
                                }
                            } label: {
                                shopCard(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(material.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.ink)
                        .font(.callout.weight(.semibold))
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func shopCard(_ item: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedImage(url: item.imageURL, height: 150)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                Text(item.brand)
                    .font(.caption2)
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                Text("$\(Int(item.price))")
                    .font(.caption2.monospacedDigit().weight(.medium))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .labSurface(padded: false, bordered: true)
    }
}
