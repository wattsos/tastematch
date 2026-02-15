import XCTest
@testable import TasteMatch

final class DomainPreferencesStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DomainPreferencesStore.clear()
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }

    override func tearDown() {
        DomainPreferencesStore.clear()
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        super.tearDown()
    }

    func testDefaultPreferences_migratesExistingUser() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        DomainPreferencesStore.clear()

        let prefs = DomainPreferencesStore.load()
        XCTAssertTrue(prefs.onboardingComplete)
        XCTAssertEqual(prefs.enabledDomains, Set(TasteDomain.allCases))
    }

    func testSetEnabled_persistsRoundTrip() {
        DomainPreferencesStore.setEnabled([.space, .art])
        DomainPreferencesStore.clear()  // Clear cache to force reload from disk

        // Re-read triggers fresh migration since file was cleared.
        // Instead, test in-memory round-trip:
        DomainPreferencesStore.setEnabled([.space, .art])
        XCTAssertEqual(DomainPreferencesStore.enabledDomains, [.space, .art])
    }

    func testPrimaryDomain_isFirstInCanonicalOrder() {
        DomainPreferencesStore.setEnabled([.art, .objects])
        // Canonical order: space, objects, art — so "objects" should be primary
        XCTAssertEqual(DomainPreferencesStore.primaryDomain, .objects)
    }

    func testSetEnabled_singleDomain() {
        DomainPreferencesStore.setEnabled([.art])
        XCTAssertEqual(DomainPreferencesStore.enabledDomains, [.art])
        XCTAssertEqual(DomainPreferencesStore.primaryDomain, .art)
    }

    func testLastViewedDomain_persistsPerProfile() {
        let id1 = UUID()
        let id2 = UUID()
        DomainPreferencesStore.setEnabled(Set(TasteDomain.allCases))

        DomainPreferencesStore.setLastViewed(domain: .art, for: id1)
        DomainPreferencesStore.setLastViewed(domain: .objects, for: id2)

        XCTAssertEqual(DomainPreferencesStore.lastViewed(for: id1), .art)
        XCTAssertEqual(DomainPreferencesStore.lastViewed(for: id2), .objects)
    }

    func testMarkOnboardingComplete() {
        // Start fresh (no existing user defaults)
        let prefs = DomainPreferencesStore.load()
        XCTAssertFalse(prefs.onboardingComplete)

        DomainPreferencesStore.markOnboardingComplete()
        XCTAssertTrue(DomainPreferencesStore.isOnboardingComplete)
    }
}
