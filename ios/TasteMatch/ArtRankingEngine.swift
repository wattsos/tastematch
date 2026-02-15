import Foundation

// MARK: - Art Ranking Engine

enum ArtRankingEngine {

    // MARK: - Stability Mode

    enum StabilityMode {
        case stable, neutral, volatile
    }

    static func detectStability(vector: TasteVector, swipeCount: Int) -> StabilityMode {
        let norm = vector.normalized()
        let sorted = norm.weights.values.sorted(by: >)
        let top1 = sorted.first ?? 0
        let top2 = sorted.dropFirst().first ?? 0
        let separation = top1 - top2

        if swipeCount >= 14 && separation >= 0.15 {
            return .stable
        } else if separation < 0.10 || swipeCount < 7 {
            return .volatile
        } else {
            return .neutral
        }
    }

    // MARK: - Rarity Boost

    static func rarityBoost(tier: ArtRarityTier, mode: StabilityMode) -> Double {
        switch (tier, mode) {
        case (.archive, .stable):       return 1.0
        case (.archive, .neutral):      return 0.7
        case (.archive, .volatile):     return 0.3
        case (.contemporary, .stable):  return 0.6
        case (.contemporary, .neutral): return 1.0
        case (.contemporary, .volatile):return 0.6
        case (.emergent, .stable):      return 0.3
        case (.emergent, .neutral):     return 0.7
        case (.emergent, .volatile):    return 1.0
        }
    }

    // MARK: - Art Freshness

    static func artFreshness(yearRange: String?) -> Double {
        guard let range = yearRange else { return 0.5 }
        // Extract the latest year from the range string (e.g. "2020-2024" → 2024)
        let numbers = range.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
            .filter { $0 >= 1900 && $0 <= 2100 }
        guard let latestYear = numbers.max() else { return 0.5 }

        if latestYear >= 2020 { return 1.0 }
        if latestYear >= 2000 { return 0.7 }
        if latestYear >= 1980 { return 0.5 }
        return 0.3
    }

    // MARK: - Rank Art Items

    /// Score = 0.60 × alignment + 0.15 × rarityScore + 0.15 × clusterBoost + 0.10 × freshness
    static func rankArtItems(
        vector: TasteVector,
        axisScores: AxisScores,
        items: [CatalogItem],
        swipeCount: Int
    ) -> [RecommendationItem] {
        let mode = detectStability(vector: vector, swipeCount: swipeCount)
        let dominantCluster = DomainDiscovery.identifyCluster(axisScores, domain: .art)
        let normalized = vector.normalized()

        let scored: [(item: CatalogItem, score: Double)] = items.map { item in
            // 0.60 — alignment
            let alignment: Double
            if !item.commerceAxisWeights.isEmpty {
                alignment = DiscoveryEngine.vectorAlignment(
                    axisScores: axisScores,
                    itemWeights: item.commerceAxisWeights
                )
            } else {
                var tagScore = 0.0
                for tag in item.tags {
                    let key = String(describing: tag)
                    tagScore += normalized.weights[key, default: 0.0]
                }
                alignment = max(0, min(1, (tagScore + 1) / 2))
            }

            // 0.15 — rarity score
            let rarityScore: Double
            if let tier = item.rarityTier {
                rarityScore = rarityBoost(tier: tier, mode: mode)
            } else {
                rarityScore = 0.5
            }

            // 0.15 — cluster boost
            let clusterBoost: Double = item.discoveryClusters.contains(dominantCluster) ? 1.0 : 0.0

            // 0.10 — freshness from yearRange
            let freshness = artFreshness(yearRange: item.yearRange)

            let score = 0.60 * alignment
                + 0.15 * rarityScore
                + 0.15 * clusterBoost
                + 0.10 * freshness

            return (item, score)
        }

        let sorted = scored.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            return $0.item.skuId < $1.item.skuId
        }

        return sorted.map { entry in
            let subtitle = "\(entry.item.brand) — $\(Int(entry.item.price))"
            return RecommendationItem(
                skuId: entry.item.skuId,
                title: entry.item.title,
                subtitle: subtitle,
                reason: "",
                attributionConfidence: min(1, max(0, entry.score)),
                price: entry.item.price,
                imageURL: entry.item.imageURL,
                merchant: entry.item.merchant,
                productURL: entry.item.productURL,
                brand: entry.item.brand,
                affiliateURL: entry.item.affiliateURL
            )
        }
    }

}
