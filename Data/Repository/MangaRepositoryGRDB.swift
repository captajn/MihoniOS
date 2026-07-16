import Foundation
import GRDB
import Domain

public final class MangaRepositoryGRDB: MangaRepository, Sendable {
    private let db: AppDatabase

    public init(db: AppDatabase) {
        self.db = db
    }

    public func getManga(id: Int64) async throws -> Manga? {
        try await db.dbWriter.read { db in
            try MangaRecord.fetchOne(db, key: id)?.toDomain()
        }
    }

    public func getManga(url: String, sourceId: Int64) async throws -> Manga? {
        try await db.dbWriter.read { db in
            try MangaRecord
                .filter(Column("url") == url && Column("source") == sourceId)
                .fetchOne(db)?
                .toDomain()
        }
    }

    public func getFavorites() async throws -> [Manga] {
        try await db.dbWriter.read { db in
            try MangaRecord
                .filter(Column("favorite") == true)
                .order(Column("title"))
                .fetchAll(db)
                .map { $0.toDomain() }
        }
    }

    public func getLibraryManga() async throws -> [LibraryManga] {
        try await db.dbWriter.read { db in
            let favorites = try MangaRecord
                .filter(Column("favorite") == true)
                .order(Column("title"))
                .fetchAll(db)

            return try favorites.map { record in
                let manga = record.toDomain()
                let mangaId = manga.id

                let total = try Int.fetchOne(
                    db,
                    sql: "SELECT COUNT(*) FROM chapters WHERE manga_id = ?",
                    arguments: [mangaId]
                ) ?? 0
                let readCount = try Int.fetchOne(
                    db,
                    sql: "SELECT COUNT(*) FROM chapters WHERE manga_id = ? AND read = 1",
                    arguments: [mangaId]
                ) ?? 0
                let bookmarkCount = try Int.fetchOne(
                    db,
                    sql: "SELECT COUNT(*) FROM chapters WHERE manga_id = ? AND bookmark = 1",
                    arguments: [mangaId]
                ) ?? 0
                let latestUpload = try Int64.fetchOne(
                    db,
                    sql: "SELECT MAX(date_upload) FROM chapters WHERE manga_id = ?",
                    arguments: [mangaId]
                ) ?? 0
                let chapterFetchedAt = try Int64.fetchOne(
                    db,
                    sql: "SELECT MAX(date_fetch) FROM chapters WHERE manga_id = ?",
                    arguments: [mangaId]
                ) ?? 0
                let lastRead = try Int64.fetchOne(
                    db,
                    sql: """
                    SELECT MAX(h.last_read) FROM history h
                    JOIN chapters c ON c._id = h.chapter_id
                    WHERE c.manga_id = ?
                    """,
                    arguments: [mangaId]
                ) ?? 0
                let categoryIds = try Int64.fetchAll(
                    db,
                    sql: "SELECT category_id FROM mangas_categories WHERE manga_id = ?",
                    arguments: [mangaId]
                )

                return LibraryManga(
                    manga: manga,
                    categories: categoryIds,
                    totalChapters: total,
                    readCount: readCount,
                    bookmarkCount: bookmarkCount,
                    latestUpload: latestUpload,
                    chapterFetchedAt: chapterFetchedAt,
                    lastRead: lastRead
                )
            }
        }
    }

    public func insert(_ manga: Manga) async throws -> Int64 {
        try await db.dbWriter.write { db in
            var record = MangaRecord.fromDomain(manga)
            record.lastModifiedAt = Int64(Date().timeIntervalSince1970)
            try record.insert(db)
            return record.id!
        }
    }

    public func update(_ manga: Manga) async throws {
        try await db.dbWriter.write { db in
            var record = MangaRecord.fromDomain(manga)
            record.lastModifiedAt = Int64(Date().timeIntervalSince1970)
            try record.update(db)
        }
    }

    public func partialUpdate(
        id: Int64,
        favorite: Bool?,
        viewerFlags: Int64?,
        chapterFlags: Int64?,
        notes: String?
    ) async throws {
        try await db.dbWriter.write { db in
            guard var record = try MangaRecord.fetchOne(db, key: id) else { return }
            if let favorite { record.favorite = favorite }
            if let viewerFlags { record.viewer = viewerFlags }
            if let chapterFlags { record.chapterFlags = chapterFlags }
            if let notes { record.notes = notes }
            record.lastModifiedAt = Int64(Date().timeIntervalSince1970)
            try record.update(db)
        }
    }

    public func delete(id: Int64) async throws {
        try await db.dbWriter.write { db in
            _ = try MangaRecord.deleteOne(db, key: id)
        }
    }
}
