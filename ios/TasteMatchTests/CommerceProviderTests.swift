import XCTest
@testable import TasteMatch

final class CommerceProviderTests: XCTestCase {

    // MARK: - Provider loads 150+ items

    func testLocalSeedProvider_loadsAtLeast150Items() {
        let provider = LocalSeedCommerceProvider(bundle: Bundle(for: type(of: self)))
        let items = provider.load()
        XCTAssertGreaterThanOrEqual(items.count, 150,
            "Commerce seed should contain at least 150 items, got \(items.count)")
    }

    // MARK: - Every item has non-empty materialTags

    func testAllItems_haveNonEmptyMaterialTags() {
        let provider = LocalSeedCommerceProvider(bundle: Bundle(for: type(of: self)))
        let items = provider.load()
        for item in items {
            XCTAssertFalse(item.materialTags.isEmpty,
                "\(item.skuId) should have non-empty materialTags")
        }
    }

    // MARK: - Every item has axisWeights

    func testAllItems_haveAxisWeights() {
        let provider = LocalSeedCommerceProvider(bundle: Bundle(for: type(of: self)))
        let items = provider.load()
        for item in items {
            XCTAssertFalse(item.commerceAxisWeights.isEmpty,
                "\(item.skuId) should have non-empty axisWeights")
            XCTAssertEqual(item.commerceAxisWeights.count, 7,
                "\(item.skuId) should have 7 axis weights")
        }
    }

    // MARK: - Every item has discoveryClusters

    func testAllItems_haveDiscoveryClusters() {
        let provider = LocalSeedCommerceProvider(bundle: Bundle(for: type(of: self)))
        let items = provider.load()
        for item in items {
            XCTAssertFalse(item.discoveryClusters.isEmpty,
                "\(item.skuId) should have non-empty discoveryClusters")
        }
    }

    // MARK: - Category distribution

    func testCategoryDistribution_100LightingAnd50Textile() {
        let provider = LocalSeedCommerceProvider(bundle: Bundle(for: type(of: self)))
        let items = provider.load()
        let lighting = items.filter { $0.category == .lighting }
        let textile = items.filter { $0.category == .textile }
        XCTAssertGreaterThanOrEqual(lighting.count, 100, "Should have at least 100 lighting items")
        XCTAssertGreaterThanOrEqual(textile.count, 50, "Should have at least 50 textile items")
    }
}
