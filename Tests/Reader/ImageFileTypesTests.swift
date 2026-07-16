import XCTest
@testable import Reader

final class ImageFileTypesTests: XCTestCase {
    func testImageExtensions() {
        XCTAssertTrue(ImageFileTypes.isImage(URL(fileURLWithPath: "/a/b/page01.jpg")))
        XCTAssertTrue(ImageFileTypes.isImage(URL(fileURLWithPath: "/a/b/page01.PNG")))
        XCTAssertTrue(ImageFileTypes.isImage(URL(fileURLWithPath: "/a/b/page01.webp")))
        XCTAssertFalse(ImageFileTypes.isImage(URL(fileURLWithPath: "/a/b/note.txt")))
        XCTAssertFalse(ImageFileTypes.isImage(URL(fileURLWithPath: "/a/b/chapter.cbz")))
    }
}
