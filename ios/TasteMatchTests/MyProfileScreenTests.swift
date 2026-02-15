import XCTest
@testable import TasteMatch

final class MyProfileScreenTests: XCTestCase {

    func testResolveBaseVector_withCalibration() {
        // Create a profile and calibration record
        let signals = VisualSignals(
            paletteTemperature: .cool,
            brightness: .high,
            contrast: .low,
            saturation: .muted,
            edgeDensity: .low,
            material: .wood
        )
        let profile = TasteEngine.analyze(
            signals: signals,
            context: .livingRoom,
            goal: .refresh
        )
        let imageVector = TasteEngine.vectorFromProfile(profile)

        let swipeVector = TasteVector(weights: [
            "scandinavian": 0.8,
            "minimalist": 0.6,
            "industrial": -0.4
        ]).normalized()

        let blended = TasteVector.blend(
            image: imageVector,
            swipe: swipeVector,
            mode: .wantMore
        )

        // Blended vector should be different from pure image vector
        let imageScores = AxisMapping.computeAxisScores(from: imageVector)
        let blendedScores = AxisMapping.computeAxisScores(from: blended)

        // At least one axis should differ after blending
        let anyDifferent = Axis.allCases.contains { axis in
            abs(imageScores.value(for: axis) - blendedScores.value(for: axis)) > 0.01
        }
        XCTAssertTrue(anyDifferent)
    }

    func testResolveBaseVector_withoutCalibration() {
        // Without calibration, should return pure image vector
        let signals = VisualSignals(
            paletteTemperature: .warm,
            brightness: .low,
            contrast: .high,
            saturation: .vivid,
            edgeDensity: .high,
            material: .metal
        )
        let profile = TasteEngine.analyze(
            signals: signals,
            context: .bedroom,
            goal: .overhaul
        )
        let imageVector = TasteEngine.vectorFromProfile(profile)

        // Without calibration, resolveBaseVector returns imageVector directly
        let scores = AxisMapping.computeAxisScores(from: imageVector)
        XCTAssertNotEqual(scores, AxisScores.zero)
    }

    // MARK: - Stability Label Thresholds

    func testStabilityLevel_low() {
        // Few swipes, low confidence → Low
        let vector = TasteVector(weights: [
            "scandinavian": 0.05,
            "minimalist": 0.02
        ])
        let level = vector.stabilityLevel(swipeCount: 3)
        XCTAssertEqual(level, "Low")
    }

    func testStabilityLevel_developing_bySwipeCount() {
        // >= 7 swipes but insufficient separation → Developing
        let vector = TasteVector(weights: [
            "scandinavian": 0.5,
            "minimalist": 0.45,
            "industrial": 0.3
        ])
        let level = vector.stabilityLevel(swipeCount: 8)
        XCTAssertEqual(level, "Developing")
    }

    func testStabilityLevel_developing_byConfidence() {
        // < 7 swipes but confidence > 0.2 → Developing
        let vector = TasteVector(weights: [
            "scandinavian": 0.8,
            "minimalist": 0.6,
            "industrial": -0.4,
            "midcentury": 0.3
        ])
        let level = vector.stabilityLevel(swipeCount: 4)
        XCTAssertEqual(level, "Developing")
    }

    func testStabilityLevel_stable() {
        // >= 14 swipes AND separation >= 0.15 → Stable
        let vector = TasteVector(weights: [
            "scandinavian": 0.9,
            "minimalist": 0.3,
            "industrial": -0.2
        ])
        let level = vector.stabilityLevel(swipeCount: 16)
        XCTAssertEqual(level, "Stable")
    }

    func testStabilityLevel_highSwipesButNoSeparation() {
        // >= 14 swipes but separation < 0.15 → Developing (not Stable)
        let vector = TasteVector(weights: [
            "scandinavian": 0.5,
            "minimalist": 0.48
        ])
        let level = vector.stabilityLevel(swipeCount: 20)
        XCTAssertEqual(level, "Developing")
    }

    // MARK: - Route

    // MARK: - Radar Image Coverage

    func testRadarCard_alwaysHasImage() {
        // dailyRadar output must always resolve to a non-nil image URL
        // either from the discovery item's own imageURL or from related commerce
        let allDiscovery = DiscoveryEngine.loadAll()
        XCTAssertGreaterThan(allDiscovery.count, 0, "Discovery items must be loaded")

        let vector = TasteVector(weights: ["industrial": 0.7, "minimalist": 0.3]).normalized()
        let axisScores = AxisMapping.computeAxisScores(from: vector)
        let profileId = UUID()

        let radar = DiscoveryEngine.dailyRadar(
            items: allDiscovery,
            axisScores: axisScores,
            signals: nil,
            profileId: profileId,
            vector: vector
        )
        XCTAssertGreaterThan(radar.count, 0, "Radar must return items")

        for item in radar {
            // Primary: discovery item's own imageURL
            if let url = item.imageURL {
                XCTAssertTrue(url.hasPrefix("https://"), "\(item.id) imageURL must be HTTPS: \(url)")
                continue
            }
            // Fallback: related commerce items must exist
            let sv = AxisMapping.syntheticVector(fromAxes: item.axisWeights)
            let ss = AxisMapping.computeAxisScores(from: sv)
            let ranked = RecommendationEngine.rankCommerceItems(
                vector: sv, axisScores: ss, items: MockCatalog.items
            )
            XCTAssertGreaterThan(ranked.count, 0,
                "\(item.id) must have commerce fallback images")
            XCTAssertNotNil(ranked.first?.resolvedImageURL,
                "\(item.id) commerce fallback must have a resolved image URL")
        }
    }

    func testDiscoveryItems_allHaveImageURL() {
        let allDiscovery = DiscoveryEngine.loadAll()
        XCTAssertGreaterThan(allDiscovery.count, 0)
        for item in allDiscovery {
            XCTAssertNotNil(item.imageURL, "\(item.id) must have imageURL")
            XCTAssertTrue(item.imageURL!.hasPrefix("https://"),
                "\(item.id) imageURL must be HTTPS")
        }
    }

    func testCommerceItems_haveValidImageURLs() {
        let items = MockCatalog.items
        XCTAssertGreaterThan(items.count, 0, "Commerce catalog must not be empty")
        // Verify first 50 items have valid HTTPS imageURLs
        for item in items.prefix(50) {
            XCTAssertTrue(item.imageURL.hasPrefix("https://"),
                "\(item.skuId) imageURL must be HTTPS: \(item.imageURL)")
            XCTAssertFalse(item.imageURL.isEmpty,
                "\(item.skuId) imageURL must not be empty")
        }
    }

    // MARK: - Route

    // MARK: - RevealStore

    func testRevealStore_defaultFalse() {
        let id = UUID()
        XCTAssertFalse(RevealStore.isRevealed(id))
    }

    func testRevealStore_markRevealed() {
        let id = UUID()
        RevealStore.markRevealed(id)
        XCTAssertTrue(RevealStore.isRevealed(id))
        RevealStore.clear(id)
        XCTAssertFalse(RevealStore.isRevealed(id))
    }

    func testRevealStore_perProfile() {
        let idA = UUID()
        let idB = UUID()
        RevealStore.markRevealed(idA)
        XCTAssertTrue(RevealStore.isRevealed(idA))
        XCTAssertFalse(RevealStore.isRevealed(idB))
        RevealStore.clear(idA)
    }

    func testHomeAutoNavigate_requiresLatestProfile() {
        // When no profiles exist, loadLatest returns nil — no auto-navigate
        let allProfiles = ProfileStore.loadAll()
        if allProfiles.isEmpty {
            XCTAssertNil(ProfileStore.loadLatest())
        } else {
            XCTAssertNotNil(ProfileStore.loadLatest())
        }
    }

    func testRouteProfile_hashEquality() {
        let id1 = UUID()
        let id2 = UUID()

        let route1a = Route.profile(id1)
        let route1b = Route.profile(id1)
        let route2 = Route.profile(id2)

        XCTAssertEqual(route1a, route1b)
        XCTAssertNotEqual(route1a, route2)

        // Hash equality
        var hasher1a = Hasher()
        route1a.hash(into: &hasher1a)
        var hasher1b = Hasher()
        route1b.hash(into: &hasher1b)
        XCTAssertEqual(hasher1a.finalize(), hasher1b.finalize())
    }
}
