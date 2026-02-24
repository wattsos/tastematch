import XCTest
@testable import TasteMatch

final class ScoringServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeIdentity(weights: [String: Double]) -> TasteIdentity {
        TasteIdentity(vector: TasteVector(weights: weights))
    }

    private func makeCandidate(weights: [String: Double]) -> TasteVector {
        TasteVector(weights: weights)
    }

    // MARK: - Alignment bounds

    func test_alignmentScore_isBoundedBetween0And100() {
        let identity  = makeIdentity(weights:  ["minimalist": 1.0, "bohemian": -1.0])
        let candidate = makeCandidate(weights: ["minimalist": 1.0, "bohemian": -1.0])
        let result = ScoringService.score(candidateVector: candidate, identity: identity)
        XCTAssertGreaterThanOrEqual(result.alignmentScore, 0)
        XCTAssertLessThanOrEqual(result.alignmentScore, 100)
    }

    func test_perfectMatchProducesHighAlignment() {
        let weights: [String: Double] = ["minimalist": 1.0, "scandinavian": 0.8]
        let identity  = makeIdentity(weights: weights)
        let candidate = makeCandidate(weights: weights)
        let result = ScoringService.score(candidateVector: candidate, identity: identity)
        XCTAssertGreaterThanOrEqual(result.alignmentScore, 70,
            "Identical vectors should produce high alignment (≥70), got \(result.alignmentScore)")
    }

    func test_oppositeVectorsProduceLowAlignment() {
        let identity  = makeIdentity(weights:  ["minimalist": 1.0])
        let candidate = makeCandidate(weights: ["minimalist": -1.0])
        let result = ScoringService.score(candidateVector: candidate, identity: identity)
        XCTAssertLessThan(result.alignmentScore, 50,
            "Opposite vectors should produce low alignment, got \(result.alignmentScore)")
    }

    // MARK: - Confidence bounds

    func test_confidenceIsBoundedBetween0And1() {
        let identity  = makeIdentity(weights:  ["rustic": 0.5])
        let candidate = makeCandidate(weights: ["rustic": 0.5])
        let result = ScoringService.score(candidateVector: candidate, identity: identity)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
    }

    // MARK: - Avoid hit reduces alignment

    func test_avoidHitReducesAlignment() {
        // Identity avoids "industrial" (weight < -0.2)
        let identity = makeIdentity(weights: ["industrial": -0.5, "minimalist": 0.8])
        // Candidate strongly signals "industrial"
        let candidate = makeCandidate(weights: ["industrial": 0.9, "minimalist": 0.8])

        let withAvoid    = ScoringService.score(candidateVector: candidate, identity: identity)

        // Baseline: identity doesn't avoid industrial
        let identityNoAvoid = makeIdentity(weights: ["industrial": 0.5, "minimalist": 0.8])
        let withoutAvoid    = ScoringService.score(candidateVector: candidate, identity: identityNoAvoid)

        XCTAssertLessThan(withAvoid.alignmentScore, withoutAvoid.alignmentScore,
            "Avoid hit should reduce alignment score")
    }

    // MARK: - Tension flags appear on avoid hit

    func test_tensionFlagsAppearWhenAvoidHitOccurs() {
        let identity  = makeIdentity(weights:  ["bohemian": -0.6, "industrial": 0.5])
        // candidate influences "bohemian" (weight > 0.3)
        let candidate = makeCandidate(weights: ["bohemian": 0.8])
        let result = ScoringService.score(candidateVector: candidate, identity: identity)
        XCTAssertFalse(result.tensionFlags.isEmpty, "Should have tension flags when avoid hit occurs")
        XCTAssertTrue(result.tensionFlags.contains("bohemian"))
    }

    func test_noTensionFlagsWhenNoAvoidHit() {
        let identity  = makeIdentity(weights:  ["minimalist": 0.7])
        let candidate = makeCandidate(weights: ["minimalist": 0.9])
        let result = ScoringService.score(candidateVector: candidate, identity: identity)
        XCTAssertTrue(result.tensionFlags.isEmpty, "No tension flags when no avoid hits")
    }

    // MARK: - Determinism

    func test_scoringIsDeterministic() {
        let identity  = makeIdentity(weights:  ["japandi": 0.6, "industrial": -0.4])
        let candidate = makeCandidate(weights: ["japandi": 0.7, "industrial": 0.2])
        let r1 = ScoringService.score(candidateVector: candidate, identity: identity)
        let r2 = ScoringService.score(candidateVector: candidate, identity: identity)
        XCTAssertEqual(r1.alignmentScore, r2.alignmentScore)
        XCTAssertEqual(r1.confidence, r2.confidence)
        XCTAssertEqual(r1.tensionFlags, r2.tensionFlags)
    }

    // MARK: - Risk of regret bounds

    func test_riskOfRegretIsBounded() {
        let identity  = makeIdentity(weights:  ["bohemian": -0.5])
        let candidate = makeCandidate(weights: ["bohemian": 0.9])
        let result = ScoringService.score(candidateVector: candidate, identity: identity)
        XCTAssertGreaterThanOrEqual(result.riskOfRegret, 0.0)
        XCTAssertLessThanOrEqual(result.riskOfRegret, 1.0)
    }
}
