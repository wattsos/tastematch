import Foundation

// MARK: - Item Category

enum ItemCategory: String, Codable, CaseIterable {
    case lighting
    case textile
    case art
    case furniture
    case decor
    case timepiece
    case bag
    case designObject
    case accessory
    case painting
    case sculpture
    case print
    case photograph
    case installation
    case clothing
    case footwear
    case tech
    case jewelry
    case unknown
}

// MARK: - Art Rarity Tier

enum ArtRarityTier: String, Codable, CaseIterable {
    case archive
    case contemporary
    case emergent
}

// MARK: - Catalog Item

struct CatalogItem {
    let skuId: String
    let title: String
    let merchant: String
    let price: Double
    let imageURL: String
    let productURL: String
    let tags: [TasteEngine.CanonicalTag]
    let brand: String
    let currency: String
    let category: ItemCategory
    let materialTags: [String]
    let commerceAxisWeights: [String: Double]
    let objectAxisWeights: [String: Double]
    let discoveryClusters: [String]
    let affiliateURL: String?
    let rarityTier: ArtRarityTier?
    let movementCluster: String?
    let yearRange: String?

    init(
        skuId: String,
        title: String,
        merchant: String,
        price: Double,
        imageURL: String,
        productURL: String,
        tags: [TasteEngine.CanonicalTag],
        brand: String = "",
        currency: String = "USD",
        category: ItemCategory = .furniture,
        materialTags: [String] = [],
        commerceAxisWeights: [String: Double] = [:],
        objectAxisWeights: [String: Double] = [:],
        discoveryClusters: [String] = [],
        affiliateURL: String? = nil,
        rarityTier: ArtRarityTier? = nil,
        movementCluster: String? = nil,
        yearRange: String? = nil
    ) {
        self.skuId = skuId
        self.title = title
        self.merchant = merchant
        self.price = price
        self.imageURL = imageURL
        self.productURL = productURL
        self.tags = tags
        self.brand = brand.isEmpty ? merchant : brand
        self.currency = currency
        self.category = category
        self.materialTags = materialTags
        self.commerceAxisWeights = commerceAxisWeights
        self.objectAxisWeights = objectAxisWeights
        self.discoveryClusters = discoveryClusters
        self.affiliateURL = affiliateURL
        self.rarityTier = rarityTier
        self.movementCluster = movementCluster
        self.yearRange = yearRange
    }
}

// MARK: - Catalog Provider

protocol CatalogProvider {
    var items: [CatalogItem] { get }
}

struct MockCatalogProvider: CatalogProvider {
    let items: [CatalogItem] = MockCatalog.items
}

enum MockCatalog {

    private static var cachedItems: [CatalogItem]?
    private static var commerceProvider: CommerceInventoryProvider = LocalSeedCommerceProvider()

    /// Primary catalog access point. Loads from commerce_seed.json, falls back to legacy 30 items.
    @available(*, deprecated, message: "Use DomainCatalog.items(for:) instead")
    static var items: [CatalogItem] {
        if let cached = cachedItems { return cached }
        let loaded = commerceProvider.load()
        cachedItems = loaded
        return loaded
    }

    /// Replace the commerce provider (for testing).
    static func setProvider(_ provider: CommerceInventoryProvider) {
        commerceProvider = provider
        cachedItems = nil
    }

    /// Reset cached items (for testing).
    static func resetCache() {
        cachedItems = nil
    }

    /// Hardcoded legacy catalog (30 items). Used as fallback when commerce_seed.json is unavailable.
    static let legacyItems: [CatalogItem] = [
        // Mid-Century Modern
        CatalogItem(skuId: "sku-001", title: "Walnut Credenza", merchant: "Elm & Oak", price: 899,
                    imageURL: "https://picsum.photos/seed/sku-001/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-001",
                    tags: [.midCenturyModern]),
        CatalogItem(skuId: "sku-002", title: "Tapered Leg Coffee Table", merchant: "Studio Nova", price: 449,
                    imageURL: "https://picsum.photos/seed/sku-002/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-002",
                    tags: [.midCenturyModern, .minimalist]),
        CatalogItem(skuId: "sku-003", title: "Sputnik Chandelier", merchant: "Elm & Oak", price: 329,
                    imageURL: "https://picsum.photos/seed/sku-003/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-003",
                    tags: [.midCenturyModern, .artDeco]),

        // Scandinavian
        CatalogItem(skuId: "sku-004", title: "Birch Dining Chair", merchant: "Studio Nova", price: 275,
                    imageURL: "https://picsum.photos/seed/sku-004/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-004",
                    tags: [.scandinavian]),
        CatalogItem(skuId: "sku-005", title: "White Oak Bookshelf", merchant: "Elm & Oak", price: 620,
                    imageURL: "https://picsum.photos/seed/sku-005/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-005",
                    tags: [.scandinavian, .minimalist]),
        CatalogItem(skuId: "sku-006", title: "Wool Knit Throw", merchant: "Studio Nova", price: 89,
                    imageURL: "https://picsum.photos/seed/sku-006/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-006",
                    tags: [.scandinavian, .japandi]),

        // Industrial
        CatalogItem(skuId: "sku-007", title: "Iron Pipe Shelving Unit", merchant: "Elm & Oak", price: 540,
                    imageURL: "https://picsum.photos/seed/sku-007/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-007",
                    tags: [.industrial]),
        CatalogItem(skuId: "sku-008", title: "Steel Frame Desk", merchant: "Studio Nova", price: 410,
                    imageURL: "https://picsum.photos/seed/sku-008/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-008",
                    tags: [.industrial, .minimalist]),
        CatalogItem(skuId: "sku-009", title: "Cage Pendant Light", merchant: "Elm & Oak", price: 159,
                    imageURL: "https://picsum.photos/seed/sku-009/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-009",
                    tags: [.industrial, .rustic]),

        // Bohemian
        CatalogItem(skuId: "sku-010", title: "Macramé Wall Hanging", merchant: "Studio Nova", price: 75,
                    imageURL: "https://picsum.photos/seed/sku-010/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-010",
                    tags: [.bohemian]),
        CatalogItem(skuId: "sku-011", title: "Kilim Floor Cushion", merchant: "Elm & Oak", price: 135,
                    imageURL: "https://picsum.photos/seed/sku-011/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-011",
                    tags: [.bohemian, .rustic]),
        CatalogItem(skuId: "sku-012", title: "Rattan Peacock Chair", merchant: "Studio Nova", price: 485,
                    imageURL: "https://picsum.photos/seed/sku-012/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-012",
                    tags: [.bohemian, .coastal]),

        // Minimalist
        CatalogItem(skuId: "sku-013", title: "Floating Wall Shelf", merchant: "Elm & Oak", price: 110,
                    imageURL: "https://picsum.photos/seed/sku-013/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-013",
                    tags: [.minimalist]),
        CatalogItem(skuId: "sku-014", title: "Concrete Table Lamp", merchant: "Studio Nova", price: 95,
                    imageURL: "https://picsum.photos/seed/sku-014/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-014",
                    tags: [.minimalist, .industrial]),
        CatalogItem(skuId: "sku-015", title: "Matte Black Vase Set", merchant: "Elm & Oak", price: 65,
                    imageURL: "https://picsum.photos/seed/sku-015/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-015",
                    tags: [.minimalist, .japandi]),

        // Traditional
        CatalogItem(skuId: "sku-016", title: "Tufted Wingback Chair", merchant: "Studio Nova", price: 780,
                    imageURL: "https://picsum.photos/seed/sku-016/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-016",
                    tags: [.traditional]),
        CatalogItem(skuId: "sku-017", title: "Cherry Wood Side Table", merchant: "Elm & Oak", price: 345,
                    imageURL: "https://picsum.photos/seed/sku-017/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-017",
                    tags: [.traditional, .midCenturyModern]),
        CatalogItem(skuId: "sku-018", title: "Brass Table Lamp", merchant: "Studio Nova", price: 215,
                    imageURL: "https://picsum.photos/seed/sku-018/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-018",
                    tags: [.traditional, .artDeco]),

        // Coastal
        CatalogItem(skuId: "sku-019", title: "Linen Slipcovered Sofa", merchant: "Elm & Oak", price: 1250,
                    imageURL: "https://picsum.photos/seed/sku-019/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-019",
                    tags: [.coastal]),
        CatalogItem(skuId: "sku-020", title: "Driftwood Mirror Frame", merchant: "Studio Nova", price: 180,
                    imageURL: "https://picsum.photos/seed/sku-020/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-020",
                    tags: [.coastal, .rustic]),
        CatalogItem(skuId: "sku-021", title: "Sea Glass Pendant Light", merchant: "Elm & Oak", price: 225,
                    imageURL: "https://picsum.photos/seed/sku-021/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-021",
                    tags: [.coastal, .bohemian]),

        // Rustic
        CatalogItem(skuId: "sku-022", title: "Reclaimed Barn Wood Table", merchant: "Studio Nova", price: 975,
                    imageURL: "https://picsum.photos/seed/sku-022/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-022",
                    tags: [.rustic]),
        CatalogItem(skuId: "sku-023", title: "Cast Iron Candle Holder", merchant: "Elm & Oak", price: 55,
                    imageURL: "https://picsum.photos/seed/sku-023/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-023",
                    tags: [.rustic, .industrial]),
        CatalogItem(skuId: "sku-024", title: "Jute Area Rug", merchant: "Studio Nova", price: 320,
                    imageURL: "https://picsum.photos/seed/sku-024/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-024",
                    tags: [.rustic, .bohemian]),

        // Art Deco
        CatalogItem(skuId: "sku-025", title: "Geometric Mirror", merchant: "Elm & Oak", price: 290,
                    imageURL: "https://picsum.photos/seed/sku-025/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-025",
                    tags: [.artDeco]),
        CatalogItem(skuId: "sku-026", title: "Velvet Accent Chair", merchant: "Studio Nova", price: 595,
                    imageURL: "https://picsum.photos/seed/sku-026/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-026",
                    tags: [.artDeco, .traditional]),
        CatalogItem(skuId: "sku-027", title: "Gold Starburst Clock", merchant: "Elm & Oak", price: 145,
                    imageURL: "https://picsum.photos/seed/sku-027/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-027",
                    tags: [.artDeco, .midCenturyModern]),

        // Japandi
        CatalogItem(skuId: "sku-028", title: "Low Platform Bed Frame", merchant: "Studio Nova", price: 860,
                    imageURL: "https://picsum.photos/seed/sku-028/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-028",
                    tags: [.japandi]),
        CatalogItem(skuId: "sku-029", title: "Wabi-Sabi Ceramic Bowl Set", merchant: "Elm & Oak", price: 85,
                    imageURL: "https://picsum.photos/seed/sku-029/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-029",
                    tags: [.japandi, .minimalist]),
        CatalogItem(skuId: "sku-030", title: "Paper Lantern Pendant", merchant: "Studio Nova", price: 110,
                    imageURL: "https://picsum.photos/seed/sku-030/400/300",
                    productURL: "https://cdn.burgundy.app/products/sku-030",
                    tags: [.japandi, .scandinavian]),
    ]
}
