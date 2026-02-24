import XCTest
@testable import TasteMatch

final class ReinforcementServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeIdentity(weights: [String: Double]) -> TasteIdentity {
        TasteIdentity(vector: TasteVector(weights: weights))
    }

    private func makeCandidate(weights: [String: Double]) -> TasteVector {
        TasteVector(weights: weights)
    }

    // MARK: - Version increment

    func test_versionIncrementsOnEveryAction() {
        let identity  = makeIdentity(weights: ["minimalist": 0.5])
        let candidate = makeCandidate(weights: ["minimalist": 0.8])
        for action in [TasteAction.bought, .rejected, .regretted] {
            let updated = ReinforcementService.apply(action: action, candidateVector: candidate, to: identity)
            XCTAssertEqual(updated.version, identity.version + 1, "Version should increment for .\(action)")
        }
    }

    // MARK: - Bought nudges toward candidate

    func test_boughtIncreasesRelevantWeight() {
        let identity  = makeIdentity(weights: ["industrial": 0.2])
        let candidate = makeCandidate(weights: ["industrial": 0.8])
        let updated   = ReinforcementService.apply(action: .bought, candidateVector: candidate, to: identity)
        XCTAssertGreaterThan(
            updated.vector.weights["industrial", default: 0.0],
            identity.vector.weights["industrial", default: 0.0],
            "Bought should increase weight toward candidate"
        )
    }

    // MARK: - Rejected nudges away from candidate

    func test_rejectedDecreasesRelevantWeight() {
        let identity  = makeIdentity(weights: ["bohemian": 0.5])
        let candidate = makeCandidate(weights: ["bohemian": 0.8])
        let updated   = ReinforcementService.apply(action: .rejected, candidateVector: candidate, to: identity)
        XCTAssertLessThan(
            updated.vector.weights["bohemian", default: 0.0],
            identity.vector.weights["bohemian", default: 0.0],
            "Rejected should decrease weight away from candidate"
        )
    }

    // MARK: - Regretted nudges away more than rejected

    func test_regrettedDecreasesMoreThanRejected() {
        let identity   = makeIdentity(weights: ["artDeco": 0.5])
        let candidate  = makeCandidate(weights: ["artDeco": 0.8])
        let afterReject  = ReinforcementService.apply(action: .rejected,  candidateVector: candidate, to: identity)
        let afterRegret  = ReinforcementService.apply(action: .regretted, candidateVector: candidate, to: identity)
        XCTAssertLessThan(
            afterRegret.vector.weights["artDeco", default: 0.0],
            afterReject.vector.weights["artDeco", default: 0.0],
            "Regretted should move weight further away than rejected"
        )
    }

    // MARK: - Weights stay clamped

    func test_weightsRemainClamped() {
        let identity  = makeIdentity(weights: ["scandinavian": 0.95])
        let candidate = makeCandidate(weights: ["scandinavian": 1.0])
        let updated   = ReinforcementService.apply(action: .bought, candidateVector: candidate, to: identity)
        for (_, weight) in updated.vector.weights {
            XCTAssertLessThanOrEqual(weight,  1.0, "Weight must not exceed 1.0")
            XCTAssertGreaterThanOrEqual(weight, -1.0, "Weight must not go below -1.0")
        }
    }

    func test_negativeWeightsClampedAtMinusOne() {
        let identity  = makeIdentity(weights: ["coastal": -0.95])
        let candidate = makeCandidate(weights: ["coastal": 1.0])
        let updated   = ReinforcementService.apply(action: .regretted, candidateVector: candidate, to: identity)
        for (_, weight) in updated.vector.weights {
            XCTAssertGreaterThanOrEqual(weight, -1.0, "Weight must not go below -1.0")
        }
    }

    // MARK: - Low-signal candidate is ignored

    func test_lowAbsWeightCandidateNotApplied() {
        // candidate weight is ≤ 0.1, should be ignored
        let identity  = makeIdentity(weights: ["rustic": 0.4])
        let candidate = makeCandidate(weights: ["rustic": 0.05])
        let updated   = ReinforcementService.apply(action: .bought, candidateVector: candidate, to: identity)
        XCTAssertEqual(
            updated.vector.weights["rustic", default: 0.0],
            identity.vector.weights["rustic", default: 0.0],
            accuracy: 0.001,
            "Weights with abs(value) ≤ 0.1 should not be updated"
        )
    }

    // MARK: - Stability is in range

    func test_stabilityIsInRange() {
        let identity  = makeIdentity(weights: ["minimalist": 0.6, "scandinavian": 0.4])
        let candidate = makeCandidate(weights: ["minimalist": 0.9, "scandinavian": 0.7])
        let updated   = ReinforcementService.apply(action: .bought, candidateVector: candidate, to: identity)
        XCTAssertGreaterThanOrEqual(updated.stability, 0.0)
        XCTAssertLessThanOrEqual(updated.stability, 1.0)
    }
}
