import XCTest
@testable import TasteMatch

final class DomainEnablementTests: XCTestCase {

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

    // MARK: - DomainLayout Config Tests

    func testSpaceConfig_heroLabel() {
        let config = DomainLayout.config(for: .space)
        XCTAssertEqual(config.heroLabel, "SIGNATURE SPACES")
    }

    func testObjectsConfig_heroLabel() {
        let config = DomainLayout.config(for: .objects)
        XCTAssertEqual(config.heroLabel, "SIGNATURE CARRY")
    }

    func testArtConfig_heroLabel() {
        let config = DomainLayout.config(for: .art)
        XCTAssertEqual(config.heroLabel, "SIGNATURE WORKS")
    }

    func testSpaceConfig_showsMaterials() {
        let config = DomainLayout.config(for: .space)
        XCTAssertTrue(config.showMaterials)
        XCTAssertTrue(config.showWorldGrid)
        XCTAssertFalse(config.showUniform)
        XCTAssertFalse(config.showRarityLanes)
    }

    func testObjectsConfig_showsUniform() {
        let config = DomainLayout.config(for: .objects)
        XCTAssertFalse(config.showMaterials)
        XCTAssertFalse(config.showWorldGrid)
        XCTAssertTrue(config.showUniform)
        XCTAssertFalse(config.showRarityLanes)
    }

    func testArtConfig_showsRarityLanes() {
        let config = DomainLayout.config(for: .art)
        XCTAssertFalse(config.showMaterials)
        XCTAssertFalse(config.showWorldGrid)
        XCTAssertFalse(config.showUniform)
        XCTAssertTrue(config.showRarityLanes)
    }

    // MARK: - Domain Radar Subtitles

    func testSpaceRadarSubtitle() {
        let config = DomainLayout.config(for: .space)
        XCTAssertEqual(config.radarSubtitle, "Architecture + material signals.")
    }

    func testObjectsRadarSubtitle() {
        let config = DomainLayout.config(for: .objects)
        XCTAssertEqual(config.radarSubtitle, "Craft, ateliers, utility.")
    }

    func testArtRadarSubtitle() {
        let config = DomainLayout.config(for: .art)
        XCTAssertEqual(config.radarSubtitle, "Movements + scenes.")
    }

    // MARK: - Onboarding State

    func testFreshUser_needsGoalSelection() {
        XCTAssertFalse(DomainPreferencesStore.isOnboardingComplete)
    }

    func testExistingUser_skipsGoalSelection() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        DomainPreferencesStore.clear()

        XCTAssertTrue(DomainPreferencesStore.isOnboardingComplete)
    }

    // MARK: - LastViewed returns nil for disabled domains

    func testLastViewed_returnsNil_forDisabledDomain() {
        let profileId = UUID()
        DomainPreferencesStore.setEnabled(Set(TasteDomain.allCases))
        DomainPreferencesStore.setLastViewed(domain: .art, for: profileId)

        // Now disable art
        DomainPreferencesStore.setEnabled([.space])
        XCTAssertNil(DomainPreferencesStore.lastViewed(for: profileId))
    }
}
