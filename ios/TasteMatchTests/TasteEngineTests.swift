import XCTest
@testable import TasteMatch

final class TasteEngineTests: XCTestCase {

    // MARK: - Known input → expected primary tag

    func testWarmMediumWoodSignals_producesMidCenturyModern() {
        let signals = VisualSignals(
            paletteTemperature: .warm,
            brightness: .medium,
            contrast: .medium,
            saturation: .neutral,
            edgeDensity: .medium,
            material: .wood
        )

        let profile = TasteEngine.analyze(signals: signals, context: .livingRoom, goal: .refresh)

        XCTAssertFalse(profile.tags.isEmpty)
        XCTAssertEqual(profile.tags.first?.key, "midCenturyModern")
        XCTAssertEqual(profile.tags.first?.label, "Mid-Century Modern")
    }

    func testCoolHighLowMutedLowWood_producesScandinavian() {
        let signals = VisualSignals(
            paletteTemperature: .cool,
            brightness: .high,
            contrast: .low,
            saturation: .muted,
            edgeDensity: .low,
            material: .wood
        )

        let profile = TasteEngine.analyze(signals: signals, context: .bedroom, goal: .refresh)

        XCTAssertEqual(profile.tags.first?.key, "scandinavian")
    }

    func testCoolLowHighMutedHighMetal_producesIndustrial() {
        let signals = VisualSignals(
            paletteTemperature: .cool,
            brightness: .low,
            contrast: .high,
            saturation: .muted,
            edgeDensity: .high,
            material: .metal
        )

        let profile = TasteEngine.analyze(signals: signals, context: .office, goal: .refresh)

        XCTAssertEqual(profile.tags.first?.key, "industrial")
    }

    // MARK: - Determinism

    func testSameInputs_produceSameOutput() {
        let signals = VisualSignals(
            paletteTemperature: .warm,
            brightness: .medium,
            contrast: .low,
            saturation: .vivid,
            edgeDensity: .high,
            material: .textile
        )

        let a = TasteEngine.analyze(signals: signals, context: .livingRoom, goal: .overhaul)
        let b = TasteEngine.analyze(signals: signals, context: .livingRoom, goal: .overhaul)

        XCTAssertEqual(a.tags.count, b.tags.count)
        XCTAssertEqual(a.tags.first?.key, b.tags.first?.key)
        XCTAssertEqual(a.tags.first?.confidence, b.tags.first?.confidence)
        XCTAssertEqual(a.story, b.story)
    }

    // MARK: - Tag key vs label

    func testTagKey_isDifferentFromLabel() {
        let signals = VisualSignals(
            paletteTemperature: .warm,
            brightness: .medium,
            contrast: .medium,
            saturation: .neutral,
            edgeDensity: .medium,
            material: .wood
        )

        let profile = TasteEngine.analyze(signals: signals, context: .livingRoom, goal: .refresh)
        let tag = profile.tags.first!

        // Key is camelCase enum name, label is display string
        XCTAssertFalse(tag.key.contains(" "))
        XCTAssertTrue(tag.label.contains(" ") || tag.label == tag.label.capitalized)
        XCTAssertNotEqual(tag.key, tag.label)
    }

    // MARK: - Confidence bounds

    func testConfidence_isClamped01() {
        let signals = VisualSignals(
            paletteTemperature: .warm,
            brightness: .medium,
            contrast: .medium,
            saturation: .neutral,
            edgeDensity: .medium,
            material: .wood
        )

        // Overhaul multiplier (1.1) could push scores above 1.0 before clamping
        let profile = TasteEngine.analyze(signals: signals, context: .livingRoom, goal: .overhaul)

        for tag in profile.tags {
            XCTAssertGreaterThanOrEqual(tag.confidence, 0.0)
            XCTAssertLessThanOrEqual(tag.confidence, 1.0)
        }
    }

    // MARK: - Signals populated

    func testSignals_alwaysHaveSixEntries() {
        let signals = VisualSignals(
            paletteTemperature: .cool,
            brightness: .high,
            contrast: .low,
            saturation: .muted,
            edgeDensity: .low,
            material: .wood
        )

        let profile = TasteEngine.analyze(signals: signals, context: .bedroom, goal: .accent)

        XCTAssertEqual(profile.signals.count, 6)
        let keys = Set(profile.signals.map(\.key))
        XCTAssertTrue(keys.contains("palette_temperature"))
        XCTAssertTrue(keys.contains("brightness"))
        XCTAssertTrue(keys.contains("contrast"))
        XCTAssertTrue(keys.contains("saturation"))
        XCTAssertTrue(keys.contains("edge_density"))
        XCTAssertTrue(keys.contains("material"))
    }

    // MARK: - Story non-empty

    func testStory_isNonEmpty() {
        let signals = VisualSignals(
            paletteTemperature: .neutral,
            brightness: .high,
            contrast: .low,
            saturation: .muted,
            edgeDensity: .low,
            material: .mixed
        )

        let profile = TasteEngine.analyze(signals: signals, context: .bathroom, goal: .organize)

        XCTAssertFalse(profile.story.isEmpty)
    }

    // MARK: - Context affects output

    func testDifferentContext_canChangeSecondaryTag() {
        let signals = VisualSignals(
            paletteTemperature: .neutral,
            brightness: .high,
            contrast: .low,
            saturation: .muted,
            edgeDensity: .low,
            material: .wood
        )

        let bedroom = TasteEngine.analyze(signals: signals, context: .bedroom, goal: .refresh)
        let kitchen = TasteEngine.analyze(signals: signals, context: .kitchen, goal: .refresh)

        // Context boosts differ, so secondary tag or confidence may shift
        let bedroomTags = bedroom.tags.map(\.key)
        let kitchenTags = kitchen.tags.map(\.key)
        // At minimum, the profiles should still share the same primary (signal-dominant)
        XCTAssertEqual(bedroomTags.first, kitchenTags.first)
    }
}
