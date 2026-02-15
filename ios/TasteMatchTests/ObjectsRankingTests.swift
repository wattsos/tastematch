import XCTest
@testable import TasteMatch

final class ObjectsRankingTests: XCTestCase {

    // MARK: - Helpers

    private func makeItem(
        skuId: String,
        objectAxisWeights: [String: Double] = [:],
        commerceAxisWeights: [String: Double] = [:],
        discoveryClusters: [String] = [],
        rarityTier: ArtRarityTier? = nil,
        yearRange: String? = nil
    ) -> CatalogItem {
        CatalogItem(
            skuId: skuId,
            title: "Item \(skuId)",
            merchant: "Test",
            price: 100,
            imageURL: "",
            productURL: "",
            tags: [],
            brand: "TestBrand",
            category: .designObject,
            commerceAxisWeights: commerceAxisWeights,
            objectAxisWeights: objectAxisWeights,
            discoveryClusters: discoveryClusters,
            rarityTier: rarityTier,
            yearRange: yearRange
        )
    }

    // MARK: - Vector Alignment

    func testVectorAlignment_cosineSimilarity() {
        let scores = ObjectAxisScores(
            precision: 1.0, patina: 0.0, utility: 0.0, formality: 0.0,
            subculture: 0.0, ornament: 0.0, heritage: 0.0,
            technicality: 0.0, minimalism: 0.0
        )
        // Identical direction → high alignment
        let aligned = ObjectsRankingEngine.vectorAlignment(
            objectScores: scores,
            itemWeights: ["precision": 1.0]
        )
        XCTAssertGreaterThan(aligned, 0.8)

        // Opposite direction → low alignment
        let opposed = ObjectsRankingEngine.vectorAlignment(
            objectScores: scores,
            itemWeights: ["precision": -1.0]
        )
        XCTAssertLessThan(opposed, 0.2)
    }

    // MARK: - Rank Object Items

    func testRankObjectItems_highAlignmentFirst() {
        let scores = ObjectAxisScores(
            precision: 0.9, patina: 0.0, utility: 0.0, formality: 0.0,
            subculture: 0.0, ornament: 0.0, heritage: 0.0,
            technicality: 0.0, minimalism: 0.0
        )
        let vector = ObjectVector(weights: Dictionary(
            uniqueKeysWithValues: ObjectAxis.allCases.map { ($0.rawValue, scores.value(for: $0)) }
        ))

        let items = [
            makeItem(skuId: "low", objectAxisWeights: ["precision": -0.8]),
            makeItem(skuId: "high", objectAxisWeights: ["precision": 0.9, "technicality": 0.3]),
        ]

        let ranked = ObjectsRankingEngine.rankObjectItems(
            vector: vector, axisScores: scores, items: items, swipeCount: 14
        )

        XCTAssertEqual(ranked.first?.skuId, "high")
        XCTAssertEqual(ranked.last?.skuId, "low")
    }

    func testRankObjectItems_stabilityAwareRarity() {
        // Stable user with high precision → should favor archive rarity
        let scores = ObjectAxisScores(
            precision: 0.8, patina: 0.0, utility: 0.0, formality: 0.0,
            subculture: 0.0, ornament: 0.0, heritage: 0.0,
            technicality: 0.0, minimalism: 0.0
        )
        let vector = ObjectVector(weights: ["precision": 0.8])

        let archiveItem = makeItem(
            skuId: "archive",
            objectAxisWeights: ["precision": 0.5],
            rarityTier: .archive
        )
        let emergentItem = makeItem(
            skuId: "emergent",
            objectAxisWeights: ["precision": 0.5],
            rarityTier: .emergent
        )

        let ranked = ObjectsRankingEngine.rankObjectItems(
            vector: vector, axisScores: scores,
            items: [emergentItem, archiveItem], swipeCount: 20
        )

        // Stable user → archive rarity boost = 1.0, emergent = 0.3
        // With identical alignment, archive should rank higher
        XCTAssertEqual(ranked.first?.skuId, "archive")
    }

    func testRankObjectItems_clusterBoost() {
        // Scores that produce "precisionTool" cluster (precision + technicality dominant)
        let scores = ObjectAxisScores(
            precision: 0.8, patina: 0.0, utility: 0.0, formality: 0.0,
            subculture: 0.0, ornament: 0.0, heritage: 0.0,
            technicality: 0.7, minimalism: 0.0
        )
        let vector = ObjectVector(weights: Dictionary(
            uniqueKeysWithValues: ObjectAxis.allCases.map { ($0.rawValue, scores.value(for: $0)) }
        ))

        let cluster = DomainDiscovery.identifyObjectsClusterV2(objectScores: scores)
        XCTAssertEqual(cluster, "precisionTool")

        let boosted = makeItem(
            skuId: "boosted",
            objectAxisWeights: ["precision": 0.5, "technicality": 0.5],
            discoveryClusters: ["precisionTool"]
        )
        let unboosted = makeItem(
            skuId: "unboosted",
            objectAxisWeights: ["precision": 0.5, "technicality": 0.5],
            discoveryClusters: ["heritageCraft"]
        )

        let ranked = ObjectsRankingEngine.rankObjectItems(
            vector: vector, axisScores: scores,
            items: [unboosted, boosted], swipeCount: 14
        )

        // With same alignment, the item in the matching cluster should rank higher
        XCTAssertEqual(ranked.first?.skuId, "boosted")
    }

    func testRankCommerceItems_delegatesToObjectsEngine() {
        // Ensure RecommendationEngine.rankCommerceItems delegates to ObjectsRankingEngine
        // when domain is .objects
        let vector = TasteVector.zero
        let axisScores = AxisScores(
            minimalOrnate: 0.5, warmCool: 0.3, softStructured: 0.7,
            organicIndustrial: 0.2, lightDark: 0.0,
            neutralSaturated: -0.1, sparseLayered: 0.1
        )

        let items = [
            makeItem(skuId: "obj-1", objectAxisWeights: ["precision": 0.8]),
            makeItem(skuId: "obj-2", objectAxisWeights: ["patina": 0.7]),
        ]

        let ranked = RecommendationEngine.rankCommerceItems(
            vector: vector, axisScores: axisScores,
            items: items, domain: .objects, swipeCount: 10
        )

        // Should produce results (delegated to ObjectsRankingEngine)
        XCTAssertEqual(ranked.count, 2)
        // Verify ordering — softStructured maps to precision in approximate mapping,
        // so the precision-heavy item should rank higher
        XCTAssertEqual(ranked.first?.skuId, "obj-1")
    }
}
