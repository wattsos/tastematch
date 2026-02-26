import XCTest
@testable import TasteMatch

final class ScoringServiceTests: XCTestCase {

    // MARK: - Helpers

    private func makeIdentity(
        embedding: StyleEmbedding = .zero,
        antiEmbedding: StyleEmbedding = .zero,
        decisions: Int = 10
    ) -> TasteIdentity {
        var id = TasteIdentity(embedding: embedding, antiEmbedding: antiEmbedding)
        id.countMe = decisions
        return id
    }

    private func minimalSignals() -> StyleSignals {
        StyleSignals(brightness: 0.85, contrast: 0.15, saturation: 0.10, warmth: 0.45,
                     edgeDensity: 0.05, symmetry: 0.90, clutter: 0.05,
                     materialHardness: 0.10, organicVsIndustrial: 0.70,
                     ornateVsMinimal: 0.05, vintageVsModern: 0.35)
    }

    // MARK: - Bounds

    func test_alignmentScoreIsBounded() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity()
        let result   = ScoringService.score(candidate: emb, signals: signals, identity: identity)
        XCTAssertGreaterThanOrEqual(result.alignmentScore, 0)
        XCTAssertLessThanOrEqual(result.alignmentScore, 100)
    }

    func test_tensionScoreIsBounded() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity()
        let result   = ScoringService.score(candidate: emb, signals: signals, identity: identity)
        XCTAssertGreaterThanOrEqual(result.tensionScore, 0)
        XCTAssertLessThanOrEqual(result.tensionScore, 100)
    }

    func test_confidenceIsBounded() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity()
        let result   = ScoringService.score(candidate: emb, signals: signals, identity: identity)
        XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
    }

    func test_riskOfRegretIsBounded() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity()
        let result   = ScoringService.score(candidate: emb, signals: signals, identity: identity)
        XCTAssertGreaterThanOrEqual(result.riskOfRegret, 0.0)
        XCTAssertLessThanOrEqual(result.riskOfRegret, 1.0)
    }

    // MARK: - Alignment Semantics

    func test_perfectMatchProducesHighAlignment() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity(embedding: emb, decisions: 10)
        let result   = ScoringService.score(candidate: emb, signals: signals, identity: identity)
        XCTAssertGreaterThanOrEqual(result.alignmentScore, 65,
            "Same embedding should produce high alignment, got \(result.alignmentScore)")
    }

    func test_zeroIdentityProducesMidAlignment() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity(embedding: .zero, decisions: 0)
        let result   = ScoringService.score(candidate: emb, signals: signals, identity: identity)
        // cosine(candidate, zero) = 0 → alignment ≈ 50
        XCTAssertGreaterThanOrEqual(result.alignmentScore, 30)
        XCTAssertLessThanOrEqual(result.alignmentScore, 70)
    }

    // MARK: - Tension Semantics

    func test_antiEmbeddingMatchingCandidateRaisesTension() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let noAnti   = makeIdentity(embedding: emb, antiEmbedding: .zero, decisions: 10)
        let withAnti = makeIdentity(embedding: emb, antiEmbedding: emb,   decisions: 10)
        let r1 = ScoringService.score(candidate: emb, signals: signals, identity: noAnti)
        let r2 = ScoringService.score(candidate: emb, signals: signals, identity: withAnti)
        XCTAssertGreaterThan(r2.tensionScore, r1.tensionScore,
            "Anti-embedding matching candidate should raise tension")
    }

    func test_zeroAntiEmbeddingProducesZeroTension() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity(embedding: emb, antiEmbedding: .zero)
        let result   = ScoringService.score(candidate: emb, signals: signals, identity: identity)
        XCTAssertEqual(result.tensionScore, 0)
    }

    // MARK: - Confidence

    func test_moreDecisionsIncreaseConfidence() {
        let signals = minimalSignals()
        let emb     = EmbeddingProjector.embed(signals)
        let low     = makeIdentity(decisions: 0)
        let high    = makeIdentity(decisions: 20)
        let r1 = ScoringService.score(candidate: emb, signals: signals, identity: low)
        let r2 = ScoringService.score(candidate: emb, signals: signals, identity: high)
        XCTAssertGreaterThan(r2.confidence, r1.confidence,
            "More decisions → higher confidence")
    }

    // MARK: - Determinism

    func test_scoringIsDeterministic() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity(embedding: emb)
        let r1 = ScoringService.score(candidate: emb, signals: signals, identity: identity)
        let r2 = ScoringService.score(candidate: emb, signals: signals, identity: identity)
        XCTAssertEqual(r1.alignmentScore, r2.alignmentScore)
        XCTAssertEqual(r1.tensionScore,   r2.tensionScore)
        XCTAssertEqual(r1.confidence,     r2.confidence)
    }

    // MARK: - JSON Roundtrip

    func test_tasteEvaluationEncodesAndDecodesCorrectly() throws {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity(embedding: emb)
        var eval     = ScoringService.score(
            candidate: emb, signals: signals, identity: identity,
            category: .sofa
        )
        eval.tasteVote         = .me
        eval.furnitureCategory = .sofa

        let data    = try JSONEncoder().encode(eval)
        let decoded = try JSONDecoder().decode(TasteEvaluation.self, from: data)

        XCTAssertEqual(decoded.id,               eval.id)
        XCTAssertEqual(decoded.alignmentScore,   eval.alignmentScore)
        XCTAssertEqual(decoded.tasteVote,        .me)
        XCTAssertEqual(decoded.furnitureCategory, .sofa)
        XCTAssertEqual(decoded.tensionScore,     eval.tensionScore)
    }

    func test_purchaseConfidenceIsBounded() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity(embedding: emb, decisions: 10)
        let result   = ScoringService.score(candidate: emb, signals: signals, identity: identity)
        XCTAssertGreaterThanOrEqual(result.purchaseConfidence, 0.0)
        XCTAssertLessThanOrEqual(result.purchaseConfidence, 1.0)
    }

    func test_budgetStressScoreIsBounded() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity()
        let context  = EvaluationContext(declaredBudgetMax: 1000, itemPrice: 800)
        let result   = ScoringService.score(candidate: emb, signals: signals, identity: identity, context: context)
        XCTAssertGreaterThanOrEqual(result.budgetStressScore, 0.0)
        XCTAssertLessThanOrEqual(result.budgetStressScore, 1.0)
    }

    func test_overBudgetItemMaxStress() {
        let signals  = minimalSignals()
        let emb      = EmbeddingProjector.embed(signals)
        let identity = makeIdentity()
        // price >> budget → stress should be 1.0
        let context  = EvaluationContext(declaredBudgetMax: 500, itemPrice: 2000)
        let result   = ScoringService.score(candidate: emb, signals: signals, identity: identity, context: context)
        XCTAssertEqual(result.budgetStressScore, 1.0, accuracy: 1e-9)
    }
}
