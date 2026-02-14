import Foundation

// MARK: - Discovery Type

enum DiscoveryType: String, Codable, CaseIterable {
    case designer
    case studio
    case object
    case material
    case movement
    case region
    case reference
}

// MARK: - Discovery Layer

enum DiscoveryLayer: String, CaseIterable {
    case culturalSignals
    case objectsInTheWild
    case materialIntelligence

    var label: String {
        switch self {
        case .culturalSignals: return "CULTURAL SIGNALS"
        case .objectsInTheWild: return "OBJECTS IN THE WILD"
        case .materialIntelligence: return "MATERIAL INTELLIGENCE"
        }
    }

    static func layer(for type: DiscoveryType) -> DiscoveryLayer {
        switch type {
        case .designer, .studio, .movement: return .culturalSignals
        case .object, .region, .reference: return .objectsInTheWild
        case .material: return .materialIntelligence
        }
    }
}

// MARK: - Discovery Item

struct DiscoveryItem: Identifiable, Codable {
    let id: String
    let title: String
    let type: DiscoveryType
    let region: String
    let body: String
    let cluster: String
    let axisWeights: [String: Double]
    let rarityScore: Double

    var layer: DiscoveryLayer {
        DiscoveryLayer.layer(for: type)
    }
}

extension DiscoveryItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DiscoveryItem, rhs: DiscoveryItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Discovery Engine

enum DiscoveryEngine {

    private static var cachedItems: [DiscoveryItem]?

    // MARK: - Load

    static func loadAll() -> [DiscoveryItem] {
        if let cached = cachedItems { return cached }
        guard let url = Bundle.main.url(forResource: "discovery", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([DiscoveryItem].self, from: data) else {
            return []
        }
        cachedItems = items
        return items
    }

    static func resetCache() {
        cachedItems = nil
    }

    // MARK: - Rank

    static func rank(items: [DiscoveryItem], axisScores: AxisScores) -> [DiscoveryItem] {
        let dominantCluster = identifyCluster(axisScores)

        let scored = items.map { item -> (DiscoveryItem, Double) in
            let alignment = vectorAlignment(axisScores: axisScores, itemWeights: item.axisWeights)
            let clusterBoost: Double = item.cluster == dominantCluster ? 1.0 : 0.0
            let score = alignment * 0.6 + clusterBoost * 0.2 + item.rarityScore * 0.1
            return (item, score)
        }

        let sorted = scored.sorted {
            if $0.1 != $1.1 { return $0.1 > $1.1 }
            return $0.0.id < $1.0.id
        }

        return diversify(sorted.map(\.0), maxConsecutive: 4)
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

    static func diversify(_ ranked: [DiscoveryItem], maxConsecutive: Int) -> [DiscoveryItem] {
        var result: [DiscoveryItem] = []
        var remaining = ranked

        while !remaining.isEmpty {
            let count = consecutiveTypeCount(in: result)

            if count >= maxConsecutive, let lastType = result.last?.type {
                if let idx = remaining.firstIndex(where: { $0.type != lastType }) {
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

    private static func consecutiveTypeCount(in items: [DiscoveryItem]) -> Int {
        guard let lastType = items.last?.type else { return 0 }
        var count = 0
        for item in items.reversed() {
            if item.type == lastType { count += 1 } else { break }
        }
        return count
    }
}
