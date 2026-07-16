import Foundation

public struct History: Identifiable, Hashable, Sendable, Codable {
    public var id: Int64
    public var chapterId: Int64
    public var readAt: Int64?
    public var readDuration: Int64

    public init(id: Int64 = -1, chapterId: Int64, readAt: Int64? = nil, readDuration: Int64 = 0) {
        self.id = id
        self.chapterId = chapterId
        self.readAt = readAt
        self.readDuration = readDuration
    }
}

public struct HistoryWithRelations: Identifiable, Hashable, Sendable {
    public var id: Int64
    public var chapterId: Int64
    public var readAt: Int64?
    public var readDuration: Int64
    public var chapterName: String
    public var chapterNumber: Double
    public var mangaId: Int64
    public var mangaTitle: String
    public var mangaThumbnailUrl: String?
    public var sourceId: Int64
    public var coverLastModified: Int64

    public init(
        id: Int64,
        chapterId: Int64,
        readAt: Int64?,
        readDuration: Int64,
        chapterName: String,
        chapterNumber: Double,
        mangaId: Int64,
        mangaTitle: String,
        mangaThumbnailUrl: String?,
        sourceId: Int64,
        coverLastModified: Int64
    ) {
        self.id = id
        self.chapterId = chapterId
        self.readAt = readAt
        self.readDuration = readDuration
        self.chapterName = chapterName
        self.chapterNumber = chapterNumber
        self.mangaId = mangaId
        self.mangaTitle = mangaTitle
        self.mangaThumbnailUrl = mangaThumbnailUrl
        self.sourceId = sourceId
        self.coverLastModified = coverLastModified
    }
}
