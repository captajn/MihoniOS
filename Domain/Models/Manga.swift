import Foundation

/// Domain manga entity — fields align with Android `tachiyomi.domain.manga.model.Manga`.
public struct Manga: Identifiable, Hashable, Sendable, Codable {
    public var id: Int64
    public var source: Int64
    public var favorite: Bool
    public var lastUpdate: Int64
    public var nextUpdate: Int64
    public var fetchInterval: Int
    public var dateAdded: Int64
    public var viewerFlags: Int64
    public var chapterFlags: Int64
    public var coverLastModified: Int64
    public var url: String
    public var title: String
    public var artist: String?
    public var author: String?
    public var description: String?
    public var genre: [String]?
    public var status: Int64
    public var thumbnailUrl: String?
    public var updateStrategy: UpdateStrategy
    public var initialized: Bool
    public var lastModifiedAt: Int64
    public var favoriteModifiedAt: Int64?
    public var version: Int64
    public var notes: String

    public init(
        id: Int64 = -1,
        source: Int64 = 0,
        favorite: Bool = false,
        lastUpdate: Int64 = 0,
        nextUpdate: Int64 = 0,
        fetchInterval: Int = 0,
        dateAdded: Int64 = 0,
        viewerFlags: Int64 = 0,
        chapterFlags: Int64 = 0,
        coverLastModified: Int64 = 0,
        url: String = "",
        title: String = "",
        artist: String? = nil,
        author: String? = nil,
        description: String? = nil,
        genre: [String]? = nil,
        status: Int64 = 0,
        thumbnailUrl: String? = nil,
        updateStrategy: UpdateStrategy = .alwaysUpdate,
        initialized: Bool = false,
        lastModifiedAt: Int64 = 0,
        favoriteModifiedAt: Int64? = nil,
        version: Int64 = 0,
        notes: String = ""
    ) {
        self.id = id
        self.source = source
        self.favorite = favorite
        self.lastUpdate = lastUpdate
        self.nextUpdate = nextUpdate
        self.fetchInterval = fetchInterval
        self.dateAdded = dateAdded
        self.viewerFlags = viewerFlags
        self.chapterFlags = chapterFlags
        self.coverLastModified = coverLastModified
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
        self.lastModifiedAt = lastModifiedAt
        self.favoriteModifiedAt = favoriteModifiedAt
        self.version = version
        self.notes = notes
    }

    public static func create(source: Int64, url: String, title: String) -> Manga {
        Manga(source: source, url: url, title: title)
    }
}

/// Mirrors Android `UpdateStrategy`.
public enum UpdateStrategy: Int, Codable, Sendable, CaseIterable {
    case alwaysUpdate = 0
    case onlyFetchOnce = 1
}

/// Manga publication status (SManga constants).
public enum MangaStatus: Int64, Sendable {
    case unknown = 0
    case ongoing = 1
    case completed = 2
    case licensed = 3
    case publishingFinished = 4
    case cancelled = 5
    case onHiatus = 6
}

/// Library row with chapter aggregates (libraryView).
public struct LibraryManga: Identifiable, Hashable, Sendable {
    public var manga: Manga
    public var categories: [Int64]
    public var totalChapters: Int
    public var readCount: Int
    public var bookmarkCount: Int
    public var latestUpload: Int64
    public var chapterFetchedAt: Int64
    public var lastRead: Int64

    public var id: Int64 { manga.id }

    public var unreadCount: Int { max(0, totalChapters - readCount) }

    public var hasUnread: Bool { unreadCount > 0 }

    public init(
        manga: Manga,
        categories: [Int64] = [],
        totalChapters: Int = 0,
        readCount: Int = 0,
        bookmarkCount: Int = 0,
        latestUpload: Int64 = 0,
        chapterFetchedAt: Int64 = 0,
        lastRead: Int64 = 0
    ) {
        self.manga = manga
        self.categories = categories
        self.totalChapters = totalChapters
        self.readCount = readCount
        self.bookmarkCount = bookmarkCount
        self.latestUpload = latestUpload
        self.chapterFetchedAt = chapterFetchedAt
        self.lastRead = lastRead
    }
}
