import Foundation

// MARK: - Domain Catalog

enum DomainCatalog {

    private static var cache: [TasteDomain: [CatalogItem]] = [:]

    static func items(for domain: TasteDomain) -> [CatalogItem] {
        if let cached = cache[domain] { return cached }
        let provider = LocalSeedCommerceProvider(filename: domain.commerceFilename)
        let loaded = provider.load()
        cache[domain] = loaded
        return loaded
    }

    static func resetCache() {
        cache.removeAll()
    }
}
