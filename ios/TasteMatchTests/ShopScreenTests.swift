import XCTest
@testable import TasteMatch

final class ShopScreenTests: XCTestCase {

    private func makeVector(_ weights: [String: Double]) -> TasteVector {
        var all: [String: Double] = [:]
        for tag in TasteEngine.CanonicalTag.allCases {
            all[String(describing: tag)] = 0.0
        }
        for (k, v) in weights { all[k] = v }
        return TasteVector(weights: all)
    }

    // MARK: - Search Filtering

    func testSearchFiltering_narrowsByTitle() {
        let items = loadCommerceItems()
        let vector = makeVector(["scandinavian": 0.8])
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        let ranked = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items
        )

        let query = "pendant"
        let filtered = ranked.filter {
            $0.title.lowercased().contains(query) || $0.brand.lowercased().contains(query)
        }

        XCTAssertGreaterThan(ranked.count, filtered.count,
            "Search should narrow results")
        for item in filtered {
            XCTAssertTrue(
                item.title.lowercased().contains(query) || item.brand.lowercased().contains(query),
                "\(item.title) should match query '\(query)'"
            )
        }
    }

    // MARK: - Category Filter

    func testCategoryFilter_narrowsResults() {
        let items = loadCommerceItems()
        let vector = makeVector(["industrial": 0.7])
        let axisScores = AxisMapping.computeAxisScores(from: vector)

        let all = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items
        )
        let lightingOnly = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items,
            categoryFilter: .lighting
        )

        XCTAssertGreaterThan(all.count, lightingOnly.count,
            "Category filter should reduce result count")
        XCTAssertGreaterThan(lightingOnly.count, 0,
            "Should have some lighting results")
    }

    // MARK: - Material Filter

    func testMaterialFilter_narrowsResults() {
        let items = loadCommerceItems()
        let vector = makeVector(["bohemian": 0.8])
        let axisScores = AxisMapping.computeAxisScores(from: vector)

        let all = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items
        )
        let woolOnly = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items,
            materialFilter: "wool"
        )

        XCTAssertGreaterThan(all.count, woolOnly.count,
            "Material filter should reduce result count")
    }

    // MARK: - Deterministic Pagination

    func testPagination_isDeterministic() {
        let items = loadCommerceItems()
        let vector = makeVector(["scandinavian": 0.6, "minimalist": 0.4])
        let axisScores = AxisMapping.computeAxisScores(from: vector)

        let ranked1 = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items
        )
        let ranked2 = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items
        )

        XCTAssertEqual(ranked1.map(\.skuId), ranked2.map(\.skuId),
            "Same inputs must produce same ranking order")

        // Simulate pagination: page 1 and page 2 should not overlap
        let page1 = Array(ranked1.prefix(20))
        let page2 = Array(ranked1.dropFirst(20).prefix(20))
        let page1Skus = Set(page1.map(\.skuId))
        let page2Skus = Set(page2.map(\.skuId))
        XCTAssertTrue(page1Skus.isDisjoint(with: page2Skus),
            "Pagination pages should not overlap")
    }

    // MARK: - Helpers

    private func loadCommerceItems() -> [CatalogItem] {
        let provider = LocalSeedCommerceProvider(bundle: Bundle(for: type(of: self)))
        return provider.load()
    }
}
