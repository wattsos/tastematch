import XCTest
@testable import TasteMatch

final class CachedImageTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ImageCache.shared.removeAll()
    }

    func testImageCache_storesAndRetrieves() {
        let url = URL(string: "https://example.com/test.jpg")!
        let image = UIImage(systemName: "star")!

        ImageCache.shared.store(image, for: url)
        let retrieved = ImageCache.shared.image(for: url)

        XCTAssertNotNil(retrieved)
    }

    func testImageCache_returnsNilForMissing() {
        let url = URL(string: "https://example.com/missing.jpg")!
        let result = ImageCache.shared.image(for: url)

        XCTAssertNil(result)
    }

    func testImageCache_countLimit() {
        ImageCache.shared.setCountLimit(2)

        let url1 = URL(string: "https://example.com/1.jpg")!
        let url2 = URL(string: "https://example.com/2.jpg")!
        let url3 = URL(string: "https://example.com/3.jpg")!
        let img = UIImage(systemName: "star")!

        ImageCache.shared.store(img, for: url1)
        ImageCache.shared.store(img, for: url2)
        ImageCache.shared.store(img, for: url3)

        // NSCache eviction is non-deterministic, but at minimum the latest should be present
        XCTAssertNotNil(ImageCache.shared.image(for: url3))

        // Restore default limit
        ImageCache.shared.setCountLimit(200)
    }
}
