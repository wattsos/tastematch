import Foundation

// MARK: - Discovery Type

enum DiscoveryType: String, Codable, CaseIterable {
    case designer
    case studio
    case object
    case material
    case movement
    case place
    case reference
}

// MARK: - Source Tier

enum SourceTier: String, Codable {
    case anchor
    case curated
    case emerging
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
        case .object, .place, .reference: return .objectsInTheWild
        case .material: return .materialIntelligence
        }
    }
}

// MARK: - Discovery Item

struct DiscoveryItem: Identifiable, Codable {
    let id: String
    let title: String
    let type: DiscoveryType
    let regions: [String]
    let body: String
    let clusters: [String]
    let axisWeights: [String: Double]
    let rarity: Double
    let yearRange: String?
    let links: [String]?
    let sourceTier: SourceTier
    let createdAt: Date?
    let imageURL: String?

    var layer: DiscoveryLayer {
        DiscoveryLayer.layer(for: type)
    }

    var primaryRegion: String {
        regions.first ?? ""
    }

    var primaryCluster: String {
        clusters.first ?? ""
    }

    var axes: [Axis: Double] {
        var result: [Axis: Double] = [:]
        for axis in Axis.allCases {
            if let value = axisWeights[axis.rawValue] {
                result[axis] = value
            }
        }
        return result
    }

    // MARK: - Backward-Compatible Decoding

    private enum CodingKeys: String, CodingKey {
        case id, title, type, body, axisWeights
        case regions, region
        case clusters, cluster
        case rarity, rarityScore
        case yearRange, links, sourceTier, createdAt
        case imageURL
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(type, forKey: .type)
        try c.encode(body, forKey: .body)
        try c.encode(axisWeights, forKey: .axisWeights)
        try c.encode(regions, forKey: .regions)
        try c.encode(clusters, forKey: .clusters)
        try c.encode(rarity, forKey: .rarity)
        try c.encodeIfPresent(yearRange, forKey: .yearRange)
        try c.encodeIfPresent(links, forKey: .links)
        try c.encode(sourceTier, forKey: .sourceTier)
        try c.encodeIfPresent(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(imageURL, forKey: .imageURL)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        body = try c.decode(String.self, forKey: .body)
        axisWeights = try c.decode([String: Double].self, forKey: .axisWeights)

        // type: "region" → .place
        let rawType = try c.decode(String.self, forKey: .type)
        type = rawType == "region" ? .place : (DiscoveryType(rawValue: rawType) ?? .reference)

        // regions: array or legacy single string
        if let arr = try? c.decode([String].self, forKey: .regions) {
            regions = arr
        } else if let single = try? c.decode(String.self, forKey: .region) {
            regions = [single]
        } else {
            regions = []
        }

        // clusters: array or legacy single string
        if let arr = try? c.decode([String].self, forKey: .clusters) {
            clusters = arr
        } else if let single = try? c.decode(String.self, forKey: .cluster) {
            clusters = [single]
        } else {
            clusters = []
        }

        // rarity or legacy rarityScore
        if let r = try? c.decode(Double.self, forKey: .rarity) {
            rarity = r
        } else if let r = try? c.decode(Double.self, forKey: .rarityScore) {
            rarity = r
        } else {
            rarity = 0.5
        }

        yearRange = try c.decodeIfPresent(String.self, forKey: .yearRange)
        links = try c.decodeIfPresent([String].self, forKey: .links)
        sourceTier = (try? c.decode(SourceTier.self, forKey: .sourceTier)) ?? .curated
        createdAt = try? c.decode(Date.self, forKey: .createdAt)
        imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
    }

    // MARK: - Memberwise Init

    init(
        id: String,
        title: String,
        type: DiscoveryType,
        regions: [String],
        body: String,
        clusters: [String],
        axisWeights: [String: Double],
        rarity: Double,
        yearRange: String? = nil,
        links: [String]? = nil,
        sourceTier: SourceTier = .curated,
        createdAt: Date? = nil,
        imageURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.regions = regions
        self.body = body
        self.clusters = clusters
        self.axisWeights = axisWeights
        self.rarity = rarity
        self.yearRange = yearRange
        self.links = links
        self.sourceTier = sourceTier
        self.createdAt = createdAt
        self.imageURL = imageURL
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
