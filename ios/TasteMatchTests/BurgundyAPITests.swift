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

    // MARK: - FetchEvents response decode

    func testFetchEventsResponseDecodes() throws {
        let eventId    = UUID().uuidString
        let identityId = UUID().uuidString
        let json: [String: Any] = [
            "events": [
                [
                    "id":           eventId,
                    "identity_id":  identityId,
                    "vote":         "me",
                    "return_reason": NSNull(),
                    "category":     "sofa",
                    "pending":      false,
                    "created_at":   "2026-02-27T04:00:00.000000+00:00",
                    "scores":       ["alignment": 72.0, "tension": 8.0],
                ] as [String: Any]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)

        // FetchEventsResponse is private; decode via a local wrapper using the public RemoteEvent type.
        struct Wrapper: Decodable { let events: [RemoteEvent] }
        let wrapper = try JSONDecoder().decode(Wrapper.self, from: data)

        XCTAssertEqual(wrapper.events.count, 1)
        let event = wrapper.events[0]
        XCTAssertEqual(event.id,          eventId)
        XCTAssertEqual(event.identity_id, identityId)
        XCTAssertEqual(event.vote,        "me")
        XCTAssertNil(event.return_reason)
        XCTAssertEqual(event.category,    "sofa")
        XCTAssertFalse(event.pending)
        XCTAssertEqual(event.scores?["alignment"] ?? 0, 72.0, accuracy: 1e-9)
        XCTAssertEqual(event.scores?["tension"]   ?? 0,  8.0, accuracy: 1e-9)
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
