import Foundation
import Core
import Domain

public struct ReaderChapterRef: Identifiable, Hashable, Sendable {
    public let id: Int64
    public let mangaId: Int64
    public let name: String
    public let url: String
    public let chapterNumber: Double
    public let lastPageRead: Int64
    public let sourceId: Int64

    public init(
        id: Int64,
        mangaId: Int64,
        name: String,
        url: String,
        chapterNumber: Double,
        lastPageRead: Int64,
        sourceId: Int64
    ) {
        self.id = id
        self.mangaId = mangaId
        self.name = name
        self.url = url
        self.chapterNumber = chapterNumber
        self.lastPageRead = lastPageRead
        self.sourceId = sourceId
    }

    public init(chapter: Chapter, sourceId: Int64) {
        self.id = chapter.id
        self.mangaId = chapter.mangaId
        self.name = chapter.name
        self.url = chapter.url
        self.chapterNumber = chapter.chapterNumber
        self.lastPageRead = chapter.lastPageRead
        self.sourceId = sourceId
    }
}

public struct ReaderOpenRequest: Hashable, Sendable {
    public let mangaTitle: String
    public let chapter: ReaderChapterRef
    public let chapters: [ReaderChapterRef]
    public let readingMode: ReadingMode
    /// Absolute path for local chapter (directory or archive).
    public let localPath: URL?
    /// Online page list if not local.
    public let remotePages: [PageRef]

    public init(
        mangaTitle: String,
        chapter: ReaderChapterRef,
        chapters: [ReaderChapterRef] = [],
        readingMode: ReadingMode = .rightToLeft,
        localPath: URL? = nil,
        remotePages: [PageRef] = []
    ) {
        self.mangaTitle = mangaTitle
        self.chapter = chapter
        self.chapters = chapters
        self.readingMode = readingMode
        self.localPath = localPath
        self.remotePages = remotePages
    }
}

public struct PageRef: Hashable, Sendable {
    public let index: Int
    public let url: String
    public let imageUrl: String?

    public init(index: Int, url: String, imageUrl: String? = nil) {
        self.index = index
        self.url = url
        self.imageUrl = imageUrl
    }
}
