import XCTest
@testable import TasteMatch

final class DesignTipsEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeProfile(
        primaryKey: String = "scandinavian",
        primaryLabel: String = "Scandinavian",
        primaryConfidence: Double = 0.85,
        secondaryKey: String? = nil,
        secondaryLabel: String? = nil,
        palette: String = "cool",
        material: String = "wood"
    ) -> TasteProfile {
        var tags = [TasteTag(key: primaryKey, label: primaryLabel, confidence: primaryConfidence)]
        if let secKey = secondaryKey, let secLabel = secondaryLabel {
            tags.append(TasteTag(key: secKey, label: secLabel, confidence: 0.5))
        }
        return TasteProfile(
            tags: tags,
            story: "Test story",
            signals: [
                Signal(key: "palette_temperature", value: palette),
                Signal(key: "material", value: material),
            ]
        )
    }

    // MARK: - Basic output

    func testTips_returnsUpToThree() {
        let profile = makeProfile()
        let tips = DesignTipsEngine.tips(for: profile, context: .bedroom, goal: .refresh)
        XCTAssertGreaterThanOrEqual(tips.count, 1)
        XCTAssertLessThanOrEqual(tips.count, 3)
    }

    func testTips_neverReturnsMoreThanThree() {
        let profile = makeProfile(
            secondaryKey: "japandi",
            secondaryLabel: "Japandi"
        )
        let tips = DesignTipsEngine.tips(for: profile, context: .livingRoom, goal: .overhaul)
        XCTAssertLessThanOrEqual(tips.count, 3)
    }

    // MARK: - Primary style tip

    func testTips_includesPrimaryStyleTip() {
        let profile = makeProfile(primaryKey: "industrial", primaryLabel: "Industrial")
        let tips = DesignTipsEngine.tips(for: profile)
        // Industrial maps to organicIndustrial positive — tip should mention "raw" or "expose"
        XCTAssertTrue(tips.contains(where: { $0.headline.lowercased().contains("raw") || $0.headline.lowercased().contains("expose") }),
                       "Should include raw/expose tip for industrial axis")
    }

    // MARK: - All 10 tags produce a tip

    func testTips_everyCanonicalTagHasATip() {
        let tagKeys = TasteEngine.CanonicalTag.allCases.map { String(describing: $0) }
        for key in tagKeys {
            let profile = makeProfile(primaryKey: key, primaryLabel: key)
            let tips = DesignTipsEngine.tips(for: profile)
            XCTAssertFalse(tips.isEmpty, "Tag '\(key)' should produce at least one tip")
        }
    }

    // MARK: - Room context adds a tip

    func testTips_roomContextAddsTip() {
        let profile = makeProfile()
        let withRoom = DesignTipsEngine.tips(for: profile, context: .kitchen)
        let without = DesignTipsEngine.tips(for: profile)
        // With room context we should get at least as many tips
        XCTAssertGreaterThanOrEqual(withRoom.count, without.count)
    }

    // MARK: - Goal adds a tip

    func testTips_goalAddsContent() {
        let profile = makeProfile(palette: "warm", material: "textile")
        let tips = DesignTipsEngine.tips(for: profile, goal: .accent)
        // Should have content from goal or other sources
        XCTAssertGreaterThanOrEqual(tips.count, 2)
    }

    // MARK: - Tips have non-empty fields

    func testTips_allFieldsPopulated() {
        let profile = makeProfile(secondaryKey: "minimalist", secondaryLabel: "Minimalist")
        let tips = DesignTipsEngine.tips(for: profile, context: .office, goal: .organize)
        for tip in tips {
            XCTAssertFalse(tip.icon.isEmpty, "Tip icon should not be empty")
            XCTAssertFalse(tip.headline.isEmpty, "Tip headline should not be empty")
            XCTAssertFalse(tip.body.isEmpty, "Tip body should not be empty")
        }
    }

    // MARK: - Signal-based tips

    func testTips_warmWoodGetsFlameTip() {
        let profile = makeProfile(palette: "warm", material: "wood")
        let tips = DesignTipsEngine.tips(for: profile)
        XCTAssertTrue(tips.contains(where: { $0.icon == "flame" }),
                       "Warm + wood should produce amber light tip")
    }

    func testTips_coolMetalGetsPolishTip() {
        let profile = makeProfile(primaryKey: "industrial", primaryLabel: "Industrial",
                                   palette: "cool", material: "metal")
        let tips = DesignTipsEngine.tips(for: profile)
        XCTAssertTrue(tips.contains(where: { $0.icon == "sparkle" }),
                       "Cool + metal should produce polish tip")
    }
}
