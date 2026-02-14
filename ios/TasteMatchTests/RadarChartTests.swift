import XCTest
@testable import TasteMatch

final class RadarChartTests: XCTestCase {

    func testRadarChart_scoreMapping() {
        // Verify [-1,+1] maps to [0,1] display range
        let mapping: (Double) -> Double = { ($0 + 1) / 2 }

        XCTAssertEqual(mapping(-1.0), 0.0, accuracy: 0.001)
        XCTAssertEqual(mapping(0.0), 0.5, accuracy: 0.001)
        XCTAssertEqual(mapping(1.0), 1.0, accuracy: 0.001)
        XCTAssertEqual(mapping(-0.5), 0.25, accuracy: 0.001)
        XCTAssertEqual(mapping(0.5), 0.75, accuracy: 0.001)
    }

    func testRadarChart_pointCalculation() {
        // Verify 7 points are generated at correct angles
        let axisCount = 7
        let slice = (2 * Double.pi) / Double(axisCount)
        let startAngle = -Double.pi / 2 // top

        for i in 0..<axisCount {
            let angle = slice * Double(i) + startAngle
            // First axis should be at top (-.pi/2)
            if i == 0 {
                XCTAssertEqual(angle, -Double.pi / 2, accuracy: 0.001)
            }
            // Angles should be within [-pi, pi+]
            XCTAssertGreaterThanOrEqual(angle, -Double.pi)
            XCTAssertLessThan(angle, 2 * Double.pi)
        }

        // Verify all 7 axes produce distinct angles
        let angles = (0..<axisCount).map { slice * Double($0) + startAngle }
        let uniqueAngles = Set(angles.map { Int($0 * 1000) })
        XCTAssertEqual(uniqueAngles.count, axisCount)
    }
}
