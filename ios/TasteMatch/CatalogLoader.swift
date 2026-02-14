import Foundation

/// Loads catalog items from a bundled JSON file at runtime.
/// Falls back to the hardcoded MockCatalog if the JSON is missing or malformed.
struct BundleCatalogProvider: CatalogProvider {
    let items: [CatalogItem]

    init(filename: String = "catalog", bundle: Bundle = .main) {
        if let loaded = Self.load(filename: filename, bundle: bundle) {
            self.items = loaded
        } else {
            self.items = MockCatalog.items
        }
    }

    // MARK: - Private

    private static func load(filename: String, bundle: Bundle) -> [CatalogItem]? {
        guard let url = bundle.url(forResource: filename, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([CatalogEntry].self, from: data) else {
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

// MARK: - JSON Schema

/// Decodable mirror of a catalog.json entry.
private struct CatalogEntry: Decodable {
    let skuId: String
    let title: String
    let merchant: String
    let price: Double
    let imageURL: String
    let productURL: String
    let tags: [String]
}
