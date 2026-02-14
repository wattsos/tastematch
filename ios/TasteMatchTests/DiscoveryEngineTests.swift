import XCTest
@testable import TasteMatch

final class DiscoveryEngineTests: XCTestCase {

    // MARK: - Deterministic Ranking

    func testRanking_isDeterministic() {
        let items = makeTestItems()
        let scores = makeIndustrialScores()

        let ranked1 = DiscoveryEngine.rank(items: items, axisScores: scores)
        let ranked2 = DiscoveryEngine.rank(items: items, axisScores: scores)

        XCTAssertEqual(ranked1.map(\.id), ranked2.map(\.id), "Same inputs must produce same ranking")
    }

    func testRanking_isDeterministic_acrossShuffledInput() {
        let items = makeTestItems()
        let reversed = Array(items.reversed())
        let scores = makeIndustrialScores()

        let ranked1 = DiscoveryEngine.rank(items: items, axisScores: scores)
        let ranked2 = DiscoveryEngine.rank(items: reversed, axisScores: scores)

        XCTAssertEqual(ranked1.map(\.id), ranked2.map(\.id), "Input order should not affect output")
    }

    // MARK: - Stable Pagination

    func testPagination_isStable() {
        let items = makeTestItems()
        let scores = makeIndustrialScores()
        let ranked = DiscoveryEngine.rank(items: items, axisScores: scores)

        let page1 = DiscoveryEngine.page(ranked, offset: 0, limit: 5)
        let page2 = DiscoveryEngine.page(ranked, offset: 5, limit: 5)

        let page1Ids = Set(page1.items.map(\.id))
        let page2Ids = Set(page2.items.map(\.id))
        XCTAssertTrue(page1Ids.isDisjoint(with: page2Ids), "Pages must not overlap")

        let page1Again = DiscoveryEngine.page(ranked, offset: 0, limit: 5)
        XCTAssertEqual(page1.items.map(\.id), page1Again.items.map(\.id), "Re-paginating must give same results")
    }

    func testPagination_hasMore() {
        let items = makeNumberedItems(count: 25)

        let page1 = DiscoveryEngine.page(items, offset: 0, limit: 20)
        XCTAssertTrue(page1.hasMore)
        XCTAssertEqual(page1.items.count, 20)

        let page2 = DiscoveryEngine.page(items, offset: 20, limit: 20)
        XCTAssertFalse(page2.hasMore)
        XCTAssertEqual(page2.items.count, 5)
    }

    func testPagination_coversAllItems() {
        let items = makeNumberedItems(count: 45)
        var allLoaded: [DiscoveryItem] = []
        var offset = 0

        while true {
            let result = DiscoveryEngine.page(items, offset: offset, limit: 20)
            allLoaded.append(contentsOf: result.items)
            offset += result.items.count
            if !result.hasMore { break }
        }

        XCTAssertEqual(allLoaded.count, 45, "All items should be loaded across pages")
        XCTAssertEqual(Set(allLoaded.map(\.id)).count, 45, "No duplicates across pages")
    }

    // MARK: - Type Diversity Enforcement

    func testDiversity_noFiveConsecutiveSameType() {
        // Create 20 designers followed by 1 material
        var items: [DiscoveryItem] = (0..<20).map { i in
            makeItem(id: "d-\(i)", type: .designer, rarity: Double(20 - i) / 20)
        }
        items.append(makeItem(id: "m-0", type: .material, rarity: 0.5))

        let diversified = DiscoveryEngine.diversify(items, maxConsecutive: 4)

        for i in 4..<diversified.count {
            let window = (i-4)...i
            let types = window.map { diversified[$0].type }
            let allDesigner = types.allSatisfy { $0 == .designer }
            // Only fail if there's a non-designer available that could have been placed
            if allDesigner && diversified.contains(where: { $0.type != .designer }) {
                // Check if any non-designer items remain after position i-4
                let remainingNonDesigner = diversified[i...].contains(where: { $0.type != .designer })
                if remainingNonDesigner {
                    XCTFail("Found 5 consecutive designers at index \(i-4) despite diversity enforcement")
                }
            }
        }
    }

    func testDiversity_preservesAllItems() {
        let items = makeTestItems()
        let diversified = DiscoveryEngine.diversify(items, maxConsecutive: 4)

        XCTAssertEqual(Set(items.map(\.id)), Set(diversified.map(\.id)), "Diversification must not drop items")
    }

    // MARK: - Axis Weight Ranking Influence

    func testAxisWeightInfluence_industrialScoresPreferIndustrialItems() {
        let industrial = makeItem(
            id: "ind", type: .designer, cluster: "industrialDark",
            weights: ["organicIndustrial": 0.9, "lightDark": 0.8, "softStructured": 0.5,
                      "warmCool": -0.4, "minimalOrnate": -0.2, "neutralSaturated": -0.4, "sparseLayered": 0.1],
            rarity: 0.5
        )

        let minimal = makeItem(
            id: "min", type: .designer, cluster: "minimalNeutral",
            weights: ["minimalOrnate": -0.8, "neutralSaturated": -0.6, "sparseLayered": -0.6,
                      "lightDark": -0.5, "warmCool": -0.2, "softStructured": 0.2, "organicIndustrial": 0.0],
            rarity: 0.5
        )

        let scores = makeIndustrialScores()
        let ranked = DiscoveryEngine.rank(items: [minimal, industrial], axisScores: scores)

        XCTAssertEqual(ranked.first?.id, "ind", "Industrial item should rank higher with industrial axis scores")
    }

    func testAxisWeightInfluence_minimalScoresPreferMinimalItems() {
        let industrial = makeItem(
            id: "ind", type: .designer, cluster: "industrialDark",
            weights: ["organicIndustrial": 0.9, "lightDark": 0.8, "softStructured": 0.5,
                      "warmCool": -0.4, "minimalOrnate": -0.2, "neutralSaturated": -0.4, "sparseLayered": 0.1],
            rarity: 0.5
        )

        let minimal = makeItem(
            id: "min", type: .designer, cluster: "minimalNeutral",
            weights: ["minimalOrnate": -0.8, "neutralSaturated": -0.6, "sparseLayered": -0.6,
                      "lightDark": -0.5, "warmCool": -0.2, "softStructured": 0.2, "organicIndustrial": 0.0],
            rarity: 0.5
        )

        let scores = AxisScores(
            minimalOrnate: -0.9, warmCool: -0.2, softStructured: 0.3,
            organicIndustrial: 0.0, lightDark: -0.5, neutralSaturated: -0.6, sparseLayered: -0.8
        )
        let ranked = DiscoveryEngine.rank(items: [industrial, minimal], axisScores: scores)

        XCTAssertEqual(ranked.first?.id, "min", "Minimal item should rank higher with minimal axis scores")
    }

    // MARK: - Vector Alignment

    func testVectorAlignment_identicalWeightsScoreHigh() {
        let scores = AxisScores(
            minimalOrnate: -0.5, warmCool: -0.3, softStructured: 0.7,
            organicIndustrial: 0.9, lightDark: 0.6, neutralSaturated: -0.2, sparseLayered: 0.1
        )
        let weights: [String: Double] = [
            "minimalOrnate": -0.5, "warmCool": -0.3, "softStructured": 0.7,
            "organicIndustrial": 0.9, "lightDark": 0.6, "neutralSaturated": -0.2, "sparseLayered": 0.1
        ]

        let alignment = DiscoveryEngine.vectorAlignment(axisScores: scores, itemWeights: weights)
        XCTAssertGreaterThan(alignment, 0.9, "Identical weights should produce high alignment")
    }

    func testVectorAlignment_oppositeWeightsScoreLow() {
        let scores = AxisScores(
            minimalOrnate: 0.8, warmCool: 0.8, softStructured: -0.6,
            organicIndustrial: -0.7, lightDark: 0.0, neutralSaturated: 0.6, sparseLayered: 0.9
        )
        let weights: [String: Double] = [
            "minimalOrnate": -0.8, "warmCool": -0.8, "softStructured": 0.6,
            "organicIndustrial": 0.7, "lightDark": 0.0, "neutralSaturated": -0.6, "sparseLayered": -0.9
        ]

        let alignment = DiscoveryEngine.vectorAlignment(axisScores: scores, itemWeights: weights)
        XCTAssertLessThan(alignment, 0.1, "Opposite weights should produce low alignment")
    }

    // MARK: - Cluster Identification

    func testIdentifyCluster_industrialScores() {
        let scores = makeIndustrialScores()
        let cluster = DiscoveryEngine.identifyCluster(scores)
        XCTAssertEqual(cluster, "industrialDark")
    }

    func testIdentifyCluster_warmScores() {
        let scores = AxisScores(
            minimalOrnate: 0.2, warmCool: 0.8, softStructured: -0.4,
            organicIndustrial: -0.7, lightDark: 0.1, neutralSaturated: 0.1, sparseLayered: 0.3
        )
        let cluster = DiscoveryEngine.identifyCluster(scores)
        XCTAssertEqual(cluster, "warmOrganic")
    }

    // MARK: - Helpers

    private func makeTestItems() -> [DiscoveryItem] {
        let types: [DiscoveryType] = [.designer, .studio, .object, .material, .movement, .region, .reference]
        let clusters = ["industrialDark", "warmOrganic", "minimalNeutral", "layeredSaturated"]
        var items: [DiscoveryItem] = []
        for i in 0..<21 {
            let weights: [String: Double] = [
                "organicIndustrial": Double(i % 3) * 0.3 - 0.3,
                "lightDark": Double(i % 4) * 0.2 - 0.2,
                "warmCool": Double(i % 2) * 0.4 - 0.2,
                "minimalOrnate": Double(i % 5) * 0.2 - 0.4,
                "softStructured": 0.1,
                "neutralSaturated": -0.1,
                "sparseLayered": 0.0
            ]
            let item = DiscoveryItem(
                id: "test-\(String(format: "%03d", i))",
                title: "Item \(i)",
                type: types[i % types.count],
                region: "Test",
                body: "Test body \(i)",
                cluster: clusters[i % clusters.count],
                axisWeights: weights,
                rarityScore: Double(i) / 21
            )
            items.append(item)
        }
        return items
    }

    private func makeNumberedItems(count: Int) -> [DiscoveryItem] {
        (0..<count).map { i in
            DiscoveryItem(
                id: "n-\(String(format: "%03d", i))",
                title: "Item \(i)",
                type: .designer,
                region: "Test",
                body: "Test",
                cluster: "industrialDark",
                axisWeights: [:],
                rarityScore: 0.5
            )
        }
    }

    private func makeItem(
        id: String,
        type: DiscoveryType,
        cluster: String = "industrialDark",
        weights: [String: Double] = [:],
        rarity: Double = 0.5
    ) -> DiscoveryItem {
        DiscoveryItem(
            id: id, title: id, type: type, region: "Test",
            body: "Test", cluster: cluster,
            axisWeights: weights, rarityScore: rarity
        )
    }

    private func makeIndustrialScores() -> AxisScores {
        AxisScores(
            minimalOrnate: -0.2, warmCool: -0.5, softStructured: 0.8,
            organicIndustrial: 0.9, lightDark: 0.7, neutralSaturated: -0.3, sparseLayered: 0.3
        )
    }
}
