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
                primaryTag: primaryTag,
                profile: profile,
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
                productURL: entry.item.productURL
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
}

// MARK: - Private Helpers

private extension RecommendationEngine {

    static func buildWhyThisFits(
        primaryTag: TasteEngine.CanonicalTag?,
        profile: TasteProfile,
        index: Int
    ) -> String {
        let signal = profile.signals.first
        let signalPhrase = signal.map { "\($0.key): \($0.value)" } ?? "your selections"

        guard let tag = primaryTag, let templates = tagReasonTemplates[tag] else {
            return "Fits your personal style — based on \(signalPhrase)."
        }

        let template = templates[index % templates.count]
        return template
            .replacingOccurrences(of: "{signal}", with: signalPhrase)
    }

    static let tagReasonTemplates: [TasteEngine.CanonicalTag: [String]] = [
        .midCenturyModern: [
            "Echoes the clean mid-century lines in your space — driven by {signal}.",
            "Pairs with your mid-century palette for a cohesive retro feel.",
            "Complements the organic curves your taste profile highlights.",
        ],
        .scandinavian: [
            "Matches the light, functional Scandinavian mood — grounded in {signal}.",
            "Reinforces the airy simplicity your photos reflect.",
            "Adds quiet warmth in line with your Scandinavian leanings.",
        ],
        .industrial: [
            "Brings raw industrial character that fits your {signal}.",
            "Pairs with the exposed-material edge your taste reveals.",
            "Anchors the urban texture running through your space.",
        ],
        .bohemian: [
            "Layers in bohemian richness — connects to your {signal}.",
            "Adds the collected, personal feel your taste calls for.",
            "Deepens the eclectic warmth your photos suggest.",
        ],
        .minimalist: [
            "Keeps things intentional — aligned with your {signal}.",
            "Supports the clean, pared-back look your profile favors.",
            "Lets negative space do the work, matching your minimalist eye.",
        ],
        .traditional: [
            "Brings time-tested elegance that resonates with your {signal}.",
            "Adds the craftsmanship and symmetry your taste gravitates toward.",
            "Reinforces the classic warmth woven through your space.",
        ],
        .coastal: [
            "Channels breezy coastal ease — rooted in your {signal}.",
            "Lightens the room with the relaxed vibe your photos suggest.",
            "Complements the natural, airy quality in your palette.",
        ],
        .rustic: [
            "Grounds the room with rustic warmth — tied to your {signal}.",
            "Adds the weathered, hearty texture your taste profile highlights.",
            "Brings honest materiality that echoes your rustic leanings.",
        ],
        .artDeco: [
            "Delivers bold Art Deco drama — driven by your {signal}.",
            "Adds geometric impact that matches your taste for contrast.",
            "Pairs luxe materials with the statement style your profile reveals.",
        ],
        .japandi: [
            "Balances serenity and function — connected to your {signal}.",
            "Reinforces the wabi-sabi calm your taste profile reflects.",
            "Blends Japanese restraint with the warmth your space carries.",
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
