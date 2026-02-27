import XCTest
@testable import TasteMatch

final class BurgundyAPITests: XCTestCase {

    // MARK: - DeviceInstallID persistence

    func testDeviceInstallIDIsStableAcrossAccesses() {
        let first  = DeviceInstallID.current
        let second = DeviceInstallID.current
        XCTAssertEqual(first, second,
            "DeviceInstallID.current must return the same value on repeated calls")
    }

    func testDeviceInstallIDIsValidUUID() {
        let id = DeviceInstallID.current
        XCTAssertNotNil(UUID(uuidString: id),
            "DeviceInstallID should be a valid UUID string, got: \(id)")
    }

    // MARK: - RemoteIdentity decode → TasteIdentity

    func testRemoteIdentityDecodesCorrectly() throws {
        let embedding     = Array(repeating: 0.1, count: 64)
        let antiEmbedding = Array(repeating: 0.0, count: 64)
        let uuid          = UUID().uuidString

        let json: [String: Any] = [
            "id":             uuid,
            "version":        3,
            "embedding":      embedding,
            "anti_embedding": antiEmbedding,
            "stability":      0.82,
            "count_me":       5,
            "count_not_me":   2,
            "count_maybe":    1,
        ]
        let data   = try JSONSerialization.data(withJSONObject: json)
        let remote = try JSONDecoder().decode(RemoteIdentity.self, from: data)
        let taste  = remote.toTasteIdentity()

        XCTAssertEqual(taste.id.uuidString, uuid)
        XCTAssertEqual(taste.version,    3)
        XCTAssertEqual(taste.countMe,    5)
        XCTAssertEqual(taste.countNotMe, 2)
        XCTAssertEqual(taste.countMaybe, 1)
        XCTAssertEqual(taste.stability,  0.82, accuracy: 1e-9)
        XCTAssertEqual(taste.embedding.dims.count, 64)
        XCTAssertEqual(taste.embedding.dims[0], 0.1, accuracy: 1e-9)
    }

    func testRemoteIdentityFallsBackToZeroEmbeddingOnWrongSize() throws {
        let json: [String: Any] = [
            "id":             UUID().uuidString,
            "version":        1,
            "embedding":      [0.5, 0.5],   // wrong size — should produce zero fallback
            "anti_embedding": [] as [Double],
            "stability":      1.0,
            "count_me":       0,
            "count_not_me":   0,
            "count_maybe":    0,
        ]
        let data   = try JSONSerialization.data(withJSONObject: json)
        let remote = try JSONDecoder().decode(RemoteIdentity.self, from: data)
        let taste  = remote.toTasteIdentity()

        XCTAssertTrue(taste.embedding.isZero,
            "Embedding of wrong size should fall back to zero")
    }
}
