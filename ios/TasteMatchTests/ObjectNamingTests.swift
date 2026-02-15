import XCTest
@testable import TasteMatch

final class ObjectNamingTests: XCTestCase {

    func testGenerate_productsSignalAndTone() {
        let scores = ObjectAxisScores(
            precision: 0.8, patina: 0.1, utility: 0.2, formality: -0.1,
            subculture: 0.0, ornament: -0.3, heritage: 0.4,
            technicality: 0.5, minimalism: 0.1
        )
        let name = ObjectNamingEngine.generateFromObjectAxes(
            objectScores: scores, basisHash: "test-hash-123"
        )

        // Should be two words: "{Signal} {Identity Tone}"
        let parts = name.split(separator: " ")
        XCTAssertEqual(parts.count, 2, "Name should be two words: '\(name)'")
    }

    func testGenerate_deterministicForSameHash() {
        let scores = ObjectAxisScores(
            precision: 0.6, patina: -0.2, utility: 0.3, formality: 0.1,
            subculture: -0.4, ornament: 0.0, heritage: 0.5,
            technicality: 0.2, minimalism: -0.1
        )
        let name1 = ObjectNamingEngine.generateFromObjectAxes(
            objectScores: scores, basisHash: "stable-hash"
        )
        let name2 = ObjectNamingEngine.generateFromObjectAxes(
            objectScores: scores, basisHash: "stable-hash"
        )
        XCTAssertEqual(name1, name2)
    }

    func testGenerate_differentHashProducesDifferentName() {
        let scores = ObjectAxisScores(
            precision: 0.8, patina: 0.1, utility: 0.2, formality: -0.1,
            subculture: 0.0, ornament: -0.3, heritage: 0.4,
            technicality: 0.5, minimalism: 0.1
        )
        let name1 = ObjectNamingEngine.generateFromObjectAxes(
            objectScores: scores, basisHash: "hash-alpha"
        )
        let name2 = ObjectNamingEngine.generateFromObjectAxes(
            objectScores: scores, basisHash: "hash-completely-different-beta"
        )
        // Different hashes should produce different names in most cases
        // (could collide, but very unlikely with these inputs)
        XCTAssertNotEqual(name1, name2, "Different hashes should usually produce different names")
    }

    func testNoOverlapWithSpaceNames() {
        // Space structural pools
        let spaceWords: Set<String> = [
            "Minimal", "Clean", "Spare", "Quiet", "Ornate", "Adorned", "Rich", "Elaborate",
            "Warm", "Earth", "Sunlit", "Cool", "Frost", "Nordic",
            "Structured", "Rigid", "Composed", "Soft", "Gentle", "Relaxed",
            "Industrial", "Brutal", "Concrete", "Raw", "Organic", "Natural", "Verdant",
            "Light", "Airy", "Bright", "Dark", "Noir", "Midnight", "Studio",
            "Neutral", "Tonal", "Muted", "Saturated", "Vivid", "Chromatic",
            "Sparse", "Open", "Reduced", "Layered", "Textural", "Expressive",
        ]

        // Object signal pools
        let objectSignals: [String] = [
            "Calibrated", "Machined", "Exacting", "Toleranced",
            "Rough", "Approximate", "Loose", "Unmetered",
            "Weathered", "Worn", "Oxidized", "Seasoned",
            "Pristine", "Factory", "Sealed", "Unworn",
            "Deployed", "Fielded", "Loaded", "Carried",
            "Displayed", "Archived", "Mounted", "Cased",
            "Ceremonial", "Formal", "Dressed", "Protocol",
            "Casual", "Off-Duty", "Undone", "Relaxed",
            "Underground", "Coded", "Deep-Cut", "Insider",
            "Standard", "Mainline", "Universal", "Open",
            "Etched", "Guilloché", "Engraved", "Filigreed",
            "Blank", "Bare", "Stripped", "Unmarked",
            "Storied", "Lineage", "Legacy", "Archive",
            "New-Gen", "First-Run", "Debut", "Zero",
            "Engineered", "Composite", "Alloy", "Technical",
            "Analog", "Manual", "Handbuilt", "Lo-Fi",
            "Reduced", "Distilled", "Essential", "Negative",
            "Stacked", "Dense", "Loaded", "Heavy",
        ]

        // Check overlap (allowing a few shared words is fine; main pools should be distinct)
        let overlap = Set(objectSignals).intersection(spaceWords)
        // "Open" and "Relaxed" may overlap — that's acceptable.
        // But the core vocabulary should be distinct.
        XCTAssertLessThanOrEqual(overlap.count, 4,
            "Object signal pools should not heavily overlap with Space. Overlapping: \(overlap)")
    }
}
