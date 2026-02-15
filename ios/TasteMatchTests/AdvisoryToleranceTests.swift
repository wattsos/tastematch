import XCTest
@testable import TasteMatch

final class AdvisoryToleranceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AdvisoryToleranceStore.reset()
        AdvisorySignalStore.clearAll()
    }

    override func tearDown() {
        AdvisoryToleranceStore.reset()
        AdvisorySignalStore.clearAll()
        super.tearDown()
    }

    // MARK: - Tolerance Defaults

    func testToleranceDefaultsToZero() {
        XCTAssertEqual(AdvisoryToleranceStore.tolerance, 0.0, accuracy: 0.001)
    }

    // MARK: - Clamping

    func testToleranceClampsPositive() {
        AdvisoryToleranceStore.tolerance = 0.20
        XCTAssertEqual(AdvisoryToleranceStore.tolerance, 0.15, accuracy: 0.001)
    }

    func testToleranceClampsNegative() {
        AdvisoryToleranceStore.tolerance = -0.20
        XCTAssertEqual(AdvisoryToleranceStore.tolerance, -0.15, accuracy: 0.001)
    }

    // MARK: - Weekly Stats

    func testWeeklyStatsComputation() {
        // 2 red shown, 1 red proceeded = 1 near miss, 1 override
        AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "shown", verdict: "red", skuId: "a"))
        AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "proceeded", verdict: "red", skuId: "a"))
        AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "shown", verdict: "red", skuId: "b"))
        AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "intentionalShift", verdict: "red", skuId: "b"))

        let stats = AdvisorySignalStore.weeklyStats()
        XCTAssertEqual(stats.overrides, 1)
        XCTAssertEqual(stats.nearMisses, 1)
        XCTAssertEqual(stats.intentionalShifts, 1)
    }

    func testWeeklyStatsIgnoresOldSignals() {
        let old = Date().addingTimeInterval(-8 * 86400)
        AdvisorySignalStore.record(AdvisorySignal(timestamp: old, action: "shown", verdict: "red", skuId: "old"))
        AdvisorySignalStore.record(AdvisorySignal(timestamp: old, action: "proceeded", verdict: "red", skuId: "old"))

        let stats = AdvisorySignalStore.weeklyStats()
        XCTAssertEqual(stats.overrides, 0)
        XCTAssertEqual(stats.nearMisses, 0)
    }

    // MARK: - Adjustment

    func testPositiveAdjustmentOnOverrides() {
        // Record 3 red overrides
        for _ in 0..<3 {
            AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "shown", verdict: "red", skuId: "test"))
            AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "proceeded", verdict: "red", skuId: "test"))
        }

        AdvisoryToleranceStore.adjustIfNeeded()
        XCTAssertEqual(AdvisoryToleranceStore.tolerance, 0.03, accuracy: 0.001)
    }

    func testNegativeAdjustmentOnNonProceeds() {
        // Record 5 yellow/red shown but not proceeded
        for _ in 0..<5 {
            AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "shown", verdict: "yellow", skuId: "test"))
        }

        AdvisoryToleranceStore.adjustIfNeeded()
        XCTAssertEqual(AdvisoryToleranceStore.tolerance, -0.03, accuracy: 0.001)
    }

    func testBothAdjustmentsCancel() {
        // 3 red overrides + 5 yellow non-proceeds → +0.03 - 0.03 = 0
        for _ in 0..<3 {
            AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "shown", verdict: "red", skuId: "a"))
            AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "proceeded", verdict: "red", skuId: "a"))
        }
        for _ in 0..<5 {
            AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "shown", verdict: "yellow", skuId: "b"))
        }

        AdvisoryToleranceStore.adjustIfNeeded()
        XCTAssertEqual(AdvisoryToleranceStore.tolerance, 0.0, accuracy: 0.001)
    }

    func testAdjustmentOnlyOncePerDay() {
        for _ in 0..<3 {
            AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "shown", verdict: "red", skuId: "test"))
            AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "proceeded", verdict: "red", skuId: "test"))
        }

        AdvisoryToleranceStore.adjustIfNeeded()
        let firstValue = AdvisoryToleranceStore.tolerance

        // Record more overrides
        for _ in 0..<3 {
            AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "shown", verdict: "red", skuId: "test"))
            AdvisorySignalStore.record(AdvisorySignal(timestamp: Date(), action: "proceeded", verdict: "red", skuId: "test"))
        }

        AdvisoryToleranceStore.adjustIfNeeded()
        XCTAssertEqual(AdvisoryToleranceStore.tolerance, firstValue, accuracy: 0.001, "Should not adjust twice in same day")
    }

    // MARK: - Policy with Tolerance

    func testPolicyVerdictFlipsWithPositiveTolerance() {
        // Standard: red if alignment <= 0.50
        // With tolerance +0.05, effective alignment = 0.48 + 0.05 = 0.53 → not red
        let conflict = ConflictResult(alignment: 0.48, drift: 0.10, conflictAxes: ["Precision"])

        let withoutTolerance = AdvisoryPolicy.decide(level: .standard, conflict: conflict)
        XCTAssertEqual(withoutTolerance.verdict, .red)

        let withTolerance = AdvisoryPolicy.decide(level: .standard, conflict: conflict, tolerance: 0.05)
        XCTAssertNotEqual(withTolerance.verdict, .red, "Positive tolerance should shift verdict away from red")
    }

    func testPolicyVerdictFlipsWithNegativeTolerance() {
        // Standard: yellow if alignment <= 0.62 (and > 0.50)
        // Alignment 0.55 → yellow normally
        // With tolerance -0.06, effective = 0.49 → red
        let conflict = ConflictResult(alignment: 0.55, drift: 0.10, conflictAxes: ["Patina"])

        let withoutTolerance = AdvisoryPolicy.decide(level: .standard, conflict: conflict)
        XCTAssertEqual(withoutTolerance.verdict, .yellow)

        let withTolerance = AdvisoryPolicy.decide(level: .standard, conflict: conflict, tolerance: -0.06)
        XCTAssertEqual(withTolerance.verdict, .red, "Negative tolerance should shift verdict toward red")
    }

    func testToleranceDoesNotAffectDriftThreshold() {
        // High drift should still trigger red regardless of positive tolerance
        let conflict = ConflictResult(alignment: 0.70, drift: 0.35, conflictAxes: ["Utility"])

        let withTolerance = AdvisoryPolicy.decide(level: .standard, conflict: conflict, tolerance: 0.15)
        XCTAssertEqual(withTolerance.verdict, .red, "Drift threshold should not be affected by tolerance")
    }
}
