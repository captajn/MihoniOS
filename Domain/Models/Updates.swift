import Foundation

public struct UpdatesWithRelations: Identifiable, Hashable, Sendable {
    public var mangaId: Int64
    public var mangaTitle: String
    public var chapterId: Int64
    public var chapterName: String
    public var scanlator: String?
    public var read: Bool
    public var bookmark: Bool
    public var lastPageRead: Int64
    public var sourceId: Int64
    public var dateFetch: Int64
    public var coverLastModified: Int64
    public var thumbnailUrl: String?

    public var id: Int64 { chapterId }

    public init(
        mangaId: Int64,
        mangaTitle: String,
        chapterId: Int64,
        chapterName: String,
        scanlator: String?,
        read: Bool,
        bookmark: Bool,
        lastPageRead: Int64,
        sourceId: Int64,
        dateFetch: Int64,
        coverLastModified: Int64,
        thumbnailUrl: String?
    ) {
        self.mangaId = mangaId
        self.mangaTitle = mangaTitle
        self.chapterId = chapterId
        self.chapterName = chapterName
        self.scanlator = scanlator
        self.read = read
        self.bookmark = bookmark
        self.lastPageRead = lastPageRead
        self.sourceId = sourceId
        self.dateFetch = dateFetch
        self.coverLastModified = coverLastModified
        self.thumbnailUrl = thumbnailUrl
    }
}
