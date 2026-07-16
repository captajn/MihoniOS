import Foundation

/// Source-layer manga (not yet persisted). Mirrors Android `SManga`.
public struct SManga: Hashable, Sendable, Codable {
    public var url: String
    public var title: String
    public var artist: String?
    public var author: String?
    public var description: String?
    public var genre: String?
    public var status: Int
    public var thumbnailUrl: String?
    public var updateStrategy: Int
    public var initialized: Bool

    public init(
        url: String = "",
        title: String = "",
        artist: String? = nil,
        author: String? = nil,
        description: String? = nil,
        genre: String? = nil,
        status: Int = 0,
        thumbnailUrl: String? = nil,
        updateStrategy: Int = 0,
        initialized: Bool = false
    ) {
        self.url = url
        self.title = title
        self.artist = artist
        self.author = author
        self.description = description
        self.genre = genre
        self.status = status
        self.thumbnailUrl = thumbnailUrl
        self.updateStrategy = updateStrategy
        self.initialized = initialized
    }

    public static let unknown = 0
    public static let ongoing = 1
    public static let completed = 2
    public static let licensed = 3
    public static let publishingFinished = 4
    public static let cancelled = 5
    public static let onHiatus = 6
}

public struct SChapter: Hashable, Sendable, Codable {
    public var url: String
    public var name: String
    public var dateUpload: Int64
    public var chapterNumber: Double
    public var scanlator: String?

    public init(
        url: String = "",
        name: String = "",
        dateUpload: Int64 = 0,
        chapterNumber: Double = -1,
        scanlator: String? = nil
    ) {
        self.url = url
        self.name = name
        self.dateUpload = dateUpload
        self.chapterNumber = chapterNumber
        self.scanlator = scanlator
    }
}

public struct Page: Identifiable, Hashable, Sendable {
    public var index: Int
    public var url: String
    public var imageUrl: String?
    public var status: PageStatus

    public var id: Int { index }

    public init(index: Int, url: String = "", imageUrl: String? = nil, status: PageStatus = .queue) {
        self.index = index
        self.url = url
        self.imageUrl = imageUrl
        self.status = status
    }
}

public enum PageStatus: String, Sendable {
    case queue
    case loadPage
    case downloadImage
    case ready
    case error
}

public struct MangasPage: Sendable {
    public var mangas: [SManga]
    public var hasNextPage: Bool

    public init(mangas: [SManga], hasNextPage: Bool) {
        self.mangas = mangas
        self.hasNextPage = hasNextPage
    }
}

public struct SMangaUpdate: Sendable {
    public var manga: SManga
    public var chapters: [SChapter]?

    public init(manga: SManga, chapters: [SChapter]? = nil) {
        self.manga = manga
        self.chapters = chapters
    }
}
