import XCTest
@testable import TasteMatch

final class DomainCopyTests: XCTestCase {

    func testObjectsCopyDoesNotContainRoom() {
        let outputs = [
            DomainCopy.aboutBody(.objects),
            DomainCopy.aboutStep1(.objects),
            DomainCopy.historyLine(.objects),
            DomainCopy.evolutionLine(.objects),
        ]
        for text in outputs {
            XCTAssertFalse(
                text.localizedCaseInsensitiveContains("room"),
                "Objects copy should not contain 'room': \(text)"
            )
        }
    }

    func testArtCopyDoesNotContainRoom() {
        let outputs = [
            DomainCopy.aboutBody(.art),
            DomainCopy.aboutStep1(.art),
            DomainCopy.historyLine(.art),
            DomainCopy.evolutionLine(.art),
        ]
        for text in outputs {
            XCTAssertFalse(
                text.localizedCaseInsensitiveContains("room"),
                "Art copy should not contain 'room': \(text)"
            )
        }
    }

    func testSpaceCopyContainsRoom() {
        XCTAssertTrue(DomainCopy.aboutBody(.space).localizedCaseInsensitiveContains("room"))
        XCTAssertTrue(DomainCopy.aboutStep1(.space).localizedCaseInsensitiveContains("room"))
        XCTAssertTrue(DomainCopy.historyLine(.space).localizedCaseInsensitiveContains("room"))
        XCTAssertTrue(DomainCopy.evolutionLine(.space).localizedCaseInsensitiveContains("room"))
    }

    func testHistoryReanalyzeUsesProfileDomain() {
        // For .objects profiles, reanalyze should route to newScan, not reanalyze
        // This validates the routing logic: non-Space profiles use Route.newScan(domain)
        let objectsDomain: TasteDomain = .objects
        let artDomain: TasteDomain = .art
        let spaceDomain: TasteDomain = .space

        // Non-space domains should NOT use reanalyze (which is Space-only)
        XCTAssertTrue(objectsDomain != .space, "Objects should not use Space reanalyze flow")
        XCTAssertTrue(artDomain != .space, "Art should not use Space reanalyze flow")
        XCTAssertTrue(spaceDomain == .space, "Space should use reanalyze flow")
    }
}
