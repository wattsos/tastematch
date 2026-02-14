import XCTest
@testable import TasteMatch

final class NetworkModelTests: XCTestCase {

    func testProfileSnapshot_encodeDecode_roundTrips() throws {
        let snapshot = ProfileSnapshot(
            id: UUID(),
            userId: "user-1",
            profileName: "Warm Minimalist",
            axisScores: ["warmCool": 0.6, "minimalOrnate": -0.3],
            basisHash: "abc123",
            confidenceLevel: "High",
            influences: ["Warm tones", "Natural light"],
            avoids: ["Industrial edge"],
            createdAt: Date(timeIntervalSince1970: 1700000000),
            updatedAt: Date(timeIntervalSince1970: 1700001000)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ProfileSnapshot.self, from: data)

        XCTAssertEqual(decoded.id, snapshot.id)
        XCTAssertEqual(decoded.userId, "user-1")
        XCTAssertEqual(decoded.profileName, "Warm Minimalist")
        XCTAssertEqual(decoded.axisScores["warmCool"], 0.6)
        XCTAssertEqual(decoded.confidenceLevel, "High")
        XCTAssertEqual(decoded.influences.count, 2)
        XCTAssertEqual(decoded.avoids.count, 1)
    }

    func testShareResponse_encodeDecode_roundTrips() throws {
        let response = ShareResponse(slug: "abc12345", publicURL: "https://burgundy.app/p/abc12345")

        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(ShareResponse.self, from: data)

        XCTAssertEqual(decoded.slug, "abc12345")
        XCTAssertEqual(decoded.publicURL, "https://burgundy.app/p/abc12345")
    }

    func testAxisScores_toDictionary_containsAllAxes() {
        let scores = AxisScores(
            minimalOrnate: 0.1,
            warmCool: 0.2,
            softStructured: 0.3,
            organicIndustrial: 0.4,
            lightDark: 0.5,
            neutralSaturated: 0.6,
            sparseLayered: 0.7
        )

        let dict = scores.toDictionary()

        XCTAssertEqual(dict.count, Axis.allCases.count)
        XCTAssertEqual(dict["minimalOrnate"]!, 0.1, accuracy: 0.001)
        XCTAssertEqual(dict["warmCool"]!, 0.2, accuracy: 0.001)
        XCTAssertEqual(dict["softStructured"]!, 0.3, accuracy: 0.001)
        XCTAssertEqual(dict["organicIndustrial"]!, 0.4, accuracy: 0.001)
        XCTAssertEqual(dict["lightDark"]!, 0.5, accuracy: 0.001)
        XCTAssertEqual(dict["neutralSaturated"]!, 0.6, accuracy: 0.001)
        XCTAssertEqual(dict["sparseLayered"]!, 0.7, accuracy: 0.001)
    }
}
