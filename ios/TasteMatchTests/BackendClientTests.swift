import XCTest
@testable import TasteMatch

final class BackendClientTests: XCTestCase {

    func testLocalBackendClient_conformsToProtocol() {
        let client: BackendClient = LocalBackendClient()
        XCTAssertNotNil(client)
    }

    func testRemoteBackendClient_conformsToProtocol() {
        let client: BackendClient = RemoteBackendClient()
        XCTAssertNotNil(client)
    }

    func testLocalBackendClient_getProfile_returnsNilForUnknown() async throws {
        let client = LocalBackendClient()
        let result = try await client.getProfile(id: UUID())
        XCTAssertNil(result)
    }

    func testLocalBackendClient_sendEvents_doesNotThrow() async throws {
        let client = LocalBackendClient()
        let event = LoggedEvent(name: "test_event")
        try await client.sendEvents([event])
    }

    func testFeatureFlags_defaultIsLocal() {
        XCTAssertEqual(FeatureFlags.backendMode, .local)
    }
}
