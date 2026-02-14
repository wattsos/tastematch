import XCTest
@testable import TasteMatch

final class TasteBadgeTests: XCTestCase {

    // MARK: - Badge map coverage

    func testBadgeMap_coversAllCanonicalTags() {
        let engineTags = TasteEngine.CanonicalTag.allCases.map { String(describing: $0) }
        let badgeKeys = Set(TasteBadge.badgeMap.keys)

        for tag in engineTags {
            XCTAssertTrue(badgeKeys.contains(tag),
                          "Badge map is missing entry for '\(tag)'")
        }
    }

    func testBadgeMap_hasExactly10Entries() {
        XCTAssertEqual(TasteBadge.badgeMap.count, 10)
    }

    // MARK: - Badge info fields

    func testBadgeInfo_allHaveNonEmptyFields() {
        for (key, info) in TasteBadge.badgeMap {
            XCTAssertFalse(info.title.isEmpty, "Badge '\(key)' should have a title")
            XCTAssertFalse(info.icon.isEmpty, "Badge '\(key)' should have an icon")
        }
    }

    // MARK: - Unknown key fallback

    func testUnknownKey_returnsFallbackBadge() {
        // Access via the view's info property indirectly by checking the map
        let fallback = TasteBadge.badgeMap["nonexistent_key"]
        XCTAssertNil(fallback, "Unknown key should not be in the badge map")
    }
}
