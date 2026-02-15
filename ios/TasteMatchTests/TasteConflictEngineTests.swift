import XCTest
@testable import TasteMatch

final class TasteConflictEngineTests: XCTestCase {

    // MARK: - Determinism

    func testDeterministic() {
        let scores = makeScores(precision: 0.8, patina: -0.3, utility: 0.5)
        let itemAxes: [String: Double] = [
            "precision": 0.2, "patina": 0.7, "utility": -0.4,
            "formality": 0.1, "subculture": 0.0, "ornament": 0.3,
            "heritage": 0.0, "technicality": 0.0, "minimalism": 0.0,
        ]
        let r1 = TasteConflictEngine.evaluateObjects(userScores: scores, itemAxes: itemAxes)
        let r2 = TasteConflictEngine.evaluateObjects(userScores: scores, itemAxes: itemAxes)
        XCTAssertEqual(r1, r2)
    }

    // MARK: - Bounds

    func testAlignmentBounds() {
        let scores = makeScores(precision: 1.0, patina: -1.0, utility: 0.5)
        let itemAxes: [String: Double] = [
            "precision": -1.0, "patina": 1.0, "utility": -0.5,
        ]
        let result = TasteConflictEngine.evaluateObjects(userScores: scores, itemAxes: itemAxes)
        XCTAssertGreaterThanOrEqual(result.alignment, 0.0)
        XCTAssertLessThanOrEqual(result.alignment, 1.0)
    }

    func testDriftBounds() {
        let scores = makeScores(precision: 1.0, patina: -1.0, utility: 1.0)
        let itemAxes: [String: Double] = [
            "precision": -1.0, "patina": 1.0, "utility": -1.0,
        ]
        let result = TasteConflictEngine.evaluateObjects(userScores: scores, itemAxes: itemAxes)
        XCTAssertGreaterThanOrEqual(result.drift, 0.0)
        XCTAssertLessThanOrEqual(result.drift, 1.0)
    }

    // MARK: - Identical Vectors

    func testIdenticalVectorsHighAlignment() {
        let scores = makeScores(precision: 0.6, patina: 0.4, utility: 0.3)
        let itemAxes: [String: Double] = [
            "precision": 0.6, "patina": 0.4, "utility": 0.3,
            "formality": 0.0, "subculture": 0.0, "ornament": 0.0,
            "heritage": 0.0, "technicality": 0.0, "minimalism": 0.0,
        ]
        let result = TasteConflictEngine.evaluateObjects(userScores: scores, itemAxes: itemAxes)
        XCTAssertGreaterThan(result.alignment, 0.9, "Identical vectors should have near-perfect alignment")
        XCTAssertLessThan(result.drift, 0.1, "Identical vectors should have near-zero drift")
    }

    // MARK: - Conflict Axes

    func testConflictAxesMaxTwo() {
        let scores = makeScores(precision: 0.8, patina: -0.7, utility: 0.5)
        let itemAxes: [String: Double] = [
            "precision": -0.5, "patina": 0.9, "utility": 0.0,
        ]
        let result = TasteConflictEngine.evaluateObjects(userScores: scores, itemAxes: itemAxes)
        XCTAssertLessThanOrEqual(result.conflictAxes.count, 2)
    }

    func testConflictAxesPicksLargestMismatch() {
        let scores = makeScores(precision: 0.9, patina: -0.9, utility: 0.0)
        let itemAxes: [String: Double] = [
            "precision": -0.9, "patina": 0.9, "utility": 0.0,
            "formality": 0.0, "subculture": 0.0, "ornament": 0.0,
            "heritage": 0.0, "technicality": 0.0, "minimalism": 0.0,
        ]
        let result = TasteConflictEngine.evaluateObjects(userScores: scores, itemAxes: itemAxes)
        // Precision and Patina have the largest absolute mismatches
        XCTAssertTrue(result.conflictAxes.contains("Precision"))
        XCTAssertTrue(result.conflictAxes.contains("Patina"))
    }

    // MARK: - Advisory Policy: Soft

    func testSoftInterceptOnlyOnRed() {
        // Red: drift >= 0.40
        let redConflict = ConflictResult(alignment: 0.60, drift: 0.45, conflictAxes: ["Precision"])
        let redDecision = AdvisoryPolicy.decide(level: .soft, conflict: redConflict)
        XCTAssertEqual(redDecision.verdict, .red)
        XCTAssertTrue(redDecision.shouldIntercept)

        // Yellow: drift >= 0.28 but < 0.40
        let yellowConflict = ConflictResult(alignment: 0.60, drift: 0.30, conflictAxes: ["Patina"])
        let yellowDecision = AdvisoryPolicy.decide(level: .soft, conflict: yellowConflict)
        XCTAssertEqual(yellowDecision.verdict, .yellow)
        XCTAssertFalse(yellowDecision.shouldIntercept)

        // Green
        let greenConflict = ConflictResult(alignment: 0.70, drift: 0.15, conflictAxes: [])
        let greenDecision = AdvisoryPolicy.decide(level: .soft, conflict: greenConflict)
        XCTAssertEqual(greenDecision.verdict, .green)
        XCTAssertFalse(greenDecision.shouldIntercept)
    }

    // MARK: - Advisory Policy: Standard

    func testStandardInterceptOnYellowAndRed() {
        // Red: drift >= 0.30
        let redConflict = ConflictResult(alignment: 0.60, drift: 0.35, conflictAxes: ["Utility"])
        let redDecision = AdvisoryPolicy.decide(level: .standard, conflict: redConflict)
        XCTAssertEqual(redDecision.verdict, .red)
        XCTAssertTrue(redDecision.shouldIntercept)

        // Yellow: drift >= 0.20 but < 0.30
        let yellowConflict = ConflictResult(alignment: 0.60, drift: 0.25, conflictAxes: ["Heritage"])
        let yellowDecision = AdvisoryPolicy.decide(level: .standard, conflict: yellowConflict)
        XCTAssertEqual(yellowDecision.verdict, .yellow)
        XCTAssertTrue(yellowDecision.shouldIntercept, "Standard should intercept yellow")

        // Green
        let greenConflict = ConflictResult(alignment: 0.75, drift: 0.15, conflictAxes: [])
        let greenDecision = AdvisoryPolicy.decide(level: .standard, conflict: greenConflict)
        XCTAssertEqual(greenDecision.verdict, .green)
        XCTAssertFalse(greenDecision.shouldIntercept)
    }

    // MARK: - Advisory Policy: Strict

    func testStrictInterceptOnYellowAndRed() {
        // Red
        let redConflict = ConflictResult(alignment: 0.55, drift: 0.25, conflictAxes: ["Formality"])
        let redDecision = AdvisoryPolicy.decide(level: .strict, conflict: redConflict)
        XCTAssertEqual(redDecision.verdict, .red)
        XCTAssertTrue(redDecision.shouldIntercept)

        // Yellow: drift >= 0.16 but < 0.22
        let yellowConflict = ConflictResult(alignment: 0.75, drift: 0.18, conflictAxes: ["Ornament"])
        let yellowDecision = AdvisoryPolicy.decide(level: .strict, conflict: yellowConflict)
        XCTAssertEqual(yellowDecision.verdict, .yellow)
        XCTAssertTrue(yellowDecision.shouldIntercept)

        // Green
        let greenConflict = ConflictResult(alignment: 0.80, drift: 0.10, conflictAxes: [])
        let greenDecision = AdvisoryPolicy.decide(level: .strict, conflict: greenConflict)
        XCTAssertEqual(greenDecision.verdict, .green)
        XCTAssertFalse(greenDecision.shouldIntercept)
    }

    // MARK: - Advisory Policy: Alignment Threshold

    func testLowAlignmentTriggersRed() {
        // Standard: red if alignment <= 0.50
        let conflict = ConflictResult(alignment: 0.45, drift: 0.10, conflictAxes: ["Subculture"])
        let decision = AdvisoryPolicy.decide(level: .standard, conflict: conflict)
        XCTAssertEqual(decision.verdict, .red)
        XCTAssertTrue(decision.shouldIntercept)
    }

    // MARK: - Advisory Settings Persistence

    func testAdvisorySettingsDefaultIsStandard() {
        let key = "burgundy.advisoryLevel"
        UserDefaults.standard.removeObject(forKey: key)
        let settings = AdvisorySettings()
        XCTAssertEqual(settings.level, .standard)
    }

    func testAdvisorySettingsRoundTrip() {
        let key = "burgundy.advisoryLevel"
        UserDefaults.standard.removeObject(forKey: key)
        let settings = AdvisorySettings()
        settings.level = .strict
        let reloaded = AdvisorySettings()
        XCTAssertEqual(reloaded.level, .strict)
        // Clean up
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Helpers

    private func makeScores(
        precision: Double = 0, patina: Double = 0, utility: Double = 0,
        formality: Double = 0, subculture: Double = 0, ornament: Double = 0,
        heritage: Double = 0, technicality: Double = 0, minimalism: Double = 0
    ) -> ObjectAxisScores {
        ObjectAxisScores(
            precision: precision, patina: patina, utility: utility,
            formality: formality, subculture: subculture, ornament: ornament,
            heritage: heritage, technicality: technicality, minimalism: minimalism
        )
    }
}
