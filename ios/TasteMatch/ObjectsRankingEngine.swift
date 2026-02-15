import Foundation

// MARK: - Objects Ranking Engine

enum ObjectsRankingEngine {

    // MARK: - Stability Mode

    enum StabilityMode {
        case stable, neutral, volatile
    }

    static func detectStability(vector: ObjectVector, swipeCount: Int) -> StabilityMode {
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

    // MARK: - Vector Alignment (cosine similarity using ObjectAxisScores)

    static func vectorAlignment(objectScores: ObjectAxisScores, itemWeights: [String: Double]) -> Double {
        var dot = 0.0
        var magA = 0.0
        var magB = 0.0

        for axis in ObjectAxis.allCases {
            let a = objectScores.value(for: axis)
            let b = itemWeights[axis.rawValue, default: 0.0]
            dot += a * b
            magA += a * a
            magB += b * b
        }

        let denom = sqrt(magA) * sqrt(magB)
        guard denom > 0 else { return 0.5 }
        return (dot / denom + 1) / 2
    }

    // MARK: - Freshness

    static func freshness(yearRange: String?) -> Double {
        ArtRankingEngine.artFreshness(yearRange: yearRange)
    }

    // MARK: - Rank Object Items

    /// Score = 0.6 × vectorAlignment + 0.2 × rarityBoost + 0.1 × clusterBoost + 0.1 × freshness
    static func rankObjectItems(
        vector: ObjectVector,
        axisScores: ObjectAxisScores,
        items: [CatalogItem],
        swipeCount: Int
    ) -> [RecommendationItem] {
        let mode = detectStability(vector: vector, swipeCount: swipeCount)
        let dominantCluster = DomainDiscovery.identifyObjectsClusterV2(objectScores: axisScores)

        let scored: [(item: CatalogItem, score: Double)] = items.map { item in
            // 0.6 — alignment
            let alignment: Double
            if !item.objectAxisWeights.isEmpty {
                alignment = vectorAlignment(objectScores: axisScores, itemWeights: item.objectAxisWeights)
            } else if !item.commerceAxisWeights.isEmpty {
                // Fallback to Space axis weights with approximate mapping
                alignment = DiscoveryEngine.vectorAlignment(
                    axisScores: approximateSpaceScores(from: axisScores),
                    itemWeights: item.commerceAxisWeights
                )
            } else {
                alignment = 0.5
            }

            // 0.2 — rarity score
            let rarityScore: Double
            if let tier = item.rarityTier {
                rarityScore = rarityBoost(tier: tier, mode: mode)
            } else {
                rarityScore = 0.5
            }

            // 0.1 — cluster boost
            let clusterBoost: Double = item.discoveryClusters.contains(dominantCluster) ? 1.0 : 0.0

            // 0.1 — freshness
            let fresh = freshness(yearRange: item.yearRange)

            let score = 0.6 * alignment
                + 0.2 * rarityScore
                + 0.1 * clusterBoost
                + 0.1 * fresh

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

    // MARK: - Private

    /// Approximate AxisScores from ObjectAxisScores for fallback alignment.
    private static func approximateSpaceScores(from obj: ObjectAxisScores) -> AxisScores {
        AxisScores(
            minimalOrnate: obj.ornament,
            warmCool: obj.patina,
            softStructured: obj.precision,
            organicIndustrial: obj.technicality,
            lightDark: 0,
            neutralSaturated: -obj.minimalism,
            sparseLayered: -obj.minimalism
        )
    }
}
