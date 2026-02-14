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

    func testDiversity_maxTwoConsecutiveSameType() {
        var items: [DiscoveryItem] = (0..<20).map { i in
            makeItem(id: "d-\(i)", type: .designer, rarity: Double(20 - i) / 20)
        }
        items.append(makeItem(id: "m-0", type: .material, rarity: 0.5))

        let diversified = DiscoveryEngine.diversify(items, maxConsecutiveType: 2, maxConsecutiveCluster: 100)

        for i in 2..<diversified.count {
            let window = (i-2)...i
            let types = window.map { diversified[$0].type }
            let allSame = types.allSatisfy { $0 == types[0] }
            if allSame {
                let remaining = diversified[(i+1)...].contains(where: { $0.type != types[0] })
                if remaining {
                    XCTFail("Found 3 consecutive same type at index \(i-2)")
                }
            }
        }
    }

    func testDiversity_maxTwoConsecutiveSameCluster() {
        var items: [DiscoveryItem] = (0..<20).map { i in
            makeItem(id: "c-\(i)", type: .designer, clusters: ["industrialDark"], rarity: Double(20 - i) / 20)
        }
        items.append(makeItem(id: "w-0", type: .designer, clusters: ["warmOrganic"], rarity: 0.5))

        let diversified = DiscoveryEngine.diversify(items, maxConsecutiveType: 100, maxConsecutiveCluster: 2)

        for i in 2..<diversified.count {
            let window = (i-2)...i
            let clusters = window.map { diversified[$0].primaryCluster }
            let allSame = clusters.allSatisfy { $0 == clusters[0] }
            if allSame {
                let remaining = diversified[(i+1)...].contains(where: { $0.primaryCluster != clusters[0] })
                if remaining {
                    XCTFail("Found 3 consecutive same cluster at index \(i-2)")
                }
            }
        }
    }

    func testDiversity_preservesAllItems() {
        let items = makeTestItems()
        let diversified = DiscoveryEngine.diversify(items, maxConsecutiveType: 2, maxConsecutiveCluster: 2)

        XCTAssertEqual(Set(items.map(\.id)), Set(diversified.map(\.id)), "Diversification must not drop items")
    }

    // MARK: - Axis Weight Ranking Influence

    func testAxisWeightInfluence_industrialScoresPreferIndustrialItems() {
        let industrial = makeItem(
            id: "ind", type: .designer, clusters: ["industrialDark"],
            weights: ["organicIndustrial": 0.9, "lightDark": 0.8, "softStructured": 0.5,
                      "warmCool": -0.4, "minimalOrnate": -0.2, "neutralSaturated": -0.4, "sparseLayered": 0.1],
            rarity: 0.5
        )

        let minimal = makeItem(
            id: "min", type: .designer, clusters: ["minimalNeutral"],
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
            id: "ind", type: .designer, clusters: ["industrialDark"],
            weights: ["organicIndustrial": 0.9, "lightDark": 0.8, "softStructured": 0.5,
                      "warmCool": -0.4, "minimalOrnate": -0.2, "neutralSaturated": -0.4, "sparseLayered": 0.1],
            rarity: 0.5
        )

        let minimal = makeItem(
            id: "min", type: .designer, clusters: ["minimalNeutral"],
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

    // MARK: - User Affinity

    func testUserAffinity_dismissedDownranked() {
        let item = makeItem(id: "x", type: .designer, rarity: 0.9)
        let signals = DiscoverySignals(profileId: UUID(), dismissedIds: ["x"])
        let affinity = DiscoveryEngine.userAffinity(item: item, signals: signals)
        XCTAssertEqual(affinity, -1.0, "Dismissed items should have -1 affinity")
    }

    func testUserAffinity_savedBoosted() {
        let item = makeItem(id: "y", type: .designer, rarity: 0.5)
        let signals = DiscoverySignals(profileId: UUID(), savedIds: ["y"])
        let affinity = DiscoveryEngine.userAffinity(item: item, signals: signals)
        XCTAssertEqual(affinity, 1.0, "Saved items should have 1.0 affinity")
    }

    func testUserAffinity_viewedModerate() {
        let item = makeItem(id: "z", type: .designer, rarity: 0.5)
        let signals = DiscoverySignals(profileId: UUID(), viewedIds: ["z"])
        let affinity = DiscoveryEngine.userAffinity(item: item, signals: signals)
        XCTAssertEqual(affinity, 0.3, "Viewed items should have 0.3 affinity")
    }

    // MARK: - Freshness

    func testFreshness_recentItemScoresHigh() {
        let item = makeItem(id: "f1", type: .designer, rarity: 0.5, createdAt: Date().addingTimeInterval(-86400))
        let score = DiscoveryEngine.freshness(item: item)
        XCTAssertEqual(score, 1.0, "Item created 1 day ago should score 1.0")
    }

    func testFreshness_oldItemScoresLow() {
        let item = makeItem(id: "f2", type: .designer, rarity: 0.5, createdAt: Date().addingTimeInterval(-86400 * 60))
        let score = DiscoveryEngine.freshness(item: item)
        XCTAssertEqual(score, 0.3, "Item created 60 days ago should score 0.3")
    }

    func testFreshness_noDateReturnsDefault() {
        let item = makeItem(id: "f3", type: .designer, rarity: 0.5)
        let score = DiscoveryEngine.freshness(item: item)
        XCTAssertEqual(score, 0.5, "Item without createdAt should score 0.5")
    }

    // MARK: - Daily Radar

    func testDailyRadar_stableWithinSameDay() {
        let items = makeTestItems()
        let scores = makeIndustrialScores()
        let profileId = UUID()
        let vector = TasteVector(weights: ["scandinavian": 0.6, "minimalist": 0.4])

        let result1 = DiscoveryEngine.dailyRadar(
            items: items, axisScores: scores, profileId: profileId, vector: vector, dayIndex: 100
        )
        let result2 = DiscoveryEngine.dailyRadar(
            items: items, axisScores: scores, profileId: profileId, vector: vector, dayIndex: 100
        )

        XCTAssertEqual(result1.map(\.id), result2.map(\.id), "Same day should produce identical ordering")
    }

    func testDailyRadar_changesAcrossDays() {
        let items = makeTestItems()
        let scores = makeIndustrialScores()
        let profileId = UUID()
        let vector = TasteVector(weights: ["scandinavian": 0.6, "minimalist": 0.4])

        let baseline = DiscoveryEngine.dailyRadar(
            items: items, axisScores: scores, profileId: profileId, vector: vector, dayIndex: 100
        ).map(\.id)

        // Check across 10 different days — at least one must differ
        let anyDifferent = (101...110).contains { day in
            let result = DiscoveryEngine.dailyRadar(
                items: items, axisScores: scores, profileId: profileId, vector: vector, dayIndex: day
            ).map(\.id)
            return result != baseline
        }

        XCTAssertTrue(anyDifferent, "Radar ordering should vary across days")
    }

    func testDailyRadar_respectsLimit() {
        let items = makeTestItems()
        let scores = makeIndustrialScores()
        let profileId = UUID()
        let vector = TasteVector(weights: ["scandinavian": 0.6])

        let result = DiscoveryEngine.dailyRadar(
            items: items, axisScores: scores, profileId: profileId, vector: vector, limit: 3, dayIndex: 50
        )

        XCTAssertEqual(result.count, 3)
    }

    func testDailyRadar_emptyInputReturnsEmpty() {
        let scores = makeIndustrialScores()
        let result = DiscoveryEngine.dailyRadar(
            items: [], axisScores: scores, profileId: UUID(), vector: .zero, dayIndex: 1
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testBuildDayKey_differentDaysProduceDifferentKeys() {
        let profileId = UUID()
        let vector = TasteVector(weights: ["scandinavian": 0.5])

        let key1 = DiscoveryEngine.buildDayKey(dayIndex: 100, profileId: profileId, vector: vector)
        let key2 = DiscoveryEngine.buildDayKey(dayIndex: 101, profileId: profileId, vector: vector)

        XCTAssertNotEqual(key1, key2)
    }

    func testBuildDayKey_sameDaySameKey() {
        let profileId = UUID()
        let vector = TasteVector(weights: ["scandinavian": 0.5])

        let key1 = DiscoveryEngine.buildDayKey(dayIndex: 42, profileId: profileId, vector: vector)
        let key2 = DiscoveryEngine.buildDayKey(dayIndex: 42, profileId: profileId, vector: vector)

        XCTAssertEqual(key1, key2)
    }

    // MARK: - Backward-Compatible Decoding

    func testBackwardCompatibleDecoding_legacyJSON() {
        let json = """
        {
            "id": "disc-001",
            "title": "Test Item",
            "type": "region",
            "region": "Tokyo",
            "body": "Test body",
            "cluster": "warmOrganic",
            "axisWeights": {"warmCool": 0.5},
            "rarityScore": 0.7
        }
        """
        let data = json.data(using: .utf8)!
        let item = try! JSONDecoder().decode(DiscoveryItem.self, from: data)

        XCTAssertEqual(item.type, .place, "Legacy 'region' type should decode as .place")
        XCTAssertEqual(item.regions, ["Tokyo"], "Legacy single region should wrap in array")
        XCTAssertEqual(item.clusters, ["warmOrganic"], "Legacy single cluster should wrap in array")
        XCTAssertEqual(item.rarity, 0.7, "Legacy rarityScore should map to rarity")
        XCTAssertEqual(item.sourceTier, .curated, "Missing sourceTier should default to .curated")
    }

    // MARK: - Helpers

    private func makeTestItems() -> [DiscoveryItem] {
        let types: [DiscoveryType] = [.designer, .studio, .object, .material, .movement, .place, .reference]
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
                regions: ["Test"],
                body: "Test body \(i)",
                clusters: [clusters[i % clusters.count]],
                axisWeights: weights,
                rarity: Double(i) / 21
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
                regions: ["Test"],
                body: "Test",
                clusters: ["industrialDark"],
                axisWeights: [:],
                rarity: 0.5
            )
        }
    }

    private func makeItem(
        id: String,
        type: DiscoveryType,
        clusters: [String] = ["industrialDark"],
        weights: [String: Double] = [:],
        rarity: Double = 0.5,
        createdAt: Date? = nil
    ) -> DiscoveryItem {
        DiscoveryItem(
            id: id, title: id, type: type, regions: ["Test"],
            body: "Test", clusters: clusters,
            axisWeights: weights, rarity: rarity,
            createdAt: createdAt
        )
    }

    private func makeIndustrialScores() -> AxisScores {
        AxisScores(
            minimalOrnate: -0.2, warmCool: -0.5, softStructured: 0.8,
            organicIndustrial: 0.9, lightDark: 0.7, neutralSaturated: -0.3, sparseLayered: 0.3
        )
    }
}
