import XCTest
@testable import TasteMatch

final class ReinforcementServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeCandidate() -> StyleEmbedding {
        EmbeddingProjector.embed(StyleSignals(
            brightness: 0.80, contrast: 0.20, saturation: 0.10, warmth: 0.50,
            edgeDensity: 0.10, symmetry: 0.80, clutter: 0.10,
            materialHardness: 0.15, organicVsIndustrial: 0.65,
            ornateVsMinimal: 0.10, vintageVsModern: 0.30
        ))
    }

    private func ornateCandidate() -> StyleEmbedding {
        EmbeddingProjector.embed(StyleSignals(
            brightness: 0.45, contrast: 0.70, saturation: 0.65, warmth: 0.65,
            edgeDensity: 0.80, symmetry: 0.40, clutter: 0.85,
            materialHardness: 0.60, organicVsIndustrial: 0.35,
            ornateVsMinimal: 0.90, vintageVsModern: 0.70
        ))
    }

    // MARK: - Version

    func test_versionIncrementsOnEveryVote() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()
        for vote in [TasteVote.me, .notMe, .maybe] {
            let updated = ReinforcementService.applyTasteVote(
                vote: vote, candidateEmbedding: candidate, to: identity
            )
            XCTAssertEqual(updated.version, identity.version + 1)
        }
    }

    // MARK: - Me vote

    func test_meVoteMovesEmbeddingTowardCandidate() {
        let identity  = TasteIdentity()   // zero embedding
        let candidate = makeCandidate()
        let updated   = ReinforcementService.applyTasteVote(
            vote: .me, candidateEmbedding: candidate, to: identity
        )
        let cosBefore = StyleEmbedding.zero.cosine(with: candidate)
        let cosAfter  = updated.embedding.cosine(with: candidate)
        XCTAssertGreaterThan(cosAfter, cosBefore,
            "Me vote should move embedding toward candidate")
    }

    func test_meVoteIncrementsCountMe() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()
        let updated   = ReinforcementService.applyTasteVote(
            vote: .me, candidateEmbedding: candidate, to: identity
        )
        XCTAssertEqual(updated.countMe, 1)
        XCTAssertEqual(updated.countNotMe, 0)
        XCTAssertEqual(updated.countMaybe, 0)
    }

    func test_meVoteDoesNotChangeAntiEmbedding() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()
        let updated   = ReinforcementService.applyTasteVote(
            vote: .me, candidateEmbedding: candidate, to: identity
        )
        XCTAssertTrue(updated.antiEmbedding.isZero,
            "Me vote should not modify antiEmbedding")
    }

    // MARK: - Not-me vote

    func test_notMeVotePopulatesAntiEmbedding() {
        let identity  = TasteIdentity()
        let candidate = ornateCandidate()
        let updated   = ReinforcementService.applyTasteVote(
            vote: .notMe, candidateEmbedding: candidate, to: identity
        )
        XCTAssertFalse(updated.antiEmbedding.isZero,
            "Not-me vote should populate antiEmbedding")
        XCTAssertEqual(updated.countNotMe, 1)
    }

    func test_notMeVoteDoesNotChangeMainEmbedding() {
        let identity  = TasteIdentity()
        let candidate = ornateCandidate()
        let updated   = ReinforcementService.applyTasteVote(
            vote: .notMe, candidateEmbedding: candidate, to: identity
        )
        XCTAssertTrue(updated.embedding.isZero,
            "Not-me vote should not change main embedding")
    }

    // MARK: - Maybe vote

    func test_maybeVoteProducesWeakerEmbeddingMoveThanMe() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()
        let afterMe    = ReinforcementService.applyTasteVote(vote: .me,    candidateEmbedding: candidate, to: identity)
        let afterMaybe = ReinforcementService.applyTasteVote(vote: .maybe, candidateEmbedding: candidate, to: identity)
        let cosMe    = afterMe.embedding.cosine(with: candidate)
        let cosMaybe = afterMaybe.embedding.cosine(with: candidate)
        XCTAssertGreaterThan(cosMaybe, StyleEmbedding.zero.cosine(with: candidate),
            "Maybe should move embedding slightly")
        XCTAssertLessThan(cosMaybe, cosMe,
            "Maybe should produce weaker embedding move than me")
    }

    func test_maybeVoteDoesNotChangeAntiEmbedding() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()
        let updated   = ReinforcementService.applyTasteVote(
            vote: .maybe, candidateEmbedding: candidate, to: identity
        )
        XCTAssertTrue(updated.antiEmbedding.isZero,
            "Maybe vote should not modify antiEmbedding")
    }

    // MARK: - Returned vote

    func test_returnedWithQualityDisappointmentUpdatesAntiEmbedding() {
        let identity  = TasteIdentity()
        let candidate = ornateCandidate()
        let (updated, _) = ReinforcementService.applyTasteVote(
            vote: .returned,
            candidateEmbedding: candidate,
            category: .loungeChair,
            returnReason: .qualityDisappointment,
            evaluationId: UUID(),
            to: identity
        )
        XCTAssertFalse(updated.antiEmbedding.isZero,
            "returned + qualityDisappointment should produce an anti-embedding update")
    }

    func test_returnedWithSizeReasonDoesNotChangeEmbedding() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()
        let embBefore  = identity.embedding
        let antiBefore = identity.antiEmbedding

        let (updated, _) = ReinforcementService.applyTasteVote(
            vote: .returned,
            candidateEmbedding: candidate,
            category: .coffeeTable,
            returnReason: .tooLarge,
            evaluationId: UUID(),
            to: identity
        )
        XCTAssertEqual(updated.embedding,     embBefore)
        XCTAssertEqual(updated.antiEmbedding, antiBefore)
    }

    // MARK: - Stability

    func test_stabilityRemainsInRange() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()
        for vote in [TasteVote.me, .notMe, .maybe] {
            let updated = ReinforcementService.applyTasteVote(
                vote: vote, candidateEmbedding: candidate, to: identity
            )
            XCTAssertGreaterThanOrEqual(updated.stability, 0.0)
            XCTAssertLessThanOrEqual(updated.stability, 1.0)
        }
    }

    // MARK: - Learning: me vote increases alignment on rescore

    func test_meVoteIncreasesAlignmentOnRescore() {
        let signals   = StyleSignals(
            brightness: 0.7, contrast: 0.3, saturation: 0.2, warmth: 0.5,
            edgeDensity: 0.2, symmetry: 0.7, clutter: 0.1,
            materialHardness: 0.2, organicVsIndustrial: 0.6,
            ornateVsMinimal: 0.1, vintageVsModern: 0.4
        )
        let candidate = EmbeddingProjector.embed(signals)
        var identity  = TasteIdentity()

        let before = ScoringService.score(candidate: candidate, signals: signals, identity: identity)
        identity   = ReinforcementService.applyTasteVote(vote: .me, candidateEmbedding: candidate, to: identity)
        let after  = ScoringService.score(candidate: candidate, signals: signals, identity: identity)

        XCTAssertGreaterThan(after.alignmentScore, before.alignmentScore,
            "Me vote should increase alignment on rescore")
    }

    func test_notMeVoteIncreasesAntiSignalOnRescore() {
        let signals   = StyleSignals(
            brightness: 0.7, contrast: 0.3, saturation: 0.2, warmth: 0.5,
            edgeDensity: 0.2, symmetry: 0.7, clutter: 0.1,
            materialHardness: 0.2, organicVsIndustrial: 0.6,
            ornateVsMinimal: 0.1, vintageVsModern: 0.4
        )
        let candidate = EmbeddingProjector.embed(signals)
        var identity  = TasteIdentity()

        let before  = ScoringService.score(candidate: candidate, signals: signals, identity: identity)
        identity    = ReinforcementService.applyTasteVote(vote: .notMe, candidateEmbedding: candidate, to: identity)
        let after   = ScoringService.score(candidate: candidate, signals: signals, identity: identity)

        // Tension should increase after not-me vote
        XCTAssertGreaterThan(after.tensionScore, before.tensionScore,
            "Not-me vote should increase tension score on rescore")
    }

    func test_maybeVoteChangesAlignmentMinimally() {
        let signals   = StyleSignals(
            brightness: 0.7, contrast: 0.3, saturation: 0.2, warmth: 0.5,
            edgeDensity: 0.2, symmetry: 0.7, clutter: 0.1,
            materialHardness: 0.2, organicVsIndustrial: 0.6,
            ornateVsMinimal: 0.1, vintageVsModern: 0.4
        )
        let candidate = EmbeddingProjector.embed(signals)
        var identity  = TasteIdentity()

        // Establish the identity first with 5 strong me votes so the embedding
        // is already well-aligned with the candidate. A maybe vote should then
        // produce negligible movement (already near the attractor).
        for _ in 0..<5 {
            identity = ReinforcementService.applyTasteVote(vote: .me, candidateEmbedding: candidate, to: identity)
        }

        let before  = ScoringService.score(candidate: candidate, signals: signals, identity: identity)
        identity    = ReinforcementService.applyTasteVote(vote: .maybe, candidateEmbedding: candidate, to: identity)
        let after   = ScoringService.score(candidate: candidate, signals: signals, identity: identity)

        let delta = abs(after.alignmentScore - before.alignmentScore)
        XCTAssertLessThan(delta, 5,
            "Maybe on an established identity should barely move alignment, got \(delta)")
    }
}
