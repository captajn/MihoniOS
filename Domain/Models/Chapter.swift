import Foundation

/// Domain chapter — aligns with Android `Chapter`.
public struct Chapter: Identifiable, Hashable, Sendable, Codable {
    public var id: Int64
    public var mangaId: Int64
    public var read: Bool
    public var bookmark: Bool
    public var lastPageRead: Int64
    public var dateFetch: Int64
    public var sourceOrder: Int64
    public var url: String
    public var name: String
    public var dateUpload: Int64
    public var chapterNumber: Double
    public var scanlator: String?
    public var lastModifiedAt: Int64
    public var version: Int64

    public init(
        id: Int64 = -1,
        mangaId: Int64 = -1,
        read: Bool = false,
        bookmark: Bool = false,
        lastPageRead: Int64 = 0,
        dateFetch: Int64 = 0,
        sourceOrder: Int64 = 0,
        url: String = "",
        name: String = "",
        dateUpload: Int64 = -1,
        chapterNumber: Double = -1,
        scanlator: String? = nil,
        lastModifiedAt: Int64 = 0,
        version: Int64 = 1
    ) {
        self.id = id
        self.mangaId = mangaId
        self.read = read
        self.bookmark = bookmark
        self.lastPageRead = lastPageRead
        self.dateFetch = dateFetch
        self.sourceOrder = sourceOrder
        self.url = url
        self.name = name
        self.dateUpload = dateUpload
        self.chapterNumber = chapterNumber
        self.scanlator = scanlator
        self.lastModifiedAt = lastModifiedAt
        self.version = version
    }

    public var isRecognizedNumber: Bool { chapterNumber >= 0 }

    public static func create(mangaId: Int64) -> Chapter {
        Chapter(mangaId: mangaId)
    }
}
