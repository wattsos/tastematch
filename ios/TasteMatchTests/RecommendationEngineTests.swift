import XCTest
@testable import TasteMatch

final class RecommendationEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeProfile(
        primaryKey: String = "midCenturyModern",
        primaryLabel: String = "Mid-Century Modern",
        primaryConfidence: Double = 0.85,
        secondaryKey: String? = nil,
        secondaryLabel: String? = nil,
        secondaryConfidence: Double = 0.5
    ) -> TasteProfile {
        var tags = [TasteTag(key: primaryKey, label: primaryLabel, confidence: primaryConfidence)]
        if let secKey = secondaryKey, let secLabel = secondaryLabel {
            tags.append(TasteTag(key: secKey, label: secLabel, confidence: secondaryConfidence))
        }
        return TasteProfile(
            tags: tags,
            story: "Test story",
            signals: [Signal(key: "palette_temperature", value: "warm")]
        )
    }

    // MARK: - Basic scoring

    func testRecommendations_returnRequestedLimit() {
        let profile = makeProfile()
        let recs = RecommendationEngine.recommend(
            profile: profile,
            catalog: MockCatalog.items,
            context: .livingRoom,
            goal: .refresh,
            limit: 6
        )
        XCTAssertEqual(recs.count, 6)
    }

    func testRecommendations_limitLargerThanCatalog_returnsAll() {
        let profile = makeProfile()
        let recs = RecommendationEngine.recommend(
            profile: profile,
            catalog: MockCatalog.items,
            context: .livingRoom,
            goal: .refresh,
            limit: 100
        )
        XCTAssertEqual(recs.count, MockCatalog.items.count)
    }

    // MARK: - Determinism

    func testSameInputs_produceSameOrder() {
        let profile = makeProfile()
        let a = RecommendationEngine.recommend(
            profile: profile, catalog: MockCatalog.items,
            context: .livingRoom, goal: .refresh, limit: 6
        )
        let b = RecommendationEngine.recommend(
            profile: profile, catalog: MockCatalog.items,
            context: .livingRoom, goal: .refresh, limit: 6
        )

        XCTAssertEqual(a.map(\.title), b.map(\.title))
        XCTAssertEqual(a.map(\.attributionConfidence), b.map(\.attributionConfidence))
    }

    // MARK: - Primary tag items ranked first

    func testPrimaryTagItems_rankedAboveUnmatched() {
        let profile = makeProfile(primaryKey: "industrial", primaryLabel: "Industrial")
        let recs = RecommendationEngine.recommend(
            profile: profile, catalog: MockCatalog.items,
            context: .office, goal: .refresh, limit: 6
        )

        // All top results should have non-zero attribution (industrial items score > 0)
        for rec in recs {
            XCTAssertGreaterThan(rec.attributionConfidence, 0.0,
                                 "\(rec.title) should have positive confidence")
        }
    }

    // MARK: - Attribution confidence bounds

    func testAttributionConfidence_isBetween0And1() {
        let profile = makeProfile(
            primaryKey: "midCenturyModern", primaryLabel: "Mid-Century Modern",
            secondaryKey: "artDeco", secondaryLabel: "Art Deco"
        )
        let recs = RecommendationEngine.recommend(
            profile: profile, catalog: MockCatalog.items,
            context: .livingRoom, goal: .overhaul, limit: 30
        )

        for rec in recs {
            XCTAssertGreaterThanOrEqual(rec.attributionConfidence, 0.0)
            XCTAssertLessThanOrEqual(rec.attributionConfidence, 1.0)
        }
    }

    // MARK: - Template rotation

    func testReasons_varyAcrossRecommendations() {
        let profile = makeProfile()
        let recs = RecommendationEngine.recommend(
            profile: profile, catalog: MockCatalog.items,
            context: .livingRoom, goal: .refresh, limit: 6
        )

        let reasons = Set(recs.map(\.reason))
        // With 3 templates and 6 items, we should have at least 2 distinct reasons
        XCTAssertGreaterThan(reasons.count, 1,
                             "Recommendations should have varied reason text")
    }

    // MARK: - Subtitle format

    func testSubtitle_containsMerchantAndPrice() {
        let profile = makeProfile()
        let recs = RecommendationEngine.recommend(
            profile: profile, catalog: MockCatalog.items,
            context: .livingRoom, goal: .refresh, limit: 1
        )

        let subtitle = recs.first!.subtitle
        // Should match "Merchant — $NNN" pattern
        XCTAssertTrue(subtitle.contains("—"), "Subtitle should contain em dash separator")
        XCTAssertTrue(subtitle.contains("$"), "Subtitle should contain price")
    }

    // MARK: - Goal affects ordering

    func testDifferentGoals_canChangeAttributionConfidence() {
        let profile = makeProfile()
        let refresh = RecommendationEngine.recommend(
            profile: profile, catalog: MockCatalog.items,
            context: .livingRoom, goal: .refresh, limit: 1
        )
        let overhaul = RecommendationEngine.recommend(
            profile: profile, catalog: MockCatalog.items,
            context: .livingRoom, goal: .overhaul, limit: 1
        )

        // Same first item, but overhaul multiplier (1.1) should give higher confidence
        XCTAssertGreaterThanOrEqual(overhaul.first!.attributionConfidence,
                                    refresh.first!.attributionConfidence)
    }

    // MARK: - Empty catalog

    func testEmptyCatalog_returnsEmpty() {
        let profile = makeProfile()
        let recs = RecommendationEngine.recommend(
            profile: profile, catalog: [],
            context: .livingRoom, goal: .refresh, limit: 6
        )
        XCTAssertTrue(recs.isEmpty)
    }
}
