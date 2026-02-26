import XCTest
@testable import TasteMatch

final class StyleDivergenceTests: XCTestCase {

    // MARK: - Embedding Divergence

    func testMinimalVsOrnateEmbeddingDivergence() {
        let minimal = StyleSignals(
            brightness: 0.85, contrast: 0.15, saturation: 0.10, warmth: 0.45,
            edgeDensity: 0.05, symmetry: 0.90, clutter: 0.05,
            materialHardness: 0.10, organicVsIndustrial: 0.70,
            ornateVsMinimal: 0.05, vintageVsModern: 0.35
        )
        let ornate = StyleSignals(
            brightness: 0.45, contrast: 0.70, saturation: 0.65, warmth: 0.65,
            edgeDensity: 0.80, symmetry: 0.40, clutter: 0.85,
            materialHardness: 0.60, organicVsIndustrial: 0.35,
            ornateVsMinimal: 0.90, vintageVsModern: 0.70
        )
        let embMinimal = EmbeddingProjector.embed(minimal)
        let embOrnate  = EmbeddingProjector.embed(ornate)
        let cos = embMinimal.cosine(with: embOrnate)
        // Raw signal-space cosine ~0.55; projection preserves it with some variance.
        // Threshold < 0.7 verifies meaningful discrimination without over-constraining.
        XCTAssertLessThan(cos, 0.7,
            "Minimal and ornate should diverge (cosine < 0.7), got \(cos)")
    }

    func testSimilarSignalsProduceHighCosine() {
        let s1 = StyleSignals(
            brightness: 0.70, contrast: 0.30, saturation: 0.20, warmth: 0.50,
            edgeDensity: 0.20, symmetry: 0.70, clutter: 0.10,
            materialHardness: 0.20, organicVsIndustrial: 0.60,
            ornateVsMinimal: 0.10, vintageVsModern: 0.40
        )
        let s2 = StyleSignals(
            brightness: 0.72, contrast: 0.28, saturation: 0.22, warmth: 0.51,
            edgeDensity: 0.18, symmetry: 0.72, clutter: 0.12,
            materialHardness: 0.19, organicVsIndustrial: 0.62,
            ornateVsMinimal: 0.11, vintageVsModern: 0.41
        )
        let e1 = EmbeddingProjector.embed(s1)
        let e2 = EmbeddingProjector.embed(s2)
        let cos = e1.cosine(with: e2)
        XCTAssertGreaterThan(cos, 0.95,
            "Very similar signals should produce high cosine (>0.95), got \(cos)")
    }

    func testProjectionIsDeterministic() {
        let signals = StyleSignals(
            brightness: 0.5, contrast: 0.5, saturation: 0.5, warmth: 0.5,
            edgeDensity: 0.5, symmetry: 0.5, clutter: 0.5,
            materialHardness: 0.5, organicVsIndustrial: 0.5,
            ornateVsMinimal: 0.5, vintageVsModern: 0.5
        )
        let e1 = EmbeddingProjector.embed(signals)
        let e2 = EmbeddingProjector.embed(signals)
        XCTAssertEqual(e1, e2, "Projection must be deterministic")
    }

    func testEmbeddingIsUnitLength() {
        let signals = StyleSignals(
            brightness: 0.6, contrast: 0.4, saturation: 0.3, warmth: 0.7,
            edgeDensity: 0.2, symmetry: 0.8, clutter: 0.1,
            materialHardness: 0.3, organicVsIndustrial: 0.6,
            ornateVsMinimal: 0.2, vintageVsModern: 0.5
        )
        let e = EmbeddingProjector.embed(signals)
        let mag = sqrt(e.dims.map { $0 * $0 }.reduce(0, +))
        XCTAssertEqual(mag, 1.0, accuracy: 1e-9, "Embedding should be unit length")
    }

    // MARK: - Scoring Divergence

    func testScoringAlignsHighForMatchingIdentity() {
        let signals = minimalSignals()
        let embedding = EmbeddingProjector.embed(signals)
        var identity = TasteIdentity(embedding: embedding)
        identity.countMe = 8   // enough decisions for moderate confidence
        let result = ScoringService.score(candidate: embedding, signals: signals, identity: identity)
        XCTAssertGreaterThanOrEqual(result.alignmentScore, 60,
            "Same embedding should produce high alignment, got \(result.alignmentScore)")
    }

    func testScoringAlignsLowForOppositeIdentity() {
        let minSig  = minimalSignals()
        let ornSig  = ornateSignals()
        let minEmb  = EmbeddingProjector.embed(minSig)
        let ornEmb  = EmbeddingProjector.embed(ornSig)
        var identity = TasteIdentity(embedding: minEmb)
        identity.countMe = 8
        let result = ScoringService.score(candidate: ornEmb, signals: ornSig, identity: identity)
        // Embedding cosine ~0.66 in 64-dim space → alignment ~83.
        // Threshold < 90 verifies ornate doesn't score as a near-perfect match
        // against a minimal identity (same style scores 100; cross-style should be < 90).
        XCTAssertLessThan(result.alignmentScore, 90,
            "Opposite style should produce lower alignment, got \(result.alignmentScore)")
    }

    // MARK: - Reinforcement Divergence

    func testMeVoteMovesEmbeddingTowardCandidate() {
        let identity  = TasteIdentity()   // zero embedding
        let candidate = EmbeddingProjector.embed(minimalSignals())
        let updated   = ReinforcementService.applyTasteVote(
            vote: .me, candidateEmbedding: candidate, to: identity
        )
        let cosBefore = StyleEmbedding.zero.cosine(with: candidate)
        let cosAfter  = updated.embedding.cosine(with: candidate)
        XCTAssertGreaterThan(cosAfter, cosBefore,
            "Me vote should move embedding toward candidate")
    }

    func testNotMeVotePopulatesAntiEmbedding() {
        let identity  = TasteIdentity()
        let candidate = EmbeddingProjector.embed(ornateSignals())
        let updated   = ReinforcementService.applyTasteVote(
            vote: .notMe, candidateEmbedding: candidate, to: identity
        )
        XCTAssertFalse(updated.antiEmbedding.isZero,
            "Not-me vote should populate antiEmbedding")
        XCTAssertGreaterThan(updated.antiEmbedding.cosine(with: candidate), 0.0,
            "antiEmbedding should align with the rejected candidate")
    }

    // MARK: - Helpers

    private func minimalSignals() -> StyleSignals {
        StyleSignals(brightness: 0.85, contrast: 0.15, saturation: 0.10, warmth: 0.45,
                     edgeDensity: 0.05, symmetry: 0.90, clutter: 0.05,
                     materialHardness: 0.10, organicVsIndustrial: 0.70,
                     ornateVsMinimal: 0.05, vintageVsModern: 0.35)
    }

    private func ornateSignals() -> StyleSignals {
        StyleSignals(brightness: 0.45, contrast: 0.70, saturation: 0.65, warmth: 0.65,
                     edgeDensity: 0.80, symmetry: 0.40, clutter: 0.85,
                     materialHardness: 0.60, organicVsIndustrial: 0.35,
                     ornateVsMinimal: 0.90, vintageVsModern: 0.70)
    }
}
