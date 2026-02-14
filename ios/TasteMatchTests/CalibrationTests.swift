import XCTest
@testable import TasteMatch

final class CalibrationTests: XCTestCase {

    // MARK: - TasteVector Swipe Tests

    func testApplySwipe_rightIncreasesWeight() {
        var vector = TasteVector.zero
        vector.applySwipe(tag: "scandinavian", direction: .right)
        XCTAssertEqual(vector.weights["scandinavian"], 1.0)
    }

    func testApplySwipe_leftDecreasesWeight() {
        var vector = TasteVector.zero
        vector.applySwipe(tag: "industrial", direction: .left)
        XCTAssertEqual(vector.weights["industrial"], -0.8)
    }

    func testApplySwipe_superLikeStrongerThanRight() {
        var vectorRight = TasteVector.zero
        vectorRight.applySwipe(tag: "japandi", direction: .right)

        var vectorUp = TasteVector.zero
        vectorUp.applySwipe(tag: "japandi", direction: .up)

        XCTAssertEqual(vectorRight.weights["japandi"], 1.0)
        XCTAssertEqual(vectorUp.weights["japandi"], 2.0)
        XCTAssertGreaterThan(vectorUp.weights["japandi"]!, vectorRight.weights["japandi"]!)
    }

    // MARK: - Blend Tests

    func testBlend_wantMoreFavorsSwipe() {
        var image = TasteVector.zero
        image.weights["scandinavian"] = 1.0

        var swipe = TasteVector.zero
        swipe.weights["scandinavian"] = 0.0
        swipe.weights["industrial"] = 1.0

        let blended = TasteVector.blend(image: image, swipe: swipe, mode: .wantMore)

        // wantMore: image x 0.35 + swipe x 0.65
        XCTAssertEqual(blended.weights["scandinavian"]!, 0.35, accuracy: 0.001)
        XCTAssertEqual(blended.weights["industrial"]!, 0.65, accuracy: 0.001)
    }

    func testBlend_haveLikeFavorsImage() {
        var image = TasteVector.zero
        image.weights["scandinavian"] = 1.0

        var swipe = TasteVector.zero
        swipe.weights["scandinavian"] = 0.0
        swipe.weights["industrial"] = 1.0

        let blended = TasteVector.blend(image: image, swipe: swipe, mode: .haveLike)

        // haveLike: image x 0.75 + swipe x 0.25
        XCTAssertEqual(blended.weights["scandinavian"]!, 0.75, accuracy: 0.001)
        XCTAssertEqual(blended.weights["industrial"]!, 0.25, accuracy: 0.001)
    }

    // MARK: - Normalization

    func testNormalized_clampsToRange() {
        var vector = TasteVector.zero
        vector.weights["scandinavian"] = 3.0
        vector.weights["industrial"] = -2.5

        let normalized = vector.normalized()
        XCTAssertEqual(normalized.weights["scandinavian"], 1.0)
        XCTAssertEqual(normalized.weights["industrial"], -1.0)
    }

    // MARK: - Influences & Avoids

    func testInfluences_returnsHighWeightTags() {
        var vector = TasteVector.zero
        vector.weights["scandinavian"] = 0.8
        vector.weights["japandi"] = 0.5
        vector.weights["industrial"] = 0.1

        let influences = vector.influences
        XCTAssertTrue(influences.contains("scandinavian"))
        XCTAssertTrue(influences.contains("japandi"))
        XCTAssertFalse(influences.contains("industrial"))
        XCTAssertEqual(influences.first, "scandinavian")
    }

    func testAvoids_returnsNegativeWeightTags() {
        var vector = TasteVector.zero
        vector.weights["industrial"] = -0.4
        vector.weights["scandinavian"] = 0.5
        vector.weights["bohemian"] = -0.1

        let avoids = vector.avoids
        XCTAssertTrue(avoids.contains("industrial"))
        XCTAssertFalse(avoids.contains("bohemian"))
        XCTAssertFalse(avoids.contains("scandinavian"))
    }

    // MARK: - Confidence

    func testConfidence_reflectsSwipeCount() {
        var vector = TasteVector.zero
        XCTAssertEqual(vector.confidence, 0.0)

        vector.applySwipe(tag: "scandinavian", direction: .right)
        vector.applySwipe(tag: "industrial", direction: .left)
        XCTAssertGreaterThan(vector.confidence, 0.0)
    }

    // MARK: - Confidence Gating

    func testConfidenceLevel_strongRequiresSwipesAndSeparation() {
        // Build a vector with clear top-tag separation and enough swipes
        var vector = TasteVector.zero
        // Swipe right on scandinavian many times to build strong separation
        for _ in 0..<8 {
            vector.applySwipe(tag: "scandinavian", direction: .right)
        }
        for _ in 0..<6 {
            vector.applySwipe(tag: "industrial", direction: .left)
        }
        // 14 swipes total, scandinavian at 8.0 (clamps to 1.0), industrial at -4.8 (clamps to -1.0)
        // After normalization: top1=1.0, top2=0.0 → separation=1.0 >= 0.15
        XCTAssertEqual(vector.confidenceLevel(swipeCount: 14), "Strong")
    }

    func testConfidenceLevel_developingWithFewerSwipes() {
        var vector = TasteVector.zero
        for _ in 0..<7 {
            vector.applySwipe(tag: "scandinavian", direction: .right)
        }
        // 7 swipes, meets swipeCount >= 7 but not >= 14
        XCTAssertEqual(vector.confidenceLevel(swipeCount: 7), "Developing")
    }

    func testConfidenceLevel_lowWithMinimalSignal() {
        let vector = TasteVector.zero
        XCTAssertEqual(vector.confidenceLevel(swipeCount: 0), "Low")
    }

    func testConfidenceLevel_strongNeedsSeparation() {
        // 14+ swipes but all tags equal → no separation → not Strong
        var vector = TasteVector.zero
        // Swipe right on every tag once, then swipe right again on 4 more
        for tag in TasteEngine.CanonicalTag.allCases {
            vector.applySwipe(tag: String(describing: tag), direction: .right)
        }
        // All at 1.0, separation = 0 after normalization
        // 10 swipes. Add 4 more left swipes on different tags to reach 14.
        vector.applySwipe(tag: "bohemian", direction: .left)
        vector.applySwipe(tag: "rustic", direction: .left)
        vector.applySwipe(tag: "artDeco", direction: .left)
        vector.applySwipe(tag: "coastal", direction: .left)
        // Now 14 swipes. bohemian/rustic/artDeco/coastal at 0.2 (1.0-0.8), rest at 1.0
        // After normalization: top1=1.0, top2=1.0 → separation=0 < 0.15
        XCTAssertEqual(vector.confidenceLevel(swipeCount: 14), "Developing")
    }

    // MARK: - CalibrationStore

    func testCalibrationStore_roundTrip() {
        let profileId = UUID()
        var vector = TasteVector.zero
        vector.applySwipe(tag: "scandinavian", direction: .right)

        let record = CalibrationRecord(
            tasteProfileId: profileId,
            vector: vector,
            swipeCount: 1,
            createdAt: Date()
        )
        CalibrationStore.save(record)

        let loaded = CalibrationStore.load(for: profileId)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.tasteProfileId, profileId)
        XCTAssertEqual(loaded?.vector, vector)
        XCTAssertEqual(loaded?.swipeCount, 1)

        // Cleanup
        CalibrationStore.delete(for: profileId)
        XCTAssertNil(CalibrationStore.load(for: profileId))
    }

    // MARK: - rankWithVector

    func testRankWithVector_boostedTagRanksHigher() {
        let profile = makeProfile(primaryKey: "scandinavian", primaryLabel: "Scandinavian")
        let recs = RecommendationEngine.recommend(
            profile: profile,
            catalog: MockCatalog.items,
            context: .livingRoom,
            goal: .refresh,
            limit: 30
        )

        var vector = TasteVector.zero
        vector.weights["industrial"] = 1.0

        let reranked = RecommendationEngine.rankWithVector(
            recs, vector: vector, catalog: MockCatalog.items,
            context: .livingRoom, goal: .refresh
        )

        // Industrial items should be near the top
        let topSkus = reranked.prefix(5).map(\.skuId)
        let industrialSkus = Set(MockCatalog.items.filter { $0.tags.contains(.industrial) }.map(\.skuId))
        let industrialInTop = topSkus.filter { industrialSkus.contains($0) }
        XCTAssertFalse(industrialInTop.isEmpty, "Industrial items should rank high when boosted")
    }

    func testRankWithVector_avoidedTagRanksLower() {
        let profile = makeProfile(primaryKey: "scandinavian", primaryLabel: "Scandinavian")
        let recs = RecommendationEngine.recommend(
            profile: profile,
            catalog: MockCatalog.items,
            context: .livingRoom,
            goal: .refresh,
            limit: 30
        )

        var vector = TasteVector.zero
        vector.weights["industrial"] = -0.5

        let reranked = RecommendationEngine.rankWithVector(
            recs, vector: vector, catalog: MockCatalog.items,
            context: .livingRoom, goal: .refresh
        )

        // Industrial items should NOT be near the top
        let topSkus = reranked.prefix(5).map(\.skuId)
        let industrialSkus = Set(MockCatalog.items.filter { $0.tags.contains(.industrial) }.map(\.skuId))
        let industrialInTop = topSkus.filter { industrialSkus.contains($0) }
        XCTAssertTrue(industrialInTop.isEmpty, "Avoided industrial items should not rank in top 5")
    }

    // MARK: - Variant Generation

    func testGenerateVariants_returnsThreeVariants() {
        var vector = TasteVector.zero
        vector.weights["scandinavian"] = 0.9
        vector.weights["industrial"] = 0.5
        vector.weights["bohemian"] = -0.4

        let variants = vector.generateVariants()
        XCTAssertEqual(variants.count, 3)

        // Variant A label should contain the top tag display name
        XCTAssertTrue(variants[0].label.contains("Scandinavian"), "Variant A label should reference top tag")
        // Variant B label should contain the second tag display name
        XCTAssertTrue(variants[1].label.contains("Industrial"), "Variant B label should reference second tag")
        // Variant C is always "Contrast Mix"
        XCTAssertEqual(variants[2].label, "Contrast Mix")
    }

    func testVariantA_boostsTopWeight() {
        var vector = TasteVector.zero
        vector.weights["scandinavian"] = 0.8
        vector.weights["industrial"] = 0.4

        let variants = vector.generateVariants()
        let variantA = variants[0]

        // Top tag should be boosted by 20%
        XCTAssertEqual(variantA.vector.weights["scandinavian"]!, 0.8 * 1.2, accuracy: 0.001)
        // Other tags unchanged
        XCTAssertEqual(variantA.vector.weights["industrial"]!, 0.4, accuracy: 0.001)
    }

    func testVariantC_invertsAvoidedTags() {
        var vector = TasteVector.zero
        vector.weights["scandinavian"] = 0.8
        vector.weights["bohemian"] = -0.5
        vector.weights["artDeco"] = -0.3

        let variants = vector.generateVariants()
        let variantC = variants[2]

        // Avoided tags (< -0.2) should be flipped: value * -0.5
        XCTAssertEqual(variantC.vector.weights["bohemian"]!, 0.25, accuracy: 0.001)
        XCTAssertEqual(variantC.vector.weights["artDeco"]!, 0.15, accuracy: 0.001)
        // Non-avoided tags unchanged
        XCTAssertEqual(variantC.vector.weights["scandinavian"]!, 0.8, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeProfile(primaryKey: String, primaryLabel: String) -> TasteProfile {
        TasteProfile(
            tags: [TasteTag(key: primaryKey, label: primaryLabel, confidence: 0.85)],
            story: "Test story",
            signals: [Signal(key: "palette_temperature", value: "cool")]
        )
    }
}
