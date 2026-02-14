import Foundation

// MARK: - Commerce Inventory Provider

protocol CommerceInventoryProvider {
    func load() -> [CatalogItem]
}

// MARK: - Local Seed Commerce Provider

/// Loads commerce catalog from a bundled commerce_seed.json.
/// Falls back to the legacy MockCatalog if the file is missing or malformed.
struct LocalSeedCommerceProvider: CommerceInventoryProvider {

    private let filename: String
    private let bundle: Bundle

    init(filename: String = "commerce_seed", bundle: Bundle = .main) {
        self.filename = filename
        self.bundle = bundle
    }

    func load() -> [CatalogItem] {
        if let items = Self.loadSeed(filename: filename, bundle: bundle) {
            return items
        }
        return MockCatalog.legacyItems
    }

    // MARK: - Private

    private static func loadSeed(filename: String, bundle: Bundle) -> [CatalogItem]? {
        guard let url = bundle.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([CommerceEntry].self, from: data) else {
            return nil
        }

        let mapped: [CatalogItem] = entries.compactMap { entry in
            let tags = entry.tags.compactMap { tagByKey[$0] }
            guard !tags.isEmpty else { return nil }
            let category = ItemCategory(rawValue: entry.category) ?? .unknown
            return CatalogItem(
                skuId: entry.skuId,
                title: entry.title,
                merchant: entry.merchant,
                price: entry.price,
                imageURL: entry.imageURL,
                productURL: entry.productURL,
                tags: tags,
                brand: entry.brand,
                currency: entry.currency,
                category: category,
                materialTags: entry.materialTags,
                commerceAxisWeights: entry.axisWeights,
                discoveryClusters: entry.discoveryClusters,
                affiliateURL: entry.affiliateURL
            )
        }

        return mapped.isEmpty ? nil : mapped
    }

    private static let tagByKey: [String: TasteEngine.CanonicalTag] = Dictionary(
        uniqueKeysWithValues: TasteEngine.CanonicalTag.allCases.map { (String(describing: $0), $0) }
    )
}

// MARK: - Legacy Bundle Catalog Provider

/// Loads catalog items from a bundled catalog.json file at runtime.
/// Falls back to the hardcoded MockCatalog if the JSON is missing or malformed.
struct BundleCatalogProvider: CatalogProvider {
    let items: [CatalogItem]

    init(filename: String = "catalog", bundle: Bundle = .main) {
        if let loaded = Self.load(filename: filename, bundle: bundle) {
            self.items = loaded
        } else {
            self.items = MockCatalog.legacyItems
        }
    }

    private static func load(filename: String, bundle: Bundle) -> [CatalogItem]? {
        guard let url = bundle.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([LegacyCatalogEntry].self, from: data) else {
            return nil
        }

        let mapped: [CatalogItem] = entries.compactMap { entry in
            let tags = entry.tags.compactMap { tagByKey[$0] }
            guard !tags.isEmpty else { return nil }
            return CatalogItem(
                skuId: entry.skuId,
                title: entry.title,
                merchant: entry.merchant,
                price: entry.price,
                imageURL: entry.imageURL,
                productURL: entry.productURL,
                tags: tags
            )
        }

        return mapped.isEmpty ? nil : mapped
    }

    private static let tagByKey: [String: TasteEngine.CanonicalTag] = Dictionary(
        uniqueKeysWithValues: TasteEngine.CanonicalTag.allCases.map { (String(describing: $0), $0) }
    )
}

// MARK: - JSON Schemas

/// Decodable mirror of a commerce_seed.json entry.
struct CommerceEntry: Decodable {
    let skuId: String
    let title: String
    let brand: String
    let merchant: String
    let price: Double
    let currency: String
    let imageURL: String
    let productURL: String
    let affiliateURL: String?
    let category: String
    let tags: [String]
    let materialTags: [String]
    let axisWeights: [String: Double]
    let discoveryClusters: [String]
}

/// Decodable mirror of a legacy catalog.json entry.
private struct LegacyCatalogEntry: Decodable {
    let skuId: String
    let title: String
    let merchant: String
    let price: Double
    let imageURL: String
    let productURL: String
    let tags: [String]
}
