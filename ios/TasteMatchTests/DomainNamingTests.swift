import XCTest
@testable import TasteMatch

final class DomainNamingTests: XCTestCase {

    private let testScores = AxisScores(
        minimalOrnate: -0.5, warmCool: 0.3, softStructured: 0.6,
        organicIndustrial: 0.7, lightDark: 0.4, neutralSaturated: -0.3, sparseLayered: 0.2
    )
    private let testHash = "+M|+L|+M|+H|+M|-M|+L|industrial|rustic|Strong"

    // MARK: - Determinism

    func testObjectNaming_isDeterministic() {
        let name1 = ObjectNamingEngine.generate(axisScores: testScores, basisHash: testHash)
        let name2 = ObjectNamingEngine.generate(axisScores: testScores, basisHash: testHash)
        XCTAssertEqual(name1, name2, "Object naming should be deterministic")
    }

    func testArtNaming_isDeterministic() {
        let name1 = ArtNamingEngine.generate(axisScores: testScores, basisHash: testHash)
        let name2 = ArtNamingEngine.generate(axisScores: testScores, basisHash: testHash)
        XCTAssertEqual(name1, name2, "Art naming should be deterministic")
    }

    // MARK: - Two-Word Grammar

    func testObjectNaming_producesLifestyleLabel() {
        let scores = [
            AxisScores(minimalOrnate: -0.8, warmCool: 0.3, softStructured: 0.2,
                      organicIndustrial: 0.1, lightDark: -0.4, neutralSaturated: -0.5, sparseLayered: -0.3),
            AxisScores(minimalOrnate: 0.7, warmCool: 0.8, softStructured: -0.3,
                      organicIndustrial: -0.5, lightDark: 0.2, neutralSaturated: 0.4, sparseLayered: 0.6),
            testScores
        ]
        let hashes = ["hash-a", "hash-b", testHash]

        for (i, s) in scores.enumerated() {
            let name = ObjectNamingEngine.generate(axisScores: s, basisHash: hashes[i])
            XCTAssertTrue(ObjectNamingEngine.allLifestyleNames.contains(name),
                "Object name '\(name)' should be a known lifestyle label")
        }
    }

    func testArtNaming_exactlyTwoWords() {
        let scores = [
            AxisScores(minimalOrnate: -0.8, warmCool: 0.3, softStructured: 0.2,
                      organicIndustrial: 0.1, lightDark: -0.4, neutralSaturated: -0.5, sparseLayered: -0.3),
            AxisScores(minimalOrnate: 0.7, warmCool: 0.8, softStructured: -0.3,
                      organicIndustrial: -0.5, lightDark: 0.2, neutralSaturated: 0.4, sparseLayered: 0.6),
            testScores
        ]
        let hashes = ["hash-a", "hash-b", testHash]

        for (i, s) in scores.enumerated() {
            let name = ArtNamingEngine.generate(axisScores: s, basisHash: hashes[i])
            let words = name.split(separator: " ")
            XCTAssertEqual(words.count, 2,
                "Art name '\(name)' should be exactly 2 words (hyphenated words count as one)")
        }
    }

    // MARK: - Names Differ Per Domain

    func testNames_differPerDomain() {
        let spaceName = DomainNameDispatcher.generate(
            axisScores: testScores, basisHash: testHash, domain: .space
        )
        let objectName = DomainNameDispatcher.generate(
            axisScores: testScores, basisHash: testHash, domain: .objects
        )
        let artName = DomainNameDispatcher.generate(
            axisScores: testScores, basisHash: testHash, domain: .art
        )

        let uniqueNames = Set([spaceName, objectName, artName])
        XCTAssertGreaterThanOrEqual(uniqueNames.count, 2,
            "At least 2 of 3 domain names should be unique. Got: space=\(spaceName), objects=\(objectName), art=\(artName)")
    }

    // MARK: - Dispatcher Routing

    func testDispatcher_routesToSpaceEngine() {
        let name = DomainNameDispatcher.generate(
            axisScores: testScores, basisHash: testHash, domain: .space
        )
        let spaceName = ProfileNameGenerator.generate(from: testScores, basisHash: testHash)
        XCTAssertEqual(name, spaceName, "Space domain should use ProfileNameGenerator")
    }

    func testDispatcher_routesToObjectsEngine() {
        let name = DomainNameDispatcher.generate(
            axisScores: testScores, basisHash: testHash, domain: .objects
        )
        let objectName = ObjectNamingEngine.generate(axisScores: testScores, basisHash: testHash)
        XCTAssertEqual(name, objectName, "Objects domain should use ObjectNamingEngine")
    }

    func testDispatcher_routesToArtEngine() {
        let name = DomainNameDispatcher.generate(
            axisScores: testScores, basisHash: testHash, domain: .art
        )
        let artName = ArtNamingEngine.generate(axisScores: testScores, basisHash: testHash)
        XCTAssertEqual(name, artName, "Art domain should use ArtNamingEngine")
    }

    // MARK: - No Canonical Label Leakage

    func testNames_noCanonicalLabelLeakage() {
        let bannedFragments = [
            "Mid-Century Modern", "Scandinavian", "Industrial", "Bohemian",
            "Minimalist", "Traditional", "Coastal", "Rustic", "Art Deco", "Japandi"
        ]

        let variations: [AxisScores] = [
            testScores,
            AxisScores(minimalOrnate: -0.9, warmCool: -0.4, softStructured: -0.3,
                      organicIndustrial: -0.3, lightDark: -0.7, neutralSaturated: -0.5, sparseLayered: -0.6),
            AxisScores(minimalOrnate: 0.8, warmCool: 0.7, softStructured: -0.5,
                      organicIndustrial: -0.6, lightDark: 0.1, neutralSaturated: 0.6, sparseLayered: 0.8),
        ]

        for scores in variations {
            // Objects domain intentionally uses lifestyle labels — skip it
            for domain in [TasteDomain.space, .art] {
                let name = DomainNameDispatcher.generate(
                    axisScores: scores, basisHash: testHash, domain: domain
                )
                for banned in bannedFragments {
                    XCTAssertFalse(name.contains(banned),
                        "Domain name '\(name)' should not contain canonical label '\(banned)'")
                }
            }
        }
    }
}
