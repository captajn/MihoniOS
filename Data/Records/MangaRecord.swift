import Foundation
import GRDB
import Domain

struct MangaRecord: Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    static let databaseTableName = "mangas"

    var id: Int64?
    var source: Int64
    var url: String
    var artist: String?
    var author: String?
    var description: String?
    var genre: String?
    var title: String
    var status: Int64
    var thumbnailUrl: String?
    var favorite: Bool
    var lastUpdate: Int64?
    var nextUpdate: Int64?
    var initialized: Bool
    var viewer: Int64
    var chapterFlags: Int64
    var coverLastModified: Int64
    var dateAdded: Int64
    var updateStrategy: Int
    var calculateInterval: Int
    var lastModifiedAt: Int64
    var favoriteModifiedAt: Int64?
    var version: Int64
    var isSyncing: Int
    var notes: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case source
        case url
        case artist
        case author
        case description
        case genre
        case title
        case status
        case thumbnailUrl = "thumbnail_url"
        case favorite
        case lastUpdate = "last_update"
        case nextUpdate = "next_update"
        case initialized
        case viewer
        case chapterFlags = "chapter_flags"
        case coverLastModified = "cover_last_modified"
        case dateAdded = "date_added"
        case updateStrategy = "update_strategy"
        case calculateInterval = "calculate_interval"
        case lastModifiedAt = "last_modified_at"
        case favoriteModifiedAt = "favorite_modified_at"
        case version
        case isSyncing = "is_syncing"
        case notes
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    func toDomain() -> Manga {
        let genres: [String]? = genre?
            .split(separator: ", ")
            .map(String.init)
        return Manga(
            id: id ?? -1,
            source: source,
            favorite: favorite,
            lastUpdate: lastUpdate ?? 0,
            nextUpdate: nextUpdate ?? 0,
            fetchInterval: calculateInterval,
            dateAdded: dateAdded,
            viewerFlags: viewer,
            chapterFlags: chapterFlags,
            coverLastModified: coverLastModified,
            url: url,
            title: title,
            artist: artist,
            author: author,
            description: description,
            genre: genres,
            status: status,
            thumbnailUrl: thumbnailUrl,
            updateStrategy: UpdateStrategy(rawValue: updateStrategy) ?? .alwaysUpdate,
            initialized: initialized,
            lastModifiedAt: lastModifiedAt,
            favoriteModifiedAt: favoriteModifiedAt,
            version: version,
            notes: notes
        )
    }

    static func fromDomain(_ manga: Manga) -> MangaRecord {
        MangaRecord(
            id: manga.id > 0 ? manga.id : nil,
            source: manga.source,
            url: manga.url,
            artist: manga.artist,
            author: manga.author,
            description: manga.description,
            genre: manga.genre?.joined(separator: ", "),
            title: manga.title,
            status: manga.status,
            thumbnailUrl: manga.thumbnailUrl,
            favorite: manga.favorite,
            lastUpdate: manga.lastUpdate,
            nextUpdate: manga.nextUpdate,
            initialized: manga.initialized,
            viewer: manga.viewerFlags,
            chapterFlags: manga.chapterFlags,
            coverLastModified: manga.coverLastModified,
            dateAdded: manga.dateAdded,
            updateStrategy: manga.updateStrategy.rawValue,
            calculateInterval: manga.fetchInterval,
            lastModifiedAt: manga.lastModifiedAt,
            favoriteModifiedAt: manga.favoriteModifiedAt,
            version: manga.version,
            isSyncing: 0,
            notes: manga.notes
        )
    }
}

struct ChapterRecord: Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    static let databaseTableName = "chapters"

    var id: Int64?
    var mangaId: Int64
    var url: String
    var name: String
    var scanlator: String?
    var read: Bool
    var bookmark: Bool
    var lastPageRead: Int64
    var chapterNumber: Double
    var sourceOrder: Int64
    var dateFetch: Int64
    var dateUpload: Int64
    var lastModifiedAt: Int64
    var version: Int64
    var isSyncing: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case mangaId = "manga_id"
        case url, name, scanlator, read, bookmark
        case lastPageRead = "last_page_read"
        case chapterNumber = "chapter_number"
        case sourceOrder = "source_order"
        case dateFetch = "date_fetch"
        case dateUpload = "date_upload"
        case lastModifiedAt = "last_modified_at"
        case version
        case isSyncing = "is_syncing"
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    func toDomain() -> Chapter {
        Chapter(
            id: id ?? -1,
            mangaId: mangaId,
            read: read,
            bookmark: bookmark,
            lastPageRead: lastPageRead,
            dateFetch: dateFetch,
            sourceOrder: sourceOrder,
            url: url,
            name: name,
            dateUpload: dateUpload,
            chapterNumber: chapterNumber,
            scanlator: scanlator,
            lastModifiedAt: lastModifiedAt,
            version: version
        )
    }

    static func fromDomain(_ chapter: Chapter) -> ChapterRecord {
        ChapterRecord(
            id: chapter.id > 0 ? chapter.id : nil,
            mangaId: chapter.mangaId,
            url: chapter.url,
            name: chapter.name,
            scanlator: chapter.scanlator,
            read: chapter.read,
            bookmark: chapter.bookmark,
            lastPageRead: chapter.lastPageRead,
            chapterNumber: chapter.chapterNumber,
            sourceOrder: chapter.sourceOrder,
            dateFetch: chapter.dateFetch,
            dateUpload: chapter.dateUpload,
            lastModifiedAt: chapter.lastModifiedAt,
            version: chapter.version,
            isSyncing: 0
        )
    }
}

struct CategoryRecord: Codable, FetchableRecord, MutablePersistableRecord, Sendable {
    static let databaseTableName = "categories"

    var id: Int64
    var name: String
    var sort: Int64
    var flags: Int64

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case sort
        case flags
    }

    func toDomain() -> Domain.Category {
        Domain.Category(id: id, name: name, order: sort, flags: flags)
    }

    static func fromDomain(_ category: Domain.Category) -> CategoryRecord {
        CategoryRecord(
            id: category.id,
            name: category.name,
            sort: category.order,
            flags: category.flags
        )
    }
}
