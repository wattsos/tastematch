import XCTest
@testable import TasteMatch

final class ArtRarityRankingTests: XCTestCase {

    // MARK: - StabilityMode Detection

    func testStabilityMode_stable() {
        var vector = TasteVector.zero
        vector.weights["industrial"] = 0.9
        vector.weights["minimalist"] = 0.3
        let mode = ArtRankingEngine.detectStability(vector: vector, swipeCount: 14)
        XCTAssertEqual(mode, .stable)
    }

    func testStabilityMode_volatile_lowSwipes() {
        let vector = TasteVector.zero
        let mode = ArtRankingEngine.detectStability(vector: vector, swipeCount: 3)
        XCTAssertEqual(mode, .volatile)
    }

    func testStabilityMode_volatile_lowSeparation() {
        var vector = TasteVector.zero
        // All weights close to each other → low separation
        for key in vector.weights.keys {
            vector.weights[key] = 0.5
        }
        let mode = ArtRankingEngine.detectStability(vector: vector, swipeCount: 20)
        XCTAssertEqual(mode, .volatile)
    }

    func testStabilityMode_neutral() {
        var vector = TasteVector.zero
        vector.weights["industrial"] = 0.7
        vector.weights["minimalist"] = 0.5
        let mode = ArtRankingEngine.detectStability(vector: vector, swipeCount: 10)
        XCTAssertEqual(mode, .neutral)
    }

    // MARK: - Rarity Boost Matrix

    func testRarityBoost_allNineCombinations() {
        let expected: [(ArtRarityTier, ArtRankingEngine.StabilityMode, Double)] = [
            (.archive, .stable, 1.0),
            (.archive, .neutral, 0.7),
            (.archive, .volatile, 0.3),
            (.contemporary, .stable, 0.6),
            (.contemporary, .neutral, 1.0),
            (.contemporary, .volatile, 0.6),
            (.emergent, .stable, 0.3),
            (.emergent, .neutral, 0.7),
            (.emergent, .volatile, 1.0),
        ]

        for (tier, mode, value) in expected {
            let boost = ArtRankingEngine.rarityBoost(tier: tier, mode: mode)
            XCTAssertEqual(boost, value, accuracy: 0.001,
                "Rarity boost for \(tier)/\(mode) should be \(value)")
        }
    }

    // MARK: - Art Freshness

    func testArtFreshness_recentYear() {
        XCTAssertEqual(ArtRankingEngine.artFreshness(yearRange: "2020-2024"), 1.0)
        XCTAssertEqual(ArtRankingEngine.artFreshness(yearRange: "2022-2025"), 1.0)
    }

    func testArtFreshness_2000s() {
        XCTAssertEqual(ArtRankingEngine.artFreshness(yearRange: "2000-2015"), 0.7)
        XCTAssertEqual(ArtRankingEngine.artFreshness(yearRange: "2005-2019"), 0.7)
    }

    func testArtFreshness_1980s() {
        XCTAssertEqual(ArtRankingEngine.artFreshness(yearRange: "1980-1995"), 0.5)
    }

    func testArtFreshness_preMethods() {
        XCTAssertEqual(ArtRankingEngine.artFreshness(yearRange: "1960-1975"), 0.3)
    }

    func testArtFreshness_nilYearRange() {
        XCTAssertEqual(ArtRankingEngine.artFreshness(yearRange: nil), 0.5)
    }

    // MARK: - Ranking Determinism

    func testArtRanking_isDeterministic() {
        let vector = makeStableVector()
        let scores = AxisMapping.computeAxisScores(from: vector)
        let items = makeSampleArtItems()

        let result1 = ArtRankingEngine.rankArtItems(
            vector: vector, axisScores: scores, items: items, swipeCount: 14
        )
        let result2 = ArtRankingEngine.rankArtItems(
            vector: vector, axisScores: scores, items: items, swipeCount: 14
        )

        XCTAssertEqual(result1.map(\.skuId), result2.map(\.skuId),
            "Art ranking should be deterministic")
    }

    // MARK: - Stable Vector Prefers Archive

    func testStableVector_prefersArchiveOverEmergent() {
        let vector = makeStableVector()
        let scores = AxisMapping.computeAxisScores(from: vector)
        let items = makeSampleArtItems()

        let ranked = ArtRankingEngine.rankArtItems(
            vector: vector, axisScores: scores, items: items, swipeCount: 20
        )

        let archiveIndex = ranked.firstIndex(where: { $0.skuId == "test-art-archive" })
        let emergentIndex = ranked.firstIndex(where: { $0.skuId == "test-art-emergent" })

        if let ai = archiveIndex, let ei = emergentIndex {
            XCTAssertLessThan(ai, ei,
                "Stable vector should rank archive higher than emergent")
        }
    }

    // MARK: - Volatile Vector Prefers Emergent

    func testVolatileVector_prefersEmergentOverArchive() {
        let vector = makeVolatileVector()
        let scores = AxisMapping.computeAxisScores(from: vector)
        let items = makeSampleArtItems()

        let ranked = ArtRankingEngine.rankArtItems(
            vector: vector, axisScores: scores, items: items, swipeCount: 3
        )

        let archiveIndex = ranked.firstIndex(where: { $0.skuId == "test-art-archive" })
        let emergentIndex = ranked.firstIndex(where: { $0.skuId == "test-art-emergent" })

        if let ai = archiveIndex, let ei = emergentIndex {
            XCTAssertLessThan(ei, ai,
                "Volatile vector should rank emergent higher than archive")
        }
    }

    // MARK: - Helpers

    private func makeStableVector() -> TasteVector {
        var vector = TasteVector.zero
        vector.weights["industrial"] = 0.9
        vector.weights["minimalist"] = 0.3
        vector.weights["rustic"] = 0.1
        return vector
    }

    private func makeVolatileVector() -> TasteVector {
        var vector = TasteVector.zero
        for key in vector.weights.keys {
            vector.weights[key] = 0.1
        }
        return vector
    }

    private func makeSampleArtItems() -> [CatalogItem] {
        let sharedWeights: [String: Double] = [
            "minimalOrnate": -0.3,
            "warmCool": -0.2,
            "softStructured": 0.5,
            "organicIndustrial": 0.7,
            "lightDark": 0.6,
            "neutralSaturated": -0.3,
            "sparseLayered": 0.2
        ]

        return [
            CatalogItem(
                skuId: "test-art-archive",
                title: "Archive Piece",
                merchant: "Test Gallery",
                price: 50000,
                imageURL: "https://example.com/archive.jpg",
                productURL: "https://example.com/archive",
                tags: [.industrial],
                category: .painting,
                commerceAxisWeights: sharedWeights,
                discoveryClusters: ["brutalGesture"],
                rarityTier: .archive,
                yearRange: "1960-1975"
            ),
            CatalogItem(
                skuId: "test-art-emergent",
                title: "Emergent Piece",
                merchant: "Test Gallery",
                price: 5000,
                imageURL: "https://example.com/emergent.jpg",
                productURL: "https://example.com/emergent",
                tags: [.industrial],
                category: .painting,
                commerceAxisWeights: sharedWeights,
                discoveryClusters: ["brutalGesture"],
                rarityTier: .emergent,
                yearRange: "2022-2024"
            ),
            CatalogItem(
                skuId: "test-art-contemporary",
                title: "Contemporary Piece",
                merchant: "Test Gallery",
                price: 20000,
                imageURL: "https://example.com/contemporary.jpg",
                productURL: "https://example.com/contemporary",
                tags: [.industrial],
                category: .sculpture,
                commerceAxisWeights: sharedWeights,
                discoveryClusters: ["brutalGesture"],
                rarityTier: .contemporary,
                yearRange: "2005-2015"
            ),
        ]
    }
}
