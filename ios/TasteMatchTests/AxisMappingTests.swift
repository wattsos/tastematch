import XCTest
@testable import TasteMatch

final class AxisMappingTests: XCTestCase {

    // MARK: - Industrial axes produce high industrial weight

    func testSyntheticVector_industrialAxes_producesHighIndustrialWeight() {
        let axisWeights: [String: Double] = [
            "organicIndustrial": 0.9,
            "softStructured": 0.7,
            "lightDark": 0.5,
            "warmCool": -0.4,
            "minimalOrnate": 0.0,
            "neutralSaturated": 0.0,
            "sparseLayered": 0.0,
        ]

        let vector = AxisMapping.syntheticVector(fromAxes: axisWeights)

        let industrialWeight = vector.weights["industrial"] ?? 0
        let otherMax = vector.weights
            .filter { $0.key != "industrial" }
            .values
            .max() ?? 0

        XCTAssertGreaterThan(industrialWeight, 0, "Industrial tag should have positive weight")
        XCTAssertGreaterThanOrEqual(industrialWeight, otherMax,
            "Industrial tag should be among the highest weighted tags")
    }

    // MARK: - Zero axes produce zero vector

    func testSyntheticVector_allZeroAxes_producesZeroVector() {
        let axisWeights: [String: Double] = [
            "organicIndustrial": 0.0,
            "softStructured": 0.0,
            "lightDark": 0.0,
            "warmCool": 0.0,
            "minimalOrnate": 0.0,
            "neutralSaturated": 0.0,
            "sparseLayered": 0.0,
        ]

        let vector = AxisMapping.syntheticVector(fromAxes: axisWeights)

        for (tag, weight) in vector.weights {
            XCTAssertEqual(weight, 0, accuracy: 1e-10,
                "Tag '\(tag)' should have zero weight with zero axes")
        }
    }

    // MARK: - Deterministic output

    func testSyntheticVector_deterministic() {
        let axisWeights: [String: Double] = [
            "organicIndustrial": 0.74,
            "warmCool": -0.3,
            "minimalOrnate": 0.2,
            "softStructured": 0.5,
            "lightDark": 0.1,
            "neutralSaturated": -0.15,
            "sparseLayered": 0.3,
        ]

        let vector1 = AxisMapping.syntheticVector(fromAxes: axisWeights)
        let vector2 = AxisMapping.syntheticVector(fromAxes: axisWeights)

        XCTAssertEqual(vector1.weights.count, vector2.weights.count)
        for (tag, weight1) in vector1.weights {
            let weight2 = vector2.weights[tag] ?? Double.nan
            XCTAssertEqual(weight1, weight2, accuracy: 1e-10,
                "Tag '\(tag)' should produce identical weight across calls")
        }
    }
}
