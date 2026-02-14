import Foundation

// MARK: - Discovery Engine

enum DiscoveryEngine {

    private static var cachedItems: [DiscoveryItem]?
    private static var provider: DiscoveryInventoryProvider = LocalNDJSONProvider()

    // MARK: - Provider

    static func setProvider(_ p: DiscoveryInventoryProvider) {
        provider = p
        cachedItems = nil
    }

    // MARK: - Load

    static func loadAll() -> [DiscoveryItem] {
        if let cached = cachedItems { return cached }
        let items = provider.loadItems()
        cachedItems = items
        return items
    }

    static func resetCache() {
        cachedItems = nil
    }

    // MARK: - Rank

    static func rank(
        items: [DiscoveryItem],
        axisScores: AxisScores,
        signals: DiscoverySignals? = nil
    ) -> [DiscoveryItem] {
        let dominantCluster = identifyCluster(axisScores)
        let now = Date()

        let scored = items.map { item -> (DiscoveryItem, Double) in
            let alignment = vectorAlignment(axisScores: axisScores, itemWeights: item.axisWeights)
            let clusterMatch: Double = item.primaryCluster == dominantCluster ? 1.0 : 0.0
            let affinity = userAffinity(item: item, signals: signals)
            let fresh = freshness(item: item, now: now)
            let score = 0.55 * alignment
                + 0.20 * clusterMatch
                + 0.10 * item.rarity
                + 0.10 * affinity
                + 0.05 * fresh
            return (item, score)
        }

        let sorted = scored.sorted {
            if $0.1 != $1.1 { return $0.1 > $1.1 }
            return $0.0.id < $1.0.id
        }

        return diversify(sorted.map(\.0), maxConsecutiveType: 2, maxConsecutiveCluster: 2)
    }

    // MARK: - Daily Radar

    /// Returns a day-keyed deterministic selection of discovery items.
    /// The ordering rotates daily based on `dayIndex + profileId hash + vectorHash`.
    static func dailyRadar(
        items: [DiscoveryItem],
        axisScores: AxisScores,
        signals: DiscoverySignals? = nil,
        profileId: UUID,
        vector: TasteVector,
        limit: Int = 6,
        dayIndex: Int? = nil
    ) -> [DiscoveryItem] {
        let ranked = rank(items: items, axisScores: axisScores, signals: signals)
        guard !ranked.isEmpty else { return [] }

        let day = dayIndex ?? currentDayIndex()
        let dayKey = buildDayKey(dayIndex: day, profileId: profileId, vector: vector)

        // Deterministic shuffle: score each item with a day-keyed hash
        let shuffled = ranked.map { item -> (DiscoveryItem, UInt64) in
            let combined = dayKey + item.id
            let hash = combined.utf8.reduce(UInt64(0)) { ($0 &+ UInt64($1)) &* 2654435761 }
            return (item, hash)
        }
        .sorted { $0.1 < $1.1 }
        .map(\.0)

        return Array(shuffled.prefix(limit))
    }

    /// Day index: days since Unix epoch.
    static func currentDayIndex() -> Int {
        Int(Date().timeIntervalSince1970 / 86400)
    }

    /// Deterministic key combining day, profile, and vector state.
    static func buildDayKey(dayIndex: Int, profileId: UUID, vector: TasteVector) -> String {
        let profileHash = profileId.uuidString.utf8.reduce(UInt64(0)) { ($0 &+ UInt64($1)) &* 31 }
        let vectorHash = vector.weights.sorted(by: { $0.key < $1.key })
            .map { "\($0.key):\(Int($0.value * 100))" }
            .joined(separator: "|")
            .utf8.reduce(UInt64(0)) { ($0 &+ UInt64($1)) &* 37 }
        return "\(dayIndex)|\(profileHash)|\(vectorHash)"
    }

    // MARK: - Paginate

    static func page(_ ranked: [DiscoveryItem], offset: Int, limit: Int = 20) -> (items: [DiscoveryItem], hasMore: Bool) {
        let slice = Array(ranked.dropFirst(offset).prefix(limit))
        return (slice, offset + limit < ranked.count)
    }

    // MARK: - Scoring

    static func vectorAlignment(axisScores: AxisScores, itemWeights: [String: Double]) -> Double {
        var dot = 0.0
        var magA = 0.0
        var magB = 0.0

        for axis in Axis.allCases {
            let a = axisScores.value(for: axis)
            let b = itemWeights[axis.rawValue, default: 0.0]
            dot += a * b
            magA += a * a
            magB += b * b
        }

        let denom = sqrt(magA) * sqrt(magB)
        guard denom > 0 else { return 0.5 }
        return (dot / denom + 1) / 2
    }

    static func identifyCluster(_ scores: AxisScores) -> String {
        let clusters: [(String, Double)] = [
            ("industrialDark", scores.organicIndustrial + scores.lightDark),
            ("warmOrganic", scores.warmCool - scores.organicIndustrial),
            ("minimalNeutral", -scores.minimalOrnate - scores.neutralSaturated),
            ("layeredSaturated", scores.sparseLayered + scores.neutralSaturated),
        ]
        return clusters.max(by: { $0.1 < $1.1 })!.0
    }

    // MARK: - User Affinity

    static func userAffinity(item: DiscoveryItem, signals: DiscoverySignals?) -> Double {
        guard let signals = signals else { return 0.5 }
        if signals.dismissedIds.contains(item.id) { return -1.0 }
        if signals.savedIds.contains(item.id) { return 1.0 }
        if signals.viewedIds.contains(item.id) { return 0.3 }
        return 0.5
    }

    // MARK: - Freshness

    static func freshness(item: DiscoveryItem, now: Date = Date()) -> Double {
        guard let created = item.createdAt else { return 0.5 }
        let days = now.timeIntervalSince(created) / 86400
        if days < 7 { return 1.0 }
        if days < 30 { return 0.7 }
        return 0.3
    }

    // MARK: - Diversity

    static func diversify(
        _ ranked: [DiscoveryItem],
        maxConsecutiveType: Int,
        maxConsecutiveCluster: Int
    ) -> [DiscoveryItem] {
        var result: [DiscoveryItem] = []
        var remaining = ranked

        while !remaining.isEmpty {
            let typeCount = consecutiveCount(in: result, by: \.type)
            let clusterCount = consecutiveCount(in: result, by: \.primaryCluster)

            let lastType = result.last?.type
            let lastCluster = result.last?.primaryCluster

            let needDifferentType = typeCount >= maxConsecutiveType && lastType != nil
            let needDifferentCluster = clusterCount >= maxConsecutiveCluster && lastCluster != nil

            if needDifferentType || needDifferentCluster {
                if let idx = remaining.firstIndex(where: { item in
                    let typeOk = !needDifferentType || item.type != lastType
                    let clusterOk = !needDifferentCluster || item.primaryCluster != lastCluster
                    return typeOk && clusterOk
                }) {
                    result.append(remaining.remove(at: idx))
                } else if let idx = remaining.firstIndex(where: { item in
                    let typeOk = !needDifferentType || item.type != lastType
                    return typeOk
                }) {
                    result.append(remaining.remove(at: idx))
                } else {
                    result.append(remaining.removeFirst())
                }
            } else {
                result.append(remaining.removeFirst())
            }
        }

        return result
    }

    private static func consecutiveCount<T: Equatable>(
        in items: [DiscoveryItem],
        by keyPath: KeyPath<DiscoveryItem, T>
    ) -> Int {
        guard let lastValue = items.last?[keyPath: keyPath] else { return 0 }
        var count = 0
        for item in items.reversed() {
            if item[keyPath: keyPath] == lastValue { count += 1 } else { break }
        }
        return count
    }
}
