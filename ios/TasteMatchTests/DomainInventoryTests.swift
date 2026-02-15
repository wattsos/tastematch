import XCTest
@testable import TasteMatch

final class DomainInventoryTests: XCTestCase {

    // MARK: - Commerce JSONs Load

    func testSpaceCatalog_loadsWithoutError() {
        let provider = LocalSeedCommerceProvider(filename: "commerce_space", bundle: Bundle(for: type(of: self)))
        let items = provider.load()
        XCTAssertGreaterThan(items.count, 0, "commerce_space.json should load items")
    }

    func testObjectsCatalog_loadsWithoutError() {
        let provider = LocalSeedCommerceProvider(filename: "commerce_objects", bundle: Bundle(for: type(of: self)))
        let items = provider.load()
        XCTAssertGreaterThan(items.count, 0, "commerce_objects.json should load items")
    }

    func testArtCatalog_loadsWithoutError() {
        let provider = LocalSeedCommerceProvider(filename: "commerce_art", bundle: Bundle(for: type(of: self)))
        let items = provider.load()
        XCTAssertGreaterThan(items.count, 0, "commerce_art.json should load items")
    }

    // MARK: - Objects Catalog Contains Object Categories

    func testObjectsCatalog_containsObjectCategories() {
        let provider = LocalSeedCommerceProvider(filename: "commerce_objects", bundle: Bundle(for: type(of: self)))
        let items = provider.load()
        let objectCategories: Set<ItemCategory> = [.timepiece, .bag, .designObject, .accessory]
        let categories = Set(items.map(\.category))
        let intersection = categories.intersection(objectCategories)
        XCTAssertGreaterThanOrEqual(intersection.count, 2,
            "Objects catalog should contain at least 2 object-specific categories, found: \(intersection)")
    }

    // MARK: - Art Catalog Has Rarity Tiers

    func testArtCatalog_hasRarityTierOnAllItems() {
        let provider = LocalSeedCommerceProvider(filename: "commerce_art", bundle: Bundle(for: type(of: self)))
        let items = provider.load()
        for item in items {
            XCTAssertNotNil(item.rarityTier,
                "\(item.skuId) should have a rarityTier")
        }
    }

    func testArtCatalog_allThreeRarityTiersPresent() {
        let provider = LocalSeedCommerceProvider(filename: "commerce_art", bundle: Bundle(for: type(of: self)))
        let items = provider.load()
        let tiers = Set(items.compactMap(\.rarityTier))
        XCTAssertTrue(tiers.contains(.archive), "Art catalog should contain archive tier")
        XCTAssertTrue(tiers.contains(.contemporary), "Art catalog should contain contemporary tier")
        XCTAssertTrue(tiers.contains(.emergent), "Art catalog should contain emergent tier")
    }

    // MARK: - DomainCatalog Caching

    func testDomainCatalog_caching() {
        DomainCatalog.resetCache()
        let items1 = DomainCatalog.items(for: .space)
        let items2 = DomainCatalog.items(for: .space)
        XCTAssertEqual(items1.count, items2.count, "Cached items should match")
    }

    // MARK: - DomainDiscovery Cluster Identification

    func testDomainDiscovery_spaceCluster() {
        let scores = AxisScores(
            minimalOrnate: -0.5, warmCool: -0.3, softStructured: 0.7,
            organicIndustrial: 0.9, lightDark: 0.8, neutralSaturated: -0.3, sparseLayered: 0.2
        )
        let cluster = DomainDiscovery.identifyCluster(scores, domain: .space)
        XCTAssertEqual(cluster, "industrialDark")
    }

    func testDomainDiscovery_objectsCluster_precision() {
        let scores = AxisScores(
            minimalOrnate: -0.3, warmCool: -0.2, softStructured: 0.8,
            organicIndustrial: 0.7, lightDark: 0.2, neutralSaturated: -0.3, sparseLayered: -0.2
        )
        let cluster = DomainDiscovery.identifyCluster(scores, domain: .objects)
        XCTAssertEqual(cluster, "precisionTool")
    }

    func testDomainDiscovery_artCluster_brutalGesture() {
        let scores = AxisScores(
            minimalOrnate: -0.2, warmCool: -0.5, softStructured: 0.7,
            organicIndustrial: 0.9, lightDark: 0.8, neutralSaturated: -0.3, sparseLayered: 0.1
        )
        let cluster = DomainDiscovery.identifyCluster(scores, domain: .art)
        XCTAssertEqual(cluster, "brutalGesture")
    }

    func testDomainDiscovery_artCluster_archiveCanon() {
        let scores = AxisScores(
            minimalOrnate: 0.6, warmCool: 0.7, softStructured: -0.2,
            organicIndustrial: -0.3, lightDark: -0.1, neutralSaturated: -0.2, sparseLayered: 0.5
        )
        let cluster = DomainDiscovery.identifyCluster(scores, domain: .art)
        XCTAssertEqual(cluster, "archiveCanon")
    }
}
