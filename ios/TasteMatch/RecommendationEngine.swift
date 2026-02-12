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

        return top.map { entry in
            let whyThisFits = buildWhyThisFits(
                primaryTag: primaryTag,
                profile: profile
            )

            let subtitle = "\(entry.item.merchant) — $\(Int(entry.item.price))"

            return RecommendationItem(
                title: entry.item.title,
                subtitle: subtitle,
                reason: whyThisFits
            )
        }
    }
}

// MARK: - Private Helpers

private extension RecommendationEngine {

    static func buildWhyThisFits(
        primaryTag: TasteEngine.CanonicalTag?,
        profile: TasteProfile
    ) -> String {
        let tagLabel = primaryTag?.rawValue ?? "personal"
        if let firstSignal = profile.signals.first {
            return "Matches your \(tagLabel) style — complements your \(firstSignal.key): \(firstSignal.value)."
        }
        return "Matches your \(tagLabel) style."
    }

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
