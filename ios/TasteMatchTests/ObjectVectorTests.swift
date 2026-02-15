import XCTest
@testable import TasteMatch

final class ObjectVectorTests: XCTestCase {

    // MARK: - Apply Swipe

    func testApplySwipe_right_increasesAxis() {
        var vector = ObjectVector.zero
        vector.applySwipe(axis: .precision, direction: .right)
        XCTAssertEqual(vector.weights["precision"], 1.0)
    }

    func testApplySwipe_left_decreasesAxis() {
        var vector = ObjectVector.zero
        vector.applySwipe(axis: .patina, direction: .left)
        XCTAssertEqual(vector.weights["patina"], -0.8)
    }

    func testApplySwipe_up_strongBoost() {
        var vector = ObjectVector.zero
        vector.applySwipe(axis: .utility, direction: .up)
        XCTAssertEqual(vector.weights["utility"], 2.0)

        var rightVector = ObjectVector.zero
        rightVector.applySwipe(axis: .utility, direction: .right)
        XCTAssertGreaterThan(vector.weights["utility"]!, rightVector.weights["utility"]!)
    }

    // MARK: - Normalization

    func testNormalized_clampsToRange() {
        var vector = ObjectVector.zero
        vector.weights["precision"] = 3.0
        vector.weights["patina"] = -2.5

        let normalized = vector.normalized()
        XCTAssertEqual(normalized.weights["precision"], 1.0)
        XCTAssertEqual(normalized.weights["patina"], -1.0)
    }

    // MARK: - Blend

    func testBlend_wantMoreMode() {
        var image = ObjectVector.zero
        image.weights["precision"] = 1.0

        var swipe = ObjectVector.zero
        swipe.weights["precision"] = 0.0
        swipe.weights["patina"] = 1.0

        let blended = ObjectVector.blend(image: image, swipe: swipe, mode: .wantMore)

        // wantMore: image × 0.35 + swipe × 0.65
        XCTAssertEqual(blended.weights["precision"]!, 0.35, accuracy: 0.001)
        XCTAssertEqual(blended.weights["patina"]!, 0.65, accuracy: 0.001)
    }

    // MARK: - Confidence Level

    func testConfidenceLevel_thresholds() {
        var vector = ObjectVector.zero
        XCTAssertEqual(vector.confidenceLevel(swipeCount: 0), "Low")

        for _ in 0..<8 {
            vector.applySwipe(axis: .precision, direction: .right)
        }
        XCTAssertEqual(vector.confidenceLevel(swipeCount: 8), "Developing")

        for _ in 0..<6 {
            vector.applySwipe(axis: .patina, direction: .left)
        }
        XCTAssertEqual(vector.confidenceLevel(swipeCount: 14), "Strong")
    }

    // MARK: - Stability Level

    func testStabilityLevel_thresholds() {
        var vector = ObjectVector.zero
        XCTAssertEqual(vector.stabilityLevel(swipeCount: 0), "Low")

        for _ in 0..<7 {
            vector.applySwipe(axis: .heritage, direction: .right)
        }
        XCTAssertEqual(vector.stabilityLevel(swipeCount: 7), "Developing")

        for _ in 0..<7 {
            vector.applySwipe(axis: .minimalism, direction: .left)
        }
        XCTAssertEqual(vector.stabilityLevel(swipeCount: 14), "Stable")
    }

    // MARK: - Axis Scores

    func testObjectAxisScores_dominantAxis() {
        let scores = ObjectAxisScores(
            precision: 0.8, patina: 0.1, utility: 0.2, formality: -0.1,
            subculture: 0.0, ornament: -0.3, heritage: 0.4,
            technicality: 0.5, minimalism: 0.1
        )
        XCTAssertEqual(scores.dominantAxis, .precision)
    }

    func testObjectAxisScores_secondaryAxis() {
        let scores = ObjectAxisScores(
            precision: 0.8, patina: 0.1, utility: 0.2, formality: -0.1,
            subculture: 0.0, ornament: -0.3, heritage: 0.4,
            technicality: 0.5, minimalism: 0.1
        )
        XCTAssertEqual(scores.secondaryAxis, .technicality)
    }

    func testObjectAxisScores_secondaryAxis_nilWhenLow() {
        let scores = ObjectAxisScores(
            precision: 0.5, patina: 0.0, utility: 0.0, formality: 0.0,
            subculture: 0.0, ornament: 0.0, heritage: 0.0,
            technicality: 0.0, minimalism: 0.0
        )
        XCTAssertNil(scores.secondaryAxis)
    }

    // MARK: - Axis Mapping

    func testObjectAxisMapping_directMapping() {
        var vector = ObjectVector.zero
        vector.weights["precision"] = 0.7
        vector.weights["patina"] = -0.3

        let scores = ObjectAxisMapping.computeAxisScores(from: vector)
        XCTAssertEqual(scores.precision, 0.7, accuracy: 0.001)
        XCTAssertEqual(scores.patina, -0.3, accuracy: 0.001)
    }
}
