import XCTest
@testable import TasteMatch

final class ObjectNamingTests: XCTestCase {

    func testGenerate_producesLifestyleLabel() {
        let scores = ObjectAxisScores(
            precision: 0.8, patina: 0.1, utility: 0.2, formality: -0.1,
            subculture: 0.0, ornament: -0.3, heritage: 0.4,
            technicality: 0.5, minimalism: 0.1
        )
        let name = ObjectNamingEngine.generateFromObjectAxes(
            objectScores: scores, basisHash: "test-hash-123"
        )

        XCTAssertTrue(
            ObjectNamingEngine.allLifestyleNames.contains(name),
            "Name '\(name)' should be a known lifestyle label"
        )
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

    func testGenerate_differentScoresProduceDifferentLabel() {
        // Scores strongly aligned with Techwear
        let techScores = ObjectAxisScores(
            precision: 0.8, patina: -0.5, utility: 0.2, formality: -0.2,
            subculture: 0.0, ornament: -0.3, heritage: -0.6,
            technicality: 0.9, minimalism: 0.6
        )
        // Scores strongly aligned with Vintage
        let vintageScores = ObjectAxisScores(
            precision: -0.2, patina: 0.9, utility: 0.0, formality: 0.1,
            subculture: 0.1, ornament: 0.2, heritage: 0.8,
            technicality: -0.6, minimalism: -0.1
        )
        let name1 = ObjectNamingEngine.generateFromObjectAxes(
            objectScores: techScores, basisHash: "any-hash"
        )
        let name2 = ObjectNamingEngine.generateFromObjectAxes(
            objectScores: vintageScores, basisHash: "any-hash"
        )
        XCTAssertNotEqual(name1, name2,
            "Very different axis profiles should produce different lifestyle labels")
    }

    func testNoOverlapWithSpaceNames() {
        let spaceWords: Set<String> = [
            "Minimal", "Clean", "Spare", "Quiet", "Ornate", "Adorned", "Rich", "Elaborate",
            "Warm", "Earth", "Sunlit", "Cool", "Frost", "Nordic",
            "Structured", "Rigid", "Composed", "Soft", "Gentle", "Relaxed",
            "Industrial", "Brutal", "Concrete", "Raw", "Organic", "Natural", "Verdant",
            "Light", "Airy", "Bright", "Dark", "Noir", "Midnight", "Studio",
            "Neutral", "Tonal", "Muted", "Saturated", "Vivid", "Chromatic",
            "Sparse", "Open", "Reduced", "Layered", "Textural", "Expressive",
        ]

        let overlap = ObjectNamingEngine.allLifestyleNames.intersection(spaceWords)
        XCTAssertEqual(overlap.count, 0,
            "Lifestyle labels should not overlap with Space names. Overlapping: \(overlap)")
    }

    func testAllAestheticNames_areRecognizable() {
        let expected: Set<String> = [
            "Quiet Luxury", "Normcore", "Streetwear", "Vintage", "Techwear",
            "Old Money", "Gorpcore", "Wabi-Sabi", "Maximalist", "Workwear",
            "Dark Academia", "Avant-Garde", "Western", "Prep", "Artisan",
            "Military", "Minimalist", "Bohemian",
        ]
        XCTAssertEqual(ObjectNamingEngine.allLifestyleNames, expected)
    }

    func testFallbackFromSpaceAxes() {
        let spaceScores = AxisScores(
            minimalOrnate: 0.5, warmCool: 0.3, softStructured: 0.7,
            organicIndustrial: -0.2, lightDark: 0.0,
            neutralSaturated: -0.1, sparseLayered: 0.2
        )
        let name = ObjectNamingEngine.generate(
            axisScores: spaceScores, basisHash: "fallback-hash"
        )
        XCTAssertTrue(
            ObjectNamingEngine.allLifestyleNames.contains(name),
            "Fallback name '\(name)' should be a known lifestyle label"
        )
    }
}
