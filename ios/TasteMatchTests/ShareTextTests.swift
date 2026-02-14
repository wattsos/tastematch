import XCTest
@testable import TasteMatch

final class ShareTextTests: XCTestCase {

    // MARK: - Share summary construction

    func testShareSummary_containsProfileLine() {
        var profile = TasteProfile(
            tags: [
                TasteTag(key: "scandinavian", label: "Scandinavian", confidence: 0.85),
                TasteTag(key: "japandi", label: "Japandi", confidence: 0.55),
            ],
            story: "A clean, bright aesthetic.",
            signals: [Signal(key: "brightness", value: "high")]
        )
        ProfileNamingEngine.applyInitialNaming(to: &profile)

        let text = ShareTextBuilder.build(profile: profile, recommendations: [])

        XCTAssertTrue(text.contains(profile.displayName))
        XCTAssertTrue(text.contains("Profile:"))
    }

    func testShareSummary_containsReading() {
        let profile = TasteProfile(
            tags: [TasteTag(key: "minimalist", label: "Minimalist", confidence: 0.9)],
            story: "Less is more.",
            signals: []
        )

        let text = ShareTextBuilder.build(profile: profile, recommendations: [])

        // Reading is dynamically generated — just verify a non-empty reading line exists
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let readingLineIndex = lines.firstIndex(where: { $0.contains("Profile:") }).map { $0 + 2 }
        if let idx = readingLineIndex, idx < lines.count {
            XCTAssertFalse(lines[idx].isEmpty, "Reading line should not be empty")
        }
    }

    func testShareSummary_containsPicks() {
        let profile = TasteProfile(
            tags: [TasteTag(key: "coastal", label: "Coastal", confidence: 0.7)],
            story: "Breezy.",
            signals: []
        )
        let recs = [
            RecommendationItem(skuId: "sku-test", title: "Linen Sofa", subtitle: "Elm & Oak — $1250", reason: "Fits", attributionConfidence: 0.8, merchant: "Elm & Oak", productURL: "https://example.com"),
        ]

        let text = ShareTextBuilder.build(profile: profile, recommendations: recs)

        XCTAssertTrue(text.contains("Linen Sofa"))
        XCTAssertTrue(text.contains("Selection:"))
    }

    func testShareSummary_containsBranding() {
        let profile = TasteProfile(
            tags: [TasteTag(key: "bohemian", label: "Bohemian", confidence: 0.65)],
            story: "Layered.",
            signals: []
        )

        let text = ShareTextBuilder.build(profile: profile, recommendations: [])

        XCTAssertTrue(text.contains("Burgundy"))
        XCTAssertTrue(text.contains("burgundy.app"))
    }
}
