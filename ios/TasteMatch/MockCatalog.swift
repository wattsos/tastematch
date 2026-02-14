import Foundation

struct CatalogItem {
    let skuId: String
    let title: String
    let merchant: String
    let price: Double
    let imageURL: String
    let productURL: String
    let tags: [TasteEngine.CanonicalTag]
}

protocol CatalogProvider {
    var items: [CatalogItem] { get }
}

struct MockCatalogProvider: CatalogProvider {
    let items: [CatalogItem] = MockCatalog.items
}

enum MockCatalog {

    static let items: [CatalogItem] = [
        // Mid-Century Modern
        CatalogItem(skuId: "sku-001", title: "Walnut Credenza", merchant: "Elm & Oak", price: 899,
                    imageURL: "https://cdn.burgundy.app/images/sku-001.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-001",
                    tags: [.midCenturyModern]),
        CatalogItem(skuId: "sku-002", title: "Tapered Leg Coffee Table", merchant: "Studio Nova", price: 449,
                    imageURL: "https://cdn.burgundy.app/images/sku-002.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-002",
                    tags: [.midCenturyModern, .minimalist]),
        CatalogItem(skuId: "sku-003", title: "Sputnik Chandelier", merchant: "Elm & Oak", price: 329,
                    imageURL: "https://cdn.burgundy.app/images/sku-003.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-003",
                    tags: [.midCenturyModern, .artDeco]),

        // Scandinavian
        CatalogItem(skuId: "sku-004", title: "Birch Dining Chair", merchant: "Studio Nova", price: 275,
                    imageURL: "https://cdn.burgundy.app/images/sku-004.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-004",
                    tags: [.scandinavian]),
        CatalogItem(skuId: "sku-005", title: "White Oak Bookshelf", merchant: "Elm & Oak", price: 620,
                    imageURL: "https://cdn.burgundy.app/images/sku-005.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-005",
                    tags: [.scandinavian, .minimalist]),
        CatalogItem(skuId: "sku-006", title: "Wool Knit Throw", merchant: "Studio Nova", price: 89,
                    imageURL: "https://cdn.burgundy.app/images/sku-006.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-006",
                    tags: [.scandinavian, .japandi]),

        // Industrial
        CatalogItem(skuId: "sku-007", title: "Iron Pipe Shelving Unit", merchant: "Elm & Oak", price: 540,
                    imageURL: "https://cdn.burgundy.app/images/sku-007.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-007",
                    tags: [.industrial]),
        CatalogItem(skuId: "sku-008", title: "Steel Frame Desk", merchant: "Studio Nova", price: 410,
                    imageURL: "https://cdn.burgundy.app/images/sku-008.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-008",
                    tags: [.industrial, .minimalist]),
        CatalogItem(skuId: "sku-009", title: "Cage Pendant Light", merchant: "Elm & Oak", price: 159,
                    imageURL: "https://cdn.burgundy.app/images/sku-009.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-009",
                    tags: [.industrial, .rustic]),

        // Bohemian
        CatalogItem(skuId: "sku-010", title: "Macramé Wall Hanging", merchant: "Studio Nova", price: 75,
                    imageURL: "https://cdn.burgundy.app/images/sku-010.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-010",
                    tags: [.bohemian]),
        CatalogItem(skuId: "sku-011", title: "Kilim Floor Cushion", merchant: "Elm & Oak", price: 135,
                    imageURL: "https://cdn.burgundy.app/images/sku-011.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-011",
                    tags: [.bohemian, .rustic]),
        CatalogItem(skuId: "sku-012", title: "Rattan Peacock Chair", merchant: "Studio Nova", price: 485,
                    imageURL: "https://cdn.burgundy.app/images/sku-012.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-012",
                    tags: [.bohemian, .coastal]),

        // Minimalist
        CatalogItem(skuId: "sku-013", title: "Floating Wall Shelf", merchant: "Elm & Oak", price: 110,
                    imageURL: "https://cdn.burgundy.app/images/sku-013.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-013",
                    tags: [.minimalist]),
        CatalogItem(skuId: "sku-014", title: "Concrete Table Lamp", merchant: "Studio Nova", price: 95,
                    imageURL: "https://cdn.burgundy.app/images/sku-014.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-014",
                    tags: [.minimalist, .industrial]),
        CatalogItem(skuId: "sku-015", title: "Matte Black Vase Set", merchant: "Elm & Oak", price: 65,
                    imageURL: "https://cdn.burgundy.app/images/sku-015.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-015",
                    tags: [.minimalist, .japandi]),

        // Traditional
        CatalogItem(skuId: "sku-016", title: "Tufted Wingback Chair", merchant: "Studio Nova", price: 780,
                    imageURL: "https://cdn.burgundy.app/images/sku-016.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-016",
                    tags: [.traditional]),
        CatalogItem(skuId: "sku-017", title: "Cherry Wood Side Table", merchant: "Elm & Oak", price: 345,
                    imageURL: "https://cdn.burgundy.app/images/sku-017.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-017",
                    tags: [.traditional, .midCenturyModern]),
        CatalogItem(skuId: "sku-018", title: "Brass Table Lamp", merchant: "Studio Nova", price: 215,
                    imageURL: "https://cdn.burgundy.app/images/sku-018.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-018",
                    tags: [.traditional, .artDeco]),

        // Coastal
        CatalogItem(skuId: "sku-019", title: "Linen Slipcovered Sofa", merchant: "Elm & Oak", price: 1250,
                    imageURL: "https://cdn.burgundy.app/images/sku-019.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-019",
                    tags: [.coastal]),
        CatalogItem(skuId: "sku-020", title: "Driftwood Mirror Frame", merchant: "Studio Nova", price: 180,
                    imageURL: "https://cdn.burgundy.app/images/sku-020.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-020",
                    tags: [.coastal, .rustic]),
        CatalogItem(skuId: "sku-021", title: "Sea Glass Pendant Light", merchant: "Elm & Oak", price: 225,
                    imageURL: "https://cdn.burgundy.app/images/sku-021.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-021",
                    tags: [.coastal, .bohemian]),

        // Rustic
        CatalogItem(skuId: "sku-022", title: "Reclaimed Barn Wood Table", merchant: "Studio Nova", price: 975,
                    imageURL: "https://cdn.burgundy.app/images/sku-022.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-022",
                    tags: [.rustic]),
        CatalogItem(skuId: "sku-023", title: "Cast Iron Candle Holder", merchant: "Elm & Oak", price: 55,
                    imageURL: "https://cdn.burgundy.app/images/sku-023.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-023",
                    tags: [.rustic, .industrial]),
        CatalogItem(skuId: "sku-024", title: "Jute Area Rug", merchant: "Studio Nova", price: 320,
                    imageURL: "https://cdn.burgundy.app/images/sku-024.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-024",
                    tags: [.rustic, .bohemian]),

        // Art Deco
        CatalogItem(skuId: "sku-025", title: "Geometric Mirror", merchant: "Elm & Oak", price: 290,
                    imageURL: "https://cdn.burgundy.app/images/sku-025.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-025",
                    tags: [.artDeco]),
        CatalogItem(skuId: "sku-026", title: "Velvet Accent Chair", merchant: "Studio Nova", price: 595,
                    imageURL: "https://cdn.burgundy.app/images/sku-026.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-026",
                    tags: [.artDeco, .traditional]),
        CatalogItem(skuId: "sku-027", title: "Gold Starburst Clock", merchant: "Elm & Oak", price: 145,
                    imageURL: "https://cdn.burgundy.app/images/sku-027.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-027",
                    tags: [.artDeco, .midCenturyModern]),

        // Japandi
        CatalogItem(skuId: "sku-028", title: "Low Platform Bed Frame", merchant: "Studio Nova", price: 860,
                    imageURL: "https://cdn.burgundy.app/images/sku-028.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-028",
                    tags: [.japandi]),
        CatalogItem(skuId: "sku-029", title: "Wabi-Sabi Ceramic Bowl Set", merchant: "Elm & Oak", price: 85,
                    imageURL: "https://cdn.burgundy.app/images/sku-029.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-029",
                    tags: [.japandi, .minimalist]),
        CatalogItem(skuId: "sku-030", title: "Paper Lantern Pendant", merchant: "Studio Nova", price: 110,
                    imageURL: "https://cdn.burgundy.app/images/sku-030.jpg",
                    productURL: "https://cdn.burgundy.app/products/sku-030",
                    tags: [.japandi, .scandinavian]),
    ]
}
