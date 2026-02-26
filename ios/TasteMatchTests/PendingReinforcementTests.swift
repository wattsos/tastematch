import XCTest
@testable import TasteMatch

final class PendingReinforcementTests: XCTestCase {

    // MARK: - Helpers

    private func makeCandidate() -> StyleEmbedding {
        EmbeddingProjector.embed(StyleSignals(
            brightness: 0.80, contrast: 0.20, saturation: 0.10, warmth: 0.50,
            edgeDensity: 0.10, symmetry: 0.80, clutter: 0.10,
            materialHardness: 0.15, organicVsIndustrial: 0.65,
            ornateVsMinimal: 0.10, vintageVsModern: 0.30
        ))
    }

    // MARK: - FurnitureCategory

    func test_sofaIsAnchor() {
        XCTAssertTrue(FurnitureCategory.sofa.isAnchor)
        XCTAssertTrue(FurnitureCategory.sectional.isAnchor)
    }

    func test_nonSofaIsNotAnchor() {
        let nonAnchors: [FurnitureCategory] = [.coffeeTable, .loungeChair, .rug, .mediaConsole, .other]
        for cat in nonAnchors {
            XCTAssertFalse(cat.isAnchor, "\(cat) should not be an anchor")
        }
    }

    func test_anchorMultiplierIsHigherForAnchors() {
        XCTAssertGreaterThan(FurnitureCategory.sofa.anchorMultiplier, FurnitureCategory.other.anchorMultiplier)
        XCTAssertEqual(FurnitureCategory.sofa.anchorMultiplier, 1.8, accuracy: 1e-9)
        XCTAssertEqual(FurnitureCategory.other.anchorMultiplier, 1.0, accuracy: 1e-9)
    }

    // MARK: - Anchor Vote Creates Pending Record

    func test_anchorMeVoteCreatesPendingRecord() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()
        let evalId    = UUID()

        let (_, pending) = ReinforcementService.applyTasteVote(
            vote: .me,
            candidateEmbedding: candidate,
            category: .sofa,
            returnReason: nil,
            evaluationId: evalId,
            to: identity
        )

        XCTAssertNotNil(pending, "Sofa me-vote should create a pending record")
        XCTAssertEqual(pending?.evaluationId, evalId)
        XCTAssertEqual(pending?.vote, .me)
        XCTAssertEqual(pending?.category, .sofa)
    }

    func test_anchorNotMeVoteCreatesPendingRecord() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()
        let evalId    = UUID()

        let (_, pending) = ReinforcementService.applyTasteVote(
            vote: .notMe,
            candidateEmbedding: candidate,
            category: .sectional,
            returnReason: nil,
            evaluationId: evalId,
            to: identity
        )

        XCTAssertNotNil(pending, "Sectional notMe-vote should create a pending record")
        XCTAssertEqual(pending?.vote, .notMe)
    }

    func test_anchorMeVoteDoesNotChangeEmbeddingImmediately() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()

        let (updated, _) = ReinforcementService.applyTasteVote(
            vote: .me,
            candidateEmbedding: candidate,
            category: .sofa,
            returnReason: nil,
            evaluationId: UUID(),
            to: identity
        )

        XCTAssertTrue(updated.embedding.isZero,
            "Anchor me-vote should NOT change embedding immediately")
    }

    // MARK: - Non-Anchor Vote Applies Immediately

    func test_nonAnchorMeVoteAppliesImmediatelyNoPending() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()

        let (updated, pending) = ReinforcementService.applyTasteVote(
            vote: .me,
            candidateEmbedding: candidate,
            category: .coffeeTable,
            returnReason: nil,
            evaluationId: UUID(),
            to: identity
        )

        XCTAssertNil(pending, "Non-anchor should not create pending record")
        XCTAssertFalse(updated.embedding.isZero, "Non-anchor me-vote should update embedding immediately")
    }

    // MARK: - Finalize Pending Applies Amplified Reinforcement

    func test_finalizeAppliesAnchorMultiplier() {
        let candidate = makeCandidate()
        let evalId    = UUID()

        // Start from an identity already pointing in a *different* direction
        // so the blend weight actually changes the resulting cosine similarity.
        let oppositeSignals = StyleSignals(
            brightness: 0.10, contrast: 0.90, saturation: 0.80, warmth: 0.20,
            edgeDensity: 0.95, symmetry: 0.10, clutter: 0.90,
            materialHardness: 0.85, organicVsIndustrial: 0.15,
            ornateVsMinimal: 0.95, vintageVsModern: 0.80
        )
        var baseIdentity = TasteIdentity()
        baseIdentity.embedding = EmbeddingProjector.embed(oppositeSignals)

        // Non-anchor (coffeeTable): immediate apply with α = 0.18
        let (nonAnchorUpdated, _) = ReinforcementService.applyTasteVote(
            vote: .me,
            candidateEmbedding: candidate,
            category: .coffeeTable,
            returnReason: nil,
            evaluationId: evalId,
            to: baseIdentity
        )
        let cosNonAnchor = nonAnchorUpdated.embedding.cosine(with: candidate)

        // Anchor (sofa): zero immediate change → finalize with α × 1.8 = 0.324
        // For finalize we start from the same base (anchorPre's embedding = base).
        let (anchorPre, pending) = ReinforcementService.applyTasteVote(
            vote: .me,
            candidateEmbedding: candidate,
            category: .sofa,
            returnReason: nil,
            evaluationId: evalId,
            to: baseIdentity
        )
        let anchorFinal = ReinforcementService.finalizePending(pending!, to: anchorPre)
        let cosAnchor = anchorFinal.embedding.cosine(with: candidate)

        XCTAssertGreaterThan(cosAnchor, cosNonAnchor,
            "Finalized anchor (weight 0.324) should align more toward candidate than non-anchor immediate (weight 0.18)")
    }

    // MARK: - Purchase Confidence Bounds

    func test_purchaseConfidenceIsInBounds() {
        let signals  = StyleSignals(
            brightness: 0.7, contrast: 0.3, saturation: 0.2, warmth: 0.5,
            edgeDensity: 0.2, symmetry: 0.7, clutter: 0.1,
            materialHardness: 0.2, organicVsIndustrial: 0.6,
            ornateVsMinimal: 0.1, vintageVsModern: 0.4
        )
        let candidate = EmbeddingProjector.embed(signals)
        let identity  = TasteIdentity()

        for category in FurnitureCategory.allCases {
            let result = ScoringService.score(
                candidate: candidate, signals: signals, identity: identity,
                category: category
            )
            XCTAssertGreaterThanOrEqual(result.purchaseConfidence, 0.0,
                "purchaseConfidence should be ≥ 0 for \(category)")
            XCTAssertLessThanOrEqual(result.purchaseConfidence, 1.0,
                "purchaseConfidence should be ≤ 1 for \(category)")
        }
    }

    func test_purchaseConfidenceWithContextIsInBounds() {
        let signals  = StyleSignals(
            brightness: 0.7, contrast: 0.3, saturation: 0.2, warmth: 0.5,
            edgeDensity: 0.2, symmetry: 0.7, clutter: 0.1,
            materialHardness: 0.2, organicVsIndustrial: 0.6,
            ornateVsMinimal: 0.1, vintageVsModern: 0.4
        )
        let candidate = EmbeddingProjector.embed(signals)
        let identity  = TasteIdentity()
        let context   = EvaluationContext(
            declaredBudgetMin: 1000, declaredBudgetMax: 2000,
            roomWidth: 15, roomLength: 20,
            itemWidth: 8, itemDepth: 3.5,
            itemPrice: 1800
        )
        let result = ScoringService.score(
            candidate: candidate, signals: signals, identity: identity,
            context: context
        )
        XCTAssertGreaterThanOrEqual(result.purchaseConfidence, 0.0)
        XCTAssertLessThanOrEqual(result.purchaseConfidence, 1.0)
        XCTAssertGreaterThanOrEqual(result.budgetStressScore, 0.0)
        XCTAssertLessThanOrEqual(result.budgetStressScore, 1.0)
        XCTAssertGreaterThanOrEqual(result.scaleFitScore, 0.0)
        XCTAssertLessThanOrEqual(result.scaleFitScore, 1.0)
    }

    // MARK: - Return Reason

    func test_returnedWithStyleReasonUpdatesAntiEmbedding() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()

        let (updated, _) = ReinforcementService.applyTasteVote(
            vote: .returned,
            candidateEmbedding: candidate,
            category: .loungeChair,
            returnReason: .qualityDisappointment,
            evaluationId: UUID(),
            to: identity
        )

        XCTAssertFalse(updated.antiEmbedding.isZero,
            "returned + qualityDisappointment should populate antiEmbedding")
    }

    func test_returnedWithSizeReasonNoStyleChange() {
        let identity  = TasteIdentity()
        let candidate = makeCandidate()

        let (updated, _) = ReinforcementService.applyTasteVote(
            vote: .returned,
            candidateEmbedding: candidate,
            category: .sofa,
            returnReason: .tooLarge,
            evaluationId: UUID(),
            to: identity
        )

        XCTAssertTrue(updated.antiEmbedding.isZero,
            "returned + tooLarge should NOT change antiEmbedding (size is not style)")
    }

    func test_returnedVoteAffectsStyleLearningFlag() {
        XCTAssertTrue(ReturnReason.qualityDisappointment.affectsStyleLearning)
        XCTAssertTrue(ReturnReason.colorMismatch.affectsStyleLearning)
        XCTAssertTrue(ReturnReason.materialMismatch.affectsStyleLearning)
        XCTAssertTrue(ReturnReason.spaceConflict.affectsStyleLearning)
        XCTAssertFalse(ReturnReason.tooLarge.affectsStyleLearning)
        XCTAssertFalse(ReturnReason.tooSmall.affectsStyleLearning)
        XCTAssertFalse(ReturnReason.priceDiscomfort.affectsStyleLearning)
        XCTAssertFalse(ReturnReason.other.affectsStyleLearning)
    }

    // MARK: - Pending Record Properties

    func test_pendingUnlockAtIs14DaysFromCreation() {
        let record = PendingReinforcement.make(
            for: UUID(),
            identityVersion: 1,
            candidateEmbedding: makeCandidate(),
            vote: .me,
            category: .sofa
        )
        let expectedUnlock = record.createdAt.addingTimeInterval(PendingReinforcement.holdDuration)
        XCTAssertEqual(record.unlockAt.timeIntervalSince1970,
                       expectedUnlock.timeIntervalSince1970,
                       accuracy: 1.0)
    }

    func test_freshPendingRecordIsNotReady() {
        let record = PendingReinforcement.make(
            for: UUID(),
            identityVersion: 0,
            candidateEmbedding: makeCandidate(),
            vote: .me,
            category: .sofa
        )
        XCTAssertFalse(record.isReady, "Freshly created pending record should not be ready")
    }

    // MARK: - Enum Codable

    func test_furnitureCategoryCodable() throws {
        for cat in FurnitureCategory.allCases {
            let data    = try JSONEncoder().encode(cat)
            let decoded = try JSONDecoder().decode(FurnitureCategory.self, from: data)
            XCTAssertEqual(decoded, cat)
        }
    }

    func test_returnReasonCodable() throws {
        for reason in ReturnReason.allCases {
            let data    = try JSONEncoder().encode(reason)
            let decoded = try JSONDecoder().decode(ReturnReason.self, from: data)
            XCTAssertEqual(decoded, reason)
        }
    }

    func test_tasteVoteWithReturnedCodable() throws {
        let vote: TasteVote = .returned
        let data    = try JSONEncoder().encode(vote)
        let decoded = try JSONDecoder().decode(TasteVote.self, from: data)
        XCTAssertEqual(decoded, .returned)
    }

    func test_tasteEvaluationWithNewFieldsRoundtrips() throws {
        let signals   = StyleSignals(
            brightness: 0.7, contrast: 0.3, saturation: 0.2, warmth: 0.5,
            edgeDensity: 0.2, symmetry: 0.7, clutter: 0.1,
            materialHardness: 0.2, organicVsIndustrial: 0.6,
            ornateVsMinimal: 0.1, vintageVsModern: 0.4
        )
        let candidate = EmbeddingProjector.embed(signals)
        let identity  = TasteIdentity()
        var eval = ScoringService.score(
            candidate: candidate, signals: signals, identity: identity,
            category: .sofa, context: EvaluationContext(itemPrice: 1500)
        )
        eval.tasteVote         = .returned
        eval.returnReason      = .colorMismatch
        eval.furnitureCategory = .sofa

        let data    = try JSONEncoder().encode(eval)
        let decoded = try JSONDecoder().decode(TasteEvaluation.self, from: data)

        XCTAssertEqual(decoded.tasteVote,         .returned)
        XCTAssertEqual(decoded.returnReason,      .colorMismatch)
        XCTAssertEqual(decoded.furnitureCategory, .sofa)
        XCTAssertEqual(decoded.alignmentScore,    eval.alignmentScore)
    }
}
