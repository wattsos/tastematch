import Foundation

struct RecommendationEngine {

    static func recommend(
        profile: TasteProfile,
        catalog: [CatalogItem],
        context: RoomContext,
        goal: DesignGoal,
        limit: Int
    ) -> [RecommendationItem] {
        let primaryTag = profile.tags.first.flatMap { tagByKey[$0.key] }
        let secondaryTag = profile.tags.dropFirst().first.flatMap { tagByKey[$0.key] }

        let vector = TasteEngine.vectorFromProfile(profile)
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        let goalMult = goalMultiplier(for: goal)
        let roomTags = roomFavoredTags[context] ?? []

        let scored: [(item: CatalogItem, score: Double)] = catalog.map { item in
            var score = 0.0

            // Primary tag match
            if let primary = primaryTag, item.tags.contains(primary) {
                score += 1.0
            }

            // Secondary tag match
            if let secondary = secondaryTag, item.tags.contains(secondary) {
                score += 0.6
            }

            // Context boost: small bump if item tag aligns with room-favored tags
            for tag in item.tags {
                if roomTags.contains(tag) {
                    score += 0.1
                    break
                }
            }

            // Goal multiplier
            score *= goalMult

            return (item, score)
        }

        let sorted = scored.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            return $0.item.skuId < $1.item.skuId
        }
        let top = sorted.prefix(limit)

        return top.enumerated().map { index, entry in
            let whyThisFits = buildWhyThisFits(
                axisScores: axisScores,
                profile: profile,
                itemTitle: entry.item.title,
                merchant: entry.item.merchant,
                index: index
            )

            let subtitle = "\(entry.item.merchant) — $\(Int(entry.item.price))"
            let attribution = min(1, max(0, entry.score))

            return RecommendationItem(
                skuId: entry.item.skuId,
                title: entry.item.title,
                subtitle: subtitle,
                reason: whyThisFits,
                attributionConfidence: attribution,
                price: entry.item.price,
                imageURL: entry.item.imageURL,
                merchant: entry.item.merchant,
                productURL: entry.item.productURL,
                brand: entry.item.brand,
                affiliateURL: entry.item.affiliateURL
            )
        }
    }

    /// Re-rank existing recommendations using a blended TasteVector.
    static func rankWithVector(
        _ items: [RecommendationItem],
        vector: TasteVector,
        catalog: [CatalogItem],
        context: RoomContext?,
        goal: DesignGoal?
    ) -> [RecommendationItem] {
        let catalogMap = Dictionary(uniqueKeysWithValues: catalog.map { ($0.skuId, $0) })
        let goalMult = goal.map { goalMultiplier(for: $0) } ?? 1.0
        let roomTags: Set<TasteEngine.CanonicalTag> = context.flatMap { roomFavoredTags[$0] } ?? []
        let normalized = vector.normalized()
        let avoided = Set(normalized.avoids)

        let scored: [(item: RecommendationItem, score: Double)] = items.map { item in
            guard let catalogItem = catalogMap[item.skuId] else {
                return (item, 0.0)
            }

            var score = 0.0
            for (i, tag) in catalogItem.tags.enumerated() {
                let key = String(describing: tag)
                let weight = normalized.weights[key, default: 0.0]
                let matchWeight = i == 0 ? 1.0 : 0.6
                score += matchWeight * weight
            }

            // Avoid penalty
            for tag in catalogItem.tags {
                let key = String(describing: tag)
                if avoided.contains(key) {
                    score -= 0.4
                }
            }

            // Context bonus
            for tag in catalogItem.tags {
                if roomTags.contains(tag) {
                    score += 0.1
                    break
                }
            }

            score *= goalMult
            return (item, score)
        }

        let sorted = scored.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            return $0.item.skuId < $1.item.skuId
        }

        return sorted.map(\.item)
    }
    // MARK: - Commerce Ranking

    /// Rank catalog items using axis-based scoring. Single entry point for commerce inventory.
    /// Score = 0.6 × vector alignment + 0.2 × material boost + 0.1 × cluster boost + 0.1 × category priority.
    static func rankCommerceItems(
        vector: TasteVector,
        axisScores: AxisScores,
        items: [CatalogItem],
        materialFilter: String? = nil,
        categoryFilter: ItemCategory? = nil,
        domain: TasteDomain = .space,
        swipeCount: Int = 0
    ) -> [RecommendationItem] {
        // Art domain uses dedicated ranking engine
        if domain == .art {
            var filtered = items
            if let mat = materialFilter {
                let lower = mat.lowercased()
                filtered = filtered.filter { item in
                    item.materialTags.contains { $0.lowercased().contains(lower) }
                }
            }
            if let cat = categoryFilter {
                filtered = filtered.filter { $0.category == cat }
            }
            return ArtRankingEngine.rankArtItems(
                vector: vector, axisScores: axisScores,
                items: filtered, swipeCount: swipeCount
            )
        }

        // Objects domain uses dedicated ranking engine when objectAxisWeights are available
        if domain == .objects {
            var filtered = items
            if let mat = materialFilter {
                let lower = mat.lowercased()
                filtered = filtered.filter { item in
                    item.materialTags.contains { $0.lowercased().contains(lower) }
                }
            }
            if let cat = categoryFilter {
                filtered = filtered.filter { $0.category == cat }
            }
            // Approximate ObjectAxisScores from Space AxisScores for fallback
            let objectScores = ObjectAxisScores(
                precision: axisScores.softStructured,
                patina: axisScores.warmCool,
                utility: -axisScores.minimalOrnate,
                formality: axisScores.minimalOrnate,
                subculture: -axisScores.neutralSaturated,
                ornament: axisScores.minimalOrnate,
                heritage: axisScores.warmCool,
                technicality: axisScores.organicIndustrial,
                minimalism: -axisScores.sparseLayered
            )
            let objectVector = ObjectVector(weights: Dictionary(
                uniqueKeysWithValues: ObjectAxis.allCases.map { ($0.rawValue, objectScores.value(for: $0)) }
            ))
            return ObjectsRankingEngine.rankObjectItems(
                vector: objectVector, axisScores: objectScores,
                items: filtered, swipeCount: swipeCount
            )
        }

        let dominantCluster = DomainDiscovery.identifyCluster(axisScores, domain: domain)
        let normalized = vector.normalized()

        var filtered = items
        if let mat = materialFilter {
            let lower = mat.lowercased()
            filtered = filtered.filter { item in
                item.materialTags.contains { $0.lowercased().contains(lower) }
            }
        }
        if let cat = categoryFilter {
            filtered = filtered.filter { $0.category == cat }
        }

        let scored: [(item: CatalogItem, score: Double)] = filtered.map { item in
            // 0.6 — vector alignment via item's commerce axis weights
            let alignment: Double
            if !item.commerceAxisWeights.isEmpty {
                alignment = DiscoveryEngine.vectorAlignment(
                    axisScores: axisScores,
                    itemWeights: item.commerceAxisWeights
                )
            } else {
                // Fallback: use tag-based alignment
                var tagScore = 0.0
                for tag in item.tags {
                    let key = String(describing: tag)
                    tagScore += normalized.weights[key, default: 0.0]
                }
                alignment = max(0, min(1, (tagScore + 1) / 2))
            }

            // 0.2 — material boost (any materialTag overlap with vector influences)
            let materialBoost: Double = {
                guard !item.materialTags.isEmpty else { return 0.5 }
                let influences = Set(normalized.influences)
                let overlap = item.materialTags.filter { influences.contains($0) }.count
                return overlap > 0 ? 1.0 : 0.3
            }()

            // 0.1 — cluster boost
            let clusterBoost: Double = item.discoveryClusters.contains(dominantCluster) ? 1.0 : 0.0

            // 0.1 — category priority (lighting > textile > other)
            let categoryPriority: Double = {
                switch item.category {
                case .lighting: return 1.0
                case .textile:  return 0.8
                default:        return 0.5
                }
            }()

            let score = 0.6 * alignment
                + 0.2 * materialBoost
                + 0.1 * clusterBoost
                + 0.1 * categoryPriority

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

// MARK: - Private Helpers

private extension RecommendationEngine {

    struct AxisReasonKey: Hashable {
        let axis: Axis
        let positive: Bool
    }

    private static func buildWhyThisFits(
        axisScores: AxisScores,
        profile: TasteProfile,
        itemTitle: String,
        merchant: String,
        index: Int
    ) -> String {
        let signal = profile.signals.first
        let signalPhrase = signal.map { "\($0.key): \($0.value)" } ?? "your selections"

        let dominant = axisScores.dominantAxis
        let dominantPositive = axisScores.value(for: dominant) >= 0
        let key = AxisReasonKey(axis: dominant, positive: dominantPositive)

        guard let templates = axisReasonTemplates[key] else {
            return "Fits your personal style — based on \(signalPhrase)."
        }

        let template = templates[index % templates.count]
        return template
            .replacingOccurrences(of: "{signal}", with: signalPhrase)
            .replacingOccurrences(of: "{item}", with: itemTitle)
            .replacingOccurrences(of: "{merchant}", with: merchant)
    }

    static let axisReasonTemplates: [AxisReasonKey: [String]] = [
        AxisReasonKey(axis: .minimalOrnate, positive: false): [
            "{item} keeps things intentional — aligned with your {signal}.",
            "A piece like {item} supports the pared-back direction your profile reads.",
            "{item} from {merchant} lets negative space do the work here.",
        ],
        AxisReasonKey(axis: .minimalOrnate, positive: true): [
            "{item} adds decorative weight that matches your ornate instinct.",
            "The layered detail in {item} echoes what your profile gravitates toward.",
            "{item} from {merchant} pairs rich texture with the density your taste reveals.",
        ],
        AxisReasonKey(axis: .warmCool, positive: true): [
            "{item} grounds the room with warmth — tied to your {signal}.",
            "A piece like {item} brings the earthen texture your taste highlights.",
            "{item} from {merchant} carries honest materiality that echoes your warm register.",
        ],
        AxisReasonKey(axis: .warmCool, positive: false): [
            "{item} channels cool clarity — rooted in your {signal}.",
            "The restrained tone of {item} lightens the room the way your profile suggests.",
            "{item} from {merchant} complements the crisp, airy quality in your palette.",
        ],
        AxisReasonKey(axis: .softStructured, positive: true): [
            "{item} echoes the structured lines your space calls for — driven by {signal}.",
            "The defined edges of {item} match your taste for precision.",
            "{item} from {merchant} reinforces the deliberate geometry your profile reveals.",
        ],
        AxisReasonKey(axis: .softStructured, positive: false): [
            "{item} softens the room with the ease your profile favors — grounded in {signal}.",
            "The gentle contours of {item} complement your yielding instinct.",
            "{item} from {merchant} brings the fluid comfort your taste calls for.",
        ],
        AxisReasonKey(axis: .organicIndustrial, positive: true): [
            "{item} brings raw character that fits your {signal}.",
            "The exposed-material edge of {item} pairs with your taste for the unfinished.",
            "{item} from {merchant} anchors the forged texture running through your space.",
        ],
        AxisReasonKey(axis: .organicIndustrial, positive: false): [
            "{item} layers in organic richness — connects to your {signal}.",
            "The handcrafted feel of {item} deepens what your profile suggests.",
            "{item} from {merchant} adds the rooted, botanical quality your taste calls for.",
        ],
        AxisReasonKey(axis: .lightDark, positive: false): [
            "{item} opens the room with airy brightness — based on your {signal}.",
            "The luminous quality of {item} reinforces the light composition your taste reflects.",
            "{item} from {merchant} adds the translucent clarity your profile favors.",
        ],
        AxisReasonKey(axis: .lightDark, positive: true): [
            "{item} brings moody depth that resonates with your {signal}.",
            "The shadow-rich presence of {item} matches your taste for the nocturnal.",
            "{item} from {merchant} reinforces the dark, intimate register of your profile.",
        ],
        AxisReasonKey(axis: .neutralSaturated, positive: false): [
            "{item} keeps the palette tonal and restrained — aligned with your {signal}.",
            "The undyed quality of {item} supports the desaturated register your profile favors.",
            "{item} from {merchant} lets form lead over color, matching your neutral instinct.",
        ],
        AxisReasonKey(axis: .neutralSaturated, positive: true): [
            "{item} delivers chromatic energy that matches your {signal}.",
            "The saturated presence of {item} speaks to your vivid instinct.",
            "{item} from {merchant} pairs bold hue with the expressive palette your profile reveals.",
        ],
        AxisReasonKey(axis: .sparseLayered, positive: false): [
            "{item} keeps things spare and open — connected to your {signal}.",
            "The edited quality of {item} reinforces the restraint your taste reflects.",
            "{item} from {merchant} lets negative space define the room here.",
        ],
        AxisReasonKey(axis: .sparseLayered, positive: true): [
            "{item} adds layered density — driven by your {signal}.",
            "The accumulated texture of {item} matches what your taste gravitates toward.",
            "{item} from {merchant} deepens the visual narrative through deliberate stacking.",
        ],
    ]

    static func goalMultiplier(for goal: DesignGoal) -> Double {
        switch goal {
        case .overhaul:  return 1.1
        case .refresh:   return 1.0
        case .organize:  return 0.95
        case .accent:    return 0.9
        }
    }

    static let tagByKey: [String: TasteEngine.CanonicalTag] = Dictionary(
        uniqueKeysWithValues: TasteEngine.CanonicalTag.allCases.map { (String(describing: $0), $0) }
    )

    static let roomFavoredTags: [RoomContext: Set<TasteEngine.CanonicalTag>] = [
        .livingRoom: [.midCenturyModern, .bohemian, .scandinavian],
        .bedroom:    [.scandinavian, .japandi, .minimalist],
        .kitchen:    [.industrial, .rustic, .scandinavian],
        .office:     [.minimalist, .industrial, .midCenturyModern],
        .bathroom:   [.minimalist, .coastal, .japandi],
        .outdoor:    [.coastal, .rustic, .bohemian],
    ]
}
