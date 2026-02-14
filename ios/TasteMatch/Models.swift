import Foundation

struct TasteTag: Identifiable, Codable {
    let id: UUID
    let key: String
    let label: String
    let confidence: Double

    init(id: UUID = UUID(), key: String, label: String, confidence: Double) {
        self.id = id
        self.key = key
        self.label = label
        self.confidence = confidence
    }
}

struct Signal: Identifiable, Codable {
    let id: UUID
    let key: String
    let value: String

    init(id: UUID = UUID(), key: String, value: String) {
        self.id = id
        self.key = key
        self.value = value
    }
}

struct TasteProfile: Identifiable, Codable {
    let id: UUID
    let tags: [TasteTag]
    let story: String
    let signals: [Signal]
    var profileName: String
    var profileNameVersion: Int
    var profileNameUpdatedAt: Date?
    var profileNameBasisHash: String
    var previousNames: [String]

    var displayName: String {
        profileName.isEmpty ? (tags.first?.label ?? "Profile") : profileName
    }

    init(id: UUID = UUID(), tags: [TasteTag], story: String, signals: [Signal]) {
        self.id = id
        self.tags = tags
        self.story = story
        self.signals = signals
        self.profileName = ""
        self.profileNameVersion = 0
        self.profileNameUpdatedAt = nil
        self.profileNameBasisHash = ""
        self.previousNames = []
    }

    // Backward-compatible decoding — old JSON without naming fields still decodes.
    enum CodingKeys: String, CodingKey {
        case id, tags, story, signals
        case profileName, profileNameVersion, profileNameUpdatedAt
        case profileNameBasisHash, previousNames
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        tags = try c.decode([TasteTag].self, forKey: .tags)
        story = try c.decode(String.self, forKey: .story)
        signals = try c.decode([Signal].self, forKey: .signals)
        profileName = try c.decodeIfPresent(String.self, forKey: .profileName) ?? ""
        profileNameVersion = try c.decodeIfPresent(Int.self, forKey: .profileNameVersion) ?? 0
        profileNameUpdatedAt = try c.decodeIfPresent(Date.self, forKey: .profileNameUpdatedAt)
        profileNameBasisHash = try c.decodeIfPresent(String.self, forKey: .profileNameBasisHash) ?? ""
        previousNames = try c.decodeIfPresent([String].self, forKey: .previousNames) ?? []
    }
}

struct RecommendationItem: Identifiable, Codable, Hashable {
    let skuId: String
    let title: String
    let subtitle: String
    let reason: String
    let attributionConfidence: Double
    let price: Double
    let imageURL: String?
    let merchant: String
    let productURL: String
    let brand: String
    let affiliateURL: String?

    var id: String { skuId }

    init(skuId: String, title: String, subtitle: String, reason: String, attributionConfidence: Double, price: Double = 0, imageURL: String? = nil, merchant: String, productURL: String, brand: String = "", affiliateURL: String? = nil) {
        self.skuId = skuId
        self.title = title
        self.subtitle = subtitle
        self.reason = reason
        self.attributionConfidence = min(1, max(0, attributionConfidence))
        self.price = price
        self.imageURL = imageURL
        self.merchant = merchant
        self.productURL = productURL
        self.brand = brand.isEmpty ? merchant : brand
        self.affiliateURL = affiliateURL
    }

    // Backward-compatible decoding — old JSON without brand/affiliateURL still decodes.
    enum CodingKeys: String, CodingKey {
        case skuId, title, subtitle, reason, attributionConfidence
        case price, imageURL, merchant, productURL, brand, affiliateURL
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        skuId = try c.decode(String.self, forKey: .skuId)
        title = try c.decode(String.self, forKey: .title)
        subtitle = try c.decode(String.self, forKey: .subtitle)
        reason = try c.decode(String.self, forKey: .reason)
        let rawConf = try c.decode(Double.self, forKey: .attributionConfidence)
        attributionConfidence = min(1, max(0, rawConf))
        price = try c.decodeIfPresent(Double.self, forKey: .price) ?? 0
        imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
        merchant = try c.decode(String.self, forKey: .merchant)
        productURL = try c.decode(String.self, forKey: .productURL)
        let rawBrand = try c.decodeIfPresent(String.self, forKey: .brand) ?? ""
        brand = rawBrand.isEmpty ? merchant : rawBrand
        affiliateURL = try c.decodeIfPresent(String.self, forKey: .affiliateURL)
    }
}

struct AnalyzeRequest: Codable {
    let imageData: [Data]
    let roomContext: String
    let goal: String
}

struct AnalyzeResponse: Codable {
    let tasteProfile: TasteProfile
    let recommendations: [RecommendationItem]
}

enum RoomContext: String, CaseIterable, Identifiable, Codable {
    case livingRoom = "Living Room"
    case bedroom = "Bedroom"
    case kitchen = "Kitchen"
    case office = "Office"
    case bathroom = "Bathroom"
    case outdoor = "Outdoor"

    var id: String { rawValue }
}

enum DesignGoal: String, CaseIterable, Identifiable, Codable {
    case refresh = "Quick Refresh"
    case overhaul = "Full Overhaul"
    case accent = "Add Accents"
    case organize = "Organize & Declutter"

    var id: String { rawValue }
}
