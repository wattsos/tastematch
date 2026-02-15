import XCTest
@testable import TasteMatch

final class ArchetypeDuelTests: XCTestCase {

    func testGenerateDuelPairs_coversAllAxes() {
        let id = UUID()
        let pairs = ObjectArchetype.generateDuelPairs(count: 5, profileId: id)
        XCTAssertEqual(pairs.count, 5)

        // Collect all dominant axes that appear across the pairs
        var coveredAxes = Set<ObjectAxis>()
        for (a, b) in pairs {
            let aSig = a.signature
            let bSig = b.signature
            let aDom = aSig.axes.max(by: { abs($0.value) < abs($1.value) })!.key
            let bDom = bSig.axes.max(by: { abs($0.value) < abs($1.value) })!.key
            coveredAxes.insert(aDom)
            coveredAxes.insert(bDom)
        }
        // Should cover multiple distinct axes
        XCTAssertGreaterThanOrEqual(coveredAxes.count, 4,
            "Duel pairs should cover at least 4 distinct axes, covered: \(coveredAxes)")
    }

    func testGenerateDuelPairs_noDuplicatePairs() {
        let id = UUID()
        let pairs = ObjectArchetype.generateDuelPairs(count: 5, profileId: id)
        var seen = Set<String>()
        for (a, b) in pairs {
            let key = "\(a.rawValue)-\(b.rawValue)"
            XCTAssertFalse(seen.contains(key), "Duplicate pair found: \(key)")
            seen.insert(key)
        }
    }

    func testApplyDuelResult_blendsWinnerSignature() {
        var vector = ObjectVector.zero
        var affinities: [String: Double] = [:]

        ObjectArchetype.applyDuelResult(
            winner: .toolWorship,
            vector: &vector,
            affinities: &affinities,
            weight: 0.15
        )

        // toolWorship has precision: 0.8, utility: 0.8, technicality: 0.7
        let expectedPrecision = 0.8 * 0.15
        XCTAssertEqual(vector.weights["precision"]!, expectedPrecision, accuracy: 0.001)
        XCTAssertEqual(vector.weights["utility"]!, 0.8 * 0.15, accuracy: 0.001)
        XCTAssertEqual(vector.weights["technicality"]!, 0.7 * 0.15, accuracy: 0.001)
    }

    func testAllArchetypes_haveValidSignatures() {
        for archetype in ObjectArchetype.allCases {
            let sig = archetype.signature
            // All 9 axes should be present
            XCTAssertEqual(sig.axes.count, ObjectAxis.allCases.count,
                "\(archetype.rawValue) should have all 9 axes")
            // Values should be in [-1, 1]
            for (axis, value) in sig.axes {
                XCTAssertGreaterThanOrEqual(value, -1.0,
                    "\(archetype.rawValue).\(axis.rawValue) = \(value) below -1")
                XCTAssertLessThanOrEqual(value, 1.0,
                    "\(archetype.rawValue).\(axis.rawValue) = \(value) above 1")
            }
            // Should have a name, tagline, and 3 keywords
            XCTAssertFalse(sig.name.isEmpty)
            XCTAssertFalse(sig.tagline.isEmpty)
            XCTAssertEqual(sig.keywords.count, 3,
                "\(archetype.rawValue) should have 3 keywords")
        }
    }

    func testArchetypeAffinity_accumulatesAcrossDuels() {
        var vector = ObjectVector.zero
        var affinities: [String: Double] = [:]

        // Apply same archetype 3 times
        for _ in 0..<3 {
            ObjectArchetype.applyDuelResult(
                winner: .quietLuxury,
                vector: &vector,
                affinities: &affinities,
                weight: 0.15
            )
        }

        XCTAssertEqual(affinities["quietLuxury"]!, 0.45, accuracy: 0.001)
        // quietLuxury has precision: 0.7 → 3 × 0.7 × 0.15 = 0.315
        XCTAssertEqual(vector.weights["precision"]!, 0.315, accuracy: 0.001)
    }
}
