import XCTest
@testable import TasteMatch

final class ProfileStoreTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        ProfileStore.clear()
    }

    // MARK: - Round-trip

    func testSaveAndLoad_roundTrips() {
        let profile = TasteProfile(
            tags: [TasteTag(key: "minimalist", label: "Minimalist", confidence: 0.9)],
            story: "Test story",
            signals: [Signal(key: "brightness", value: "high")]
        )
        let recs = [
            RecommendationItem(
                title: "Test Item",
                subtitle: "Test — $100",
                reason: "Test reason",
                attributionConfidence: 0.8
            )
        ]

        ProfileStore.save(profile: profile, recommendations: recs)

        let loaded = ProfileStore.loadLatest()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.tasteProfile.id, profile.id)
        XCTAssertEqual(loaded?.tasteProfile.tags.count, 1)
        XCTAssertEqual(loaded?.tasteProfile.tags.first?.key, "minimalist")
        XCTAssertEqual(loaded?.tasteProfile.story, "Test story")
        XCTAssertEqual(loaded?.recommendations.count, 1)
        XCTAssertEqual(loaded?.recommendations.first?.title, "Test Item")
        XCTAssertEqual(loaded?.recommendations.first?.attributionConfidence, 0.8)
    }

    // MARK: - Clear

    func testClear_removesData() {
        let profile = TasteProfile(
            tags: [TasteTag(key: "coastal", label: "Coastal", confidence: 0.7)],
            story: "Coastal story",
            signals: []
        )

        ProfileStore.save(profile: profile, recommendations: [])
        XCTAssertNotNil(ProfileStore.loadLatest())

        ProfileStore.clear()
        XCTAssertNil(ProfileStore.loadLatest())
    }

    // MARK: - Load when empty

    func testLoad_whenNothingSaved_returnsNil() {
        ProfileStore.clear()
        XCTAssertNil(ProfileStore.loadLatest())
    }

    // MARK: - Overwrite

    func testSave_overwritesPrevious() {
        let first = TasteProfile(
            tags: [TasteTag(key: "rustic", label: "Rustic", confidence: 0.6)],
            story: "First",
            signals: []
        )
        let second = TasteProfile(
            tags: [TasteTag(key: "japandi", label: "Japandi", confidence: 0.8)],
            story: "Second",
            signals: []
        )

        ProfileStore.save(profile: first, recommendations: [])
        ProfileStore.save(profile: second, recommendations: [])

        let loaded = ProfileStore.loadLatest()
        XCTAssertEqual(loaded?.tasteProfile.id, second.id)
        XCTAssertEqual(loaded?.tasteProfile.tags.first?.key, "japandi")
    }

    // MARK: - Timestamp

    func testSavedAt_isPopulated() {
        let profile = TasteProfile(
            tags: [TasteTag(key: "bohemian", label: "Bohemian", confidence: 0.75)],
            story: "Boho",
            signals: []
        )

        let before = Date()
        ProfileStore.save(profile: profile, recommendations: [])
        let after = Date()

        let loaded = ProfileStore.loadLatest()
        XCTAssertNotNil(loaded?.savedAt)
        XCTAssertGreaterThanOrEqual(loaded!.savedAt, before)
        XCTAssertLessThanOrEqual(loaded!.savedAt, after)
    }
}
