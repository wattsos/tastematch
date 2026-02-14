import XCTest
@testable import TasteMatch

final class ProfileNamingTests: XCTestCase {

    // MARK: - Determinism: Same vector → same basisHash + same name

    func testSameVector_producesSameHashAndName() {
        let vectorA = makeVector(["scandinavian": 0.85, "japandi": 0.4])
        let vectorB = makeVector(["scandinavian": 0.85, "japandi": 0.4])

        let profile = makeEmptyNameProfile()
        let resultA = ProfileNamingEngine.resolve(vector: vectorA, swipeCount: 0, existingProfile: profile)
        let resultB = ProfileNamingEngine.resolve(vector: vectorB, swipeCount: 0, existingProfile: profile)

        XCTAssertEqual(resultA.basisHash, resultB.basisHash)
        XCTAssertEqual(resultA.name, resultB.name)
    }

    // MARK: - Small perturbation below threshold → name unchanged

    func testSmallPerturbation_keepsName() {
        let vector = makeVector(["scandinavian": 0.85, "japandi": 0.4])
        let profile = makeEmptyNameProfile()

        // Generate initial name
        let initial = ProfileNamingEngine.resolve(vector: vector, swipeCount: 0, existingProfile: profile)
        XCTAssertTrue(initial.didUpdate)

        // Create a named profile with the initial result
        var namedProfile = profile
        namedProfile.profileName = initial.name
        namedProfile.profileNameVersion = initial.version
        namedProfile.profileNameBasisHash = initial.basisHash
        namedProfile.previousNames = initial.previousNames

        // Tiny perturbation — same buckets, same top influences
        let perturbed = makeVector(["scandinavian": 0.86, "japandi": 0.39])
        let second = ProfileNamingEngine.resolve(vector: perturbed, swipeCount: 0, existingProfile: namedProfile)

        XCTAssertEqual(second.name, initial.name, "Small perturbation should not change name")
        XCTAssertFalse(second.didUpdate)
        XCTAssertEqual(second.version, initial.version)
    }

    // MARK: - Meaningful axis shift → name updates and version increments

    func testMeaningfulShift_updatesNameAndVersion() {
        let vector = makeVector(["scandinavian": 0.85])
        let profile = makeEmptyNameProfile()

        let initial = ProfileNamingEngine.resolve(vector: vector, swipeCount: 0, existingProfile: profile)

        var namedProfile = profile
        namedProfile.profileName = initial.name
        namedProfile.profileNameVersion = initial.version
        namedProfile.profileNameBasisHash = initial.basisHash

        // Dramatic shift to a completely different style
        let shifted = makeVector(["industrial": 0.9, "artDeco": 0.6])
        let updated = ProfileNamingEngine.resolve(vector: shifted, swipeCount: 14, existingProfile: namedProfile)

        XCTAssertTrue(updated.didUpdate)
        XCTAssertNotEqual(updated.name, initial.name, "Meaningful shift should produce different name")
        XCTAssertEqual(updated.version, initial.version + 1)
        XCTAssertTrue(updated.previousNames.contains(initial.name))
    }

    // MARK: - previousNames max length enforced

    func testPreviousNames_cappedAtThree() {
        var profile = makeEmptyNameProfile()

        // Evolve through 5 different vectors
        let vectors: [[String: Double]] = [
            ["scandinavian": 0.9],
            ["industrial": 0.9],
            ["bohemian": 0.9],
            ["artDeco": 0.9],
            ["rustic": 0.9],
        ]

        for weights in vectors {
            let vector = makeVector(weights)
            let result = ProfileNamingEngine.resolve(vector: vector, swipeCount: 14, existingProfile: profile)
            profile.profileName = result.name
            profile.profileNameVersion = result.version
            profile.profileNameBasisHash = result.basisHash
            profile.previousNames = result.previousNames
        }

        XCTAssertLessThanOrEqual(profile.previousNames.count, 3, "previousNames should be capped at 3")
    }

    // MARK: - Deterministic descriptor selection

    func testDescriptorSelection_isDeterministic() {
        let scores = AxisMapping.computeAxisScores(from: makeVector(["industrial": 0.9]))
        let hash = "test|hash|value"

        let desc1 = StructuralDescriptorResolver.resolve(axisScores: scores, basisHash: hash)
        let desc2 = StructuralDescriptorResolver.resolve(axisScores: scores, basisHash: hash)

        XCTAssertEqual(desc1, desc2, "Same inputs must produce same descriptor")
    }

    // MARK: - Axis scores computation

    func testAxisScores_scandinavianProfile() {
        let vector = makeVector(["scandinavian": 1.0])
        let scores = AxisMapping.computeAxisScores(from: vector)

        XCTAssertEqual(scores.dominantAxis, .minimalOrnate, "Scandinavian should be minimal-dominant")
        XCTAssertLessThan(scores.minimalOrnate, 0, "Scandinavian should score negative (minimal)")
        XCTAssertLessThan(scores.lightDark, 0, "Scandinavian should score negative (light)")
    }

    func testAxisScores_industrialProfile() {
        let vector = makeVector(["industrial": 1.0])
        let scores = AxisMapping.computeAxisScores(from: vector)

        XCTAssertEqual(scores.dominantAxis, .organicIndustrial, "Industrial should be organicIndustrial-dominant")
        XCTAssertGreaterThan(scores.organicIndustrial, 0, "Industrial should score positive")
    }

    // MARK: - Description generation

    func testDescription_neverEmpty() {
        for tag in TasteEngine.CanonicalTag.allCases {
            let vector = makeVector([String(describing: tag): 0.9])
            let scores = AxisMapping.computeAxisScores(from: vector)
            let desc = DescriptionGenerator.generate(from: scores)
            XCTAssertFalse(desc.isEmpty, "Description should never be empty for \(tag)")
            XCTAssertTrue(desc.hasSuffix("."), "Description should end with period for \(tag)")
        }
    }

    // MARK: - Profile name is always two words

    func testProfileName_alwaysTwoWords() {
        for tag in TasteEngine.CanonicalTag.allCases {
            let vector = makeVector([String(describing: tag): 0.9])
            let scores = AxisMapping.computeAxisScores(from: vector)
            let hash = BasisHashBuilder.build(axisScores: scores, vector: vector, swipeCount: 0)
            let name = ProfileNameGenerator.generate(from: scores, basisHash: hash)
            let words = name.split(separator: " ")
            XCTAssertEqual(words.count, 2, "Profile name '\(name)' should be exactly two words for \(tag)")
        }
    }

    // MARK: - Evolution gate respects thresholds

    func testEvolutionGate_blocksWithoutThreshold() {
        // Create a vector where separation < 0.15 and swipeCount < 14
        // All tags at equal weight → separation = 0
        var weights: [String: Double] = [:]
        for tag in TasteEngine.CanonicalTag.allCases {
            weights[String(describing: tag)] = 0.5
        }
        let vector = TasteVector(weights: weights)
        let profile = makeEmptyNameProfile()

        let initial = ProfileNamingEngine.resolve(vector: vector, swipeCount: 0, existingProfile: profile)

        var namedProfile = profile
        namedProfile.profileName = initial.name
        namedProfile.profileNameVersion = initial.version
        namedProfile.profileNameBasisHash = initial.basisHash

        // Slightly different equal-weight vector — hash may change but threshold not met
        var weights2 = weights
        weights2["scandinavian"] = 0.51
        let vector2 = TasteVector(weights: weights2)

        let second = ProfileNamingEngine.resolve(vector: vector2, swipeCount: 3, existingProfile: namedProfile)

        // With all-equal weights, separation is ~0 and swipeCount=3 < 14
        // But separation of 0.51 vs 0.50 = 0.01 after normalization... still < 0.15
        // confidenceLevel with swipeCount=3 and confidence > 0.2 (all tags significant) → "Developing"
        // So shouldEvolve: Strong? No. swipeCount>=14? No. separation>=0.15? No.
        // But confidence > 0.2 means all tags are significant, so swipeCount >= 7 check...
        // Actually confidenceLevel checks swipeCount >= 7 → no (3 < 7), but checks confidence > 0.2 → yes (10/10 = 1.0 > 0.2)
        // So confidence level = "Developing", not "Strong"
        // shouldEvolve: "Strong"? No. >=14? No. separation>=0.15? No.
        // Result: should NOT evolve
        if second.basisHash != initial.basisHash {
            // Hash changed but threshold not met → name should stay
            XCTAssertEqual(second.name, initial.name, "Name should not evolve without meeting threshold")
            XCTAssertFalse(second.didUpdate)
        }
        // If hash didn't change, name stays anyway — also correct
    }

    // MARK: - Backward-compatible Codable

    func testTasteProfile_decodesWithoutNamingFields() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "tags": [],
            "story": "Test",
            "signals": []
        }
        """
        let data = json.data(using: .utf8)!
        let profile = try JSONDecoder().decode(TasteProfile.self, from: data)

        XCTAssertEqual(profile.profileName, "")
        XCTAssertEqual(profile.profileNameVersion, 0)
        XCTAssertNil(profile.profileNameUpdatedAt)
        XCTAssertEqual(profile.profileNameBasisHash, "")
        XCTAssertTrue(profile.previousNames.isEmpty)
    }

    // MARK: - displayName prefers profileName over canonical label

    func testDisplayName_prefersProfileName() {
        var profile = TasteProfile(
            tags: [TasteTag(key: "artDeco", label: "Art Deco", confidence: 0.9)],
            story: "Test",
            signals: []
        )
        // Before naming: falls back to canonical label
        XCTAssertEqual(profile.displayName, "Art Deco")

        // After naming: returns generated name
        profile.profileName = "Berlin Industrial"
        XCTAssertEqual(profile.displayName, "Berlin Industrial")
    }

    func testDisplayName_neverReturnsCanonicalLabel_whenNamed() {
        let canonicalLabels: Set<String> = [
            "Mid-Century Modern", "Scandinavian", "Industrial", "Bohemian",
            "Minimalist", "Traditional", "Coastal", "Rustic", "Art Deco", "Japandi"
        ]

        for tag in TasteEngine.CanonicalTag.allCases {
            var profile = TasteProfile(
                tags: [TasteTag(key: String(describing: tag), label: tag.rawValue, confidence: 0.9)],
                story: "Test",
                signals: []
            )
            ProfileNamingEngine.applyInitialNaming(to: &profile)

            XCTAssertFalse(profile.profileName.isEmpty, "profileName should be set for \(tag)")
            XCTAssertFalse(canonicalLabels.contains(profile.displayName),
                           "displayName '\(profile.displayName)' should not be a canonical label for \(tag)")
        }
    }

    func testApplyInitialNaming_setsAllFields() {
        var profile = makeEmptyNameProfile()
        XCTAssertTrue(profile.profileName.isEmpty)

        ProfileNamingEngine.applyInitialNaming(to: &profile)

        XCTAssertFalse(profile.profileName.isEmpty)
        XCTAssertEqual(profile.profileNameVersion, 1)
        XCTAssertFalse(profile.profileNameBasisHash.isEmpty)
        XCTAssertNotNil(profile.profileNameUpdatedAt)
    }

    // MARK: - Helpers

    private func makeVector(_ weights: [String: Double]) -> TasteVector {
        var all: [String: Double] = [:]
        for tag in TasteEngine.CanonicalTag.allCases {
            all[String(describing: tag)] = 0.0
        }
        for (k, v) in weights {
            all[k] = v
        }
        return TasteVector(weights: all)
    }

    private func makeEmptyNameProfile() -> TasteProfile {
        TasteProfile(
            tags: [TasteTag(key: "scandinavian", label: "Scandinavian", confidence: 0.85)],
            story: "Test story",
            signals: [Signal(key: "palette_temperature", value: "cool")]
        )
    }
}
