import XCTest
@testable import Domain

final class DomainModelTests: XCTestCase {
    func testLibraryMangaUnreadCount() {
        let manga = Manga(id: 1, title: "Test")
        let item = LibraryManga(manga: manga, totalChapters: 10, readCount: 3)
        XCTAssertEqual(item.unreadCount, 7)
        XCTAssertTrue(item.hasUnread)
    }

    func testChapterRecognizedNumber() {
        var chapter = Chapter(chapterNumber: 12.5)
        XCTAssertTrue(chapter.isRecognizedNumber)
        chapter.chapterNumber = -1
        XCTAssertFalse(chapter.isRecognizedNumber)
    }

    func testSystemCategoryProtected() {
        XCTAssertTrue(Category.defaultCategory.isSystemCategory)
    }

    func testTrackerIdsMatchAndroid() {
        XCTAssertEqual(TrackerId.myAnimeList.rawValue, 1)
        XCTAssertEqual(TrackerId.aniList.rawValue, 2)
        XCTAssertEqual(TrackerId.kitsu.rawValue, 3)
        XCTAssertEqual(TrackerId.mangaBaka.rawValue, 11)
    }
}
