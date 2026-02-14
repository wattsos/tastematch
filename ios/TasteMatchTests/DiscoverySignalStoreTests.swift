import XCTest
@testable import TasteMatch

final class DiscoverySignalStoreTests: XCTestCase {

    private let testProfileId = UUID()

    // MARK: - Empty Profile

    func testLoad_emptyProfile_returnsEmptySignals() {
        let profileId = UUID()
        let signals = DiscoverySignalStore.load(for: profileId)

        XCTAssertTrue(signals.viewedIds.isEmpty)
        XCTAssertTrue(signals.savedIds.isEmpty)
        XCTAssertTrue(signals.dismissedIds.isEmpty)
        XCTAssertEqual(signals.profileId, profileId)
    }

    // MARK: - Round-Trip Persistence

    func testRecordViewed_persists() {
        let profileId = UUID()
        DiscoverySignalStore.recordViewed("item-1", profileId: profileId)

        let signals = DiscoverySignalStore.load(for: profileId)
        XCTAssertTrue(signals.viewedIds.contains("item-1"))
    }

    func testRecordSaved_persists() {
        let profileId = UUID()
        DiscoverySignalStore.recordSaved("item-2", profileId: profileId)

        let signals = DiscoverySignalStore.load(for: profileId)
        XCTAssertTrue(signals.savedIds.contains("item-2"))
    }

    func testRecordDismissed_persists() {
        let profileId = UUID()
        DiscoverySignalStore.recordDismissed("item-3", profileId: profileId)

        let signals = DiscoverySignalStore.load(for: profileId)
        XCTAssertTrue(signals.dismissedIds.contains("item-3"))
    }

    // MARK: - Multiple Signals

    func testMultipleSignals_accumulateCorrectly() {
        let profileId = UUID()
        DiscoverySignalStore.recordViewed("a", profileId: profileId)
        DiscoverySignalStore.recordViewed("b", profileId: profileId)
        DiscoverySignalStore.recordSaved("c", profileId: profileId)
        DiscoverySignalStore.recordDismissed("d", profileId: profileId)

        let signals = DiscoverySignalStore.load(for: profileId)
        XCTAssertEqual(signals.viewedIds.count, 2)
        XCTAssertEqual(signals.savedIds.count, 1)
        XCTAssertEqual(signals.dismissedIds.count, 1)
    }
}
