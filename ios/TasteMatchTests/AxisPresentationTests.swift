import XCTest
@testable import TasteMatch

final class AxisPresentationTests: XCTestCase {

    private let canonicalLabels = [
        "Art Deco", "Scandinavian", "Bohemian", "Industrial", "Minimalist",
        "Traditional", "Coastal", "Rustic", "Mid-Century Modern", "Japandi",
    ]

    // MARK: - Influence Phrases

    func testInfluencePhrases_neverContainCanonicalLabels() {
        for tag in TasteEngine.CanonicalTag.allCases {
            var weights: [String: Double] = [:]
            for t in TasteEngine.CanonicalTag.allCases {
                weights[String(describing: t)] = 0.0
            }
            weights[String(describing: tag)] = 1.0
            let vector = TasteVector(weights: weights)
            let scores = AxisMapping.computeAxisScores(from: vector)
            let phrases = AxisPresentation.influencePhrases(axisScores: scores)

            for phrase in phrases {
                for label in canonicalLabels {
                    XCTAssertFalse(phrase.contains(label),
                                   "Influence phrase '\(phrase)' for tag \(tag) should not contain '\(label)'")
                }
            }
        }
    }

    func testInfluencePhrases_returnsAtLeastTwo() {
        for tag in TasteEngine.CanonicalTag.allCases {
            var weights: [String: Double] = [:]
            for t in TasteEngine.CanonicalTag.allCases {
                weights[String(describing: t)] = 0.0
            }
            weights[String(describing: tag)] = 1.0
            let vector = TasteVector(weights: weights)
            let scores = AxisMapping.computeAxisScores(from: vector)
            let phrases = AxisPresentation.influencePhrases(axisScores: scores)

            XCTAssertGreaterThanOrEqual(phrases.count, 2,
                                         "Tag \(tag) should produce at least 2 influence phrases")
        }
    }

    func testInfluencePhrases_deterministic() {
        let scores = AxisScores(
            minimalOrnate: -0.5, warmCool: 0.3, softStructured: 0.6,
            organicIndustrial: 0.8, lightDark: 0.4, neutralSaturated: -0.2, sparseLayered: 0.1
        )
        let first = AxisPresentation.influencePhrases(axisScores: scores)
        let second = AxisPresentation.influencePhrases(axisScores: scores)
        XCTAssertEqual(first, second)
    }

    func testInfluencePhrases_categoryMixing() {
        let scores = AxisScores(
            minimalOrnate: -0.5, warmCool: 0.3, softStructured: 0.6,
            organicIndustrial: 0.8, lightDark: 0.4, neutralSaturated: -0.2, sparseLayered: 0.1
        )
        let phrases = AxisPresentation.influencePhrases(axisScores: scores)
        XCTAssertGreaterThanOrEqual(phrases.count, 2)
        XCTAssertLessThanOrEqual(phrases.count, 4)
    }

    // MARK: - Avoid Phrases

    func testAvoidPhrases_neverContainCanonicalLabels() {
        for tag in TasteEngine.CanonicalTag.allCases {
            var weights: [String: Double] = [:]
            for t in TasteEngine.CanonicalTag.allCases {
                weights[String(describing: t)] = 0.0
            }
            weights[String(describing: tag)] = 1.0
            let vector = TasteVector(weights: weights)
            let scores = AxisMapping.computeAxisScores(from: vector)
            let phrases = AxisPresentation.avoidPhrases(axisScores: scores)

            for phrase in phrases {
                for label in canonicalLabels {
                    XCTAssertFalse(phrase.contains(label),
                                   "Avoid phrase '\(phrase)' for tag \(tag) should not contain '\(label)'")
                }
            }
        }
    }

    func testAvoidPhrases_canReturnEmpty() {
        // Balanced vector — all zeros
        let scores = AxisScores.zero
        let phrases = AxisPresentation.avoidPhrases(axisScores: scores)
        XCTAssertTrue(phrases.isEmpty, "Balanced vector should produce no avoid phrases")
    }

    // MARK: - One Line Reading

    func testOneLineReading_neverContainsCanonicalLabels() {
        for tag in TasteEngine.CanonicalTag.allCases {
            var weights: [String: Double] = [:]
            for t in TasteEngine.CanonicalTag.allCases {
                weights[String(describing: t)] = 0.0
            }
            weights[String(describing: tag)] = 1.0
            let vector = TasteVector(weights: weights)
            let scores = AxisMapping.computeAxisScores(from: vector)
            let reading = AxisPresentation.oneLineReading(profileName: "Test Profile", axisScores: scores)

            for label in canonicalLabels {
                XCTAssertFalse(reading.contains(label),
                               "Reading for tag \(tag) should not contain '\(label)'")
            }
        }
    }

    func testOneLineReading_containsProfileName() {
        let scores = AxisScores(
            minimalOrnate: -0.5, warmCool: 0.3, softStructured: 0.6,
            organicIndustrial: 0.8, lightDark: 0.4, neutralSaturated: -0.2, sparseLayered: 0.1
        )
        let reading = AxisPresentation.oneLineReading(profileName: "Berlin Industrial", axisScores: scores)
        XCTAssertTrue(reading.contains("Berlin Industrial"))
    }

    func testOneLineReading_wordCountInRange() {
        // Test across all canonical tag vectors
        for tag in TasteEngine.CanonicalTag.allCases {
            var weights: [String: Double] = [:]
            for t in TasteEngine.CanonicalTag.allCases {
                weights[String(describing: t)] = 0.0
            }
            weights[String(describing: tag)] = 1.0
            let vector = TasteVector(weights: weights)
            let scores = AxisMapping.computeAxisScores(from: vector)
            let reading = AxisPresentation.oneLineReading(profileName: "Test Profile", axisScores: scores)

            let wordCount = reading
                .components(separatedBy: .whitespaces)
                .filter { $0.rangeOfCharacter(from: .letters) != nil }
                .count

            XCTAssertGreaterThanOrEqual(wordCount, 10,
                "Reading for \(tag) has \(wordCount) words (expected >= 10): \(reading)")
            XCTAssertLessThanOrEqual(wordCount, 18,
                "Reading for \(tag) has \(wordCount) words (expected <= 18): \(reading)")
        }
    }

    func testOneLineReading_deterministic() {
        let scores = AxisScores(
            minimalOrnate: -0.5, warmCool: 0.3, softStructured: 0.6,
            organicIndustrial: 0.8, lightDark: 0.4, neutralSaturated: -0.2, sparseLayered: 0.1
        )
        let first = AxisPresentation.oneLineReading(profileName: "Test Name", axisScores: scores)
        let second = AxisPresentation.oneLineReading(profileName: "Test Name", axisScores: scores)
        XCTAssertEqual(first, second)
    }

    func testOneLineReading_alwaysContainsProfileName() {
        let names = ["Berlin Industrial", "Quiet Meridian", "Soft Archive", "Warm Contour"]
        let scores = AxisScores(
            minimalOrnate: 0.7, warmCool: -0.4, softStructured: 0.2,
            organicIndustrial: -0.6, lightDark: 0.1, neutralSaturated: 0.5, sparseLayered: -0.3
        )
        for name in names {
            let reading = AxisPresentation.oneLineReading(profileName: name, axisScores: scores)
            XCTAssertTrue(reading.contains(name),
                          "Reading should contain profile name '\(name)': \(reading)")
        }
    }
}
