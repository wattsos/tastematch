import XCTest
@testable import TasteMatch

final class CommerceRankingTests: XCTestCase {

    private func loadCommerceItems() -> [CatalogItem] {
        let provider = LocalSeedCommerceProvider(bundle: Bundle(for: type(of: self)))
        return provider.load()
    }

    private func makeVector(_ weights: [String: Double]) -> TasteVector {
        var all: [String: Double] = [:]
        for tag in TasteEngine.CanonicalTag.allCases {
            all[String(describing: tag)] = 0.0
        }
        for (k, v) in weights { all[k] = v }
        return TasteVector(weights: all)
    }

    // MARK: - Material filter restricts results

    func testMaterialFilter_restrictsResults() {
        let items = loadCommerceItems()
        let vector = makeVector(["industrial": 0.8])
        let axisScores = AxisMapping.computeAxisScores(from: vector)

        let allResults = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items
        )
        let brassResults = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items, materialFilter: "brass"
        )

        XCTAssertGreaterThan(allResults.count, brassResults.count,
            "Material filter should reduce result count")
        // Verify all brass results actually contain brass
        let brassSkus = Set(brassResults.map(\.skuId))
        let brassItems = items.filter { brassSkus.contains($0.skuId) }
        for item in brassItems {
            XCTAssertTrue(
                item.materialTags.contains { $0.lowercased().contains("brass") },
                "\(item.skuId) should have brass in materialTags"
            )
        }
    }

    // MARK: - Category filter restricts results

    func testCategoryFilter_restrictsResults() {
        let items = loadCommerceItems()
        let vector = makeVector(["scandinavian": 0.8])
        let axisScores = AxisMapping.computeAxisScores(from: vector)

        let allResults = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items
        )
        let textileResults = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items,
            categoryFilter: .textile
        )

        XCTAssertGreaterThan(allResults.count, textileResults.count,
            "Category filter should reduce result count")
        XCTAssertGreaterThan(textileResults.count, 0,
            "Should have some textile results")
    }

    // MARK: - Determinism

    func testRankCommerceItems_isDeterministic() {
        let items = loadCommerceItems()
        let vector = makeVector(["industrial": 0.7, "minimalist": 0.3])
        let axisScores = AxisMapping.computeAxisScores(from: vector)

        let result1 = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items
        )
        let result2 = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items
        )

        XCTAssertEqual(result1.map(\.skuId), result2.map(\.skuId),
            "Same inputs must produce same ranking order")
    }

    // MARK: - Combined filters

    func testCombinedFilters_materialAndCategory() {
        let items = loadCommerceItems()
        let vector = makeVector(["bohemian": 0.8])
        let axisScores = AxisMapping.computeAxisScores(from: vector)

        let results = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores, items: items,
            materialFilter: "wool", categoryFilter: .textile
        )

        let skus = Set(results.map(\.skuId))
        let matchedItems = items.filter { skus.contains($0.skuId) }
        for item in matchedItems {
            XCTAssertEqual(item.category, .textile)
            XCTAssertTrue(
                item.materialTags.contains { $0.lowercased().contains("wool") },
                "\(item.skuId) should have wool in materialTags"
            )
        }
    }
}
