import Foundation
import GRDB
import Domain

// MARK: - Category

public final class CategoryRepositoryGRDB: CategoryRepository, Sendable {
    private let db: AppDatabase

    public init(db: AppDatabase) {
        self.db = db
    }

    public func getAll() async throws -> [Domain.Category] {
        try await db.dbWriter.read { db in
            try CategoryRecord
                .order(Column("sort"))
                .fetchAll(db)
                .map { $0.toDomain() }
        }
    }

    public func getCategories(mangaId: Int64) async throws -> [Domain.Category] {
        try await db.dbWriter.read { db in
            try CategoryRecord.fetchAll(
                db,
                sql: """
                SELECT C.* FROM categories C
                JOIN mangas_categories MC ON MC.category_id = C._id
                WHERE MC.manga_id = ?
                ORDER BY C.sort
                """,
                arguments: [mangaId]
            )
            .map { $0.toDomain() }
        }
    }

    public func insert(_ category: Domain.Category) async throws -> Int64 {
        try await db.dbWriter.write { db in
            // Allocate next id > 0
            let maxId = try Int64.fetchOne(db, sql: "SELECT MAX(_id) FROM categories") ?? 0
            let newId = max(maxId + 1, 1)
            var record = CategoryRecord(
                id: newId,
                name: category.name,
                sort: category.order,
                flags: category.flags
            )
            try record.insert(db)
            return newId
        }
    }

    public func update(_ category: Domain.Category) async throws {
        try await db.dbWriter.write { db in
            try CategoryRecord.fromDomain(category).update(db)
        }
    }

    public func delete(id: Int64) async throws {
        guard id > 0 else { return }
        try await db.dbWriter.write { db in
            _ = try CategoryRecord.deleteOne(db, key: id)
        }
    }

    public func setMangaCategories(mangaId: Int64, categoryIds: [Int64]) async throws {
        try await db.dbWriter.write { db in
            try db.execute(sql: "DELETE FROM mangas_categories WHERE manga_id = ?", arguments: [mangaId])
            for categoryId in categoryIds where categoryId > 0 {
                try db.execute(
                    sql: "INSERT INTO mangas_categories(manga_id, category_id) VALUES (?, ?)",
                    arguments: [mangaId, categoryId]
                )
            }
        }
    }
}

// MARK: - History

public final class HistoryRepositoryGRDB: HistoryRepository, Sendable {
    private let db: AppDatabase

    public init(db: AppDatabase) {
        self.db = db
    }

    public func getHistory(query: String) async throws -> [HistoryWithRelations] {
        try await db.dbWriter.read { db in
            let sql: String
            let arguments: StatementArguments
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sql = """
                SELECT H._id AS id, H.chapter_id, H.last_read, H.time_read,
                       C.name AS chapter_name, C.chapter_number,
                       M._id AS manga_id, M.title AS manga_title, M.thumbnail_url,
                       M.source AS source_id, M.cover_last_modified
                FROM history H
                JOIN chapters C ON C._id = H.chapter_id
                JOIN mangas M ON M._id = C.manga_id
                WHERE H.last_read > 0
                ORDER BY H.last_read DESC
                """
                arguments = StatementArguments()
            } else {
                sql = """
                SELECT H._id AS id, H.chapter_id, H.last_read, H.time_read,
                       C.name AS chapter_name, C.chapter_number,
                       M._id AS manga_id, M.title AS manga_title, M.thumbnail_url,
                       M.source AS source_id, M.cover_last_modified
                FROM history H
                JOIN chapters C ON C._id = H.chapter_id
                JOIN mangas M ON M._id = C.manga_id
                WHERE H.last_read > 0 AND M.title LIKE ?
                ORDER BY H.last_read DESC
                """
                arguments = ["%\(query)%"]
            }

            let rows = try Row.fetchAll(db, sql: sql, arguments: arguments)
            return rows.map { row in
                HistoryWithRelations(
                    id: row["id"],
                    chapterId: row["chapter_id"],
                    readAt: row["last_read"],
                    readDuration: row["time_read"],
                    chapterName: row["chapter_name"],
                    chapterNumber: row["chapter_number"],
                    mangaId: row["manga_id"],
                    mangaTitle: row["manga_title"],
                    mangaThumbnailUrl: row["thumbnail_url"],
                    sourceId: row["source_id"],
                    coverLastModified: row["cover_last_modified"]
                )
            }
        }
    }

    public func getHistory(mangaId: Int64) async throws -> [History] {
        try await db.dbWriter.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT H._id, H.chapter_id, H.last_read, H.time_read
                FROM history H
                JOIN chapters C ON C._id = H.chapter_id
                WHERE C.manga_id = ?
                """,
                arguments: [mangaId]
            )
            return rows.map { row in
                History(
                    id: row["_id"],
                    chapterId: row["chapter_id"],
                    readAt: row["last_read"],
                    readDuration: row["time_read"]
                )
            }
        }
    }

    public func upsert(_ history: History) async throws {
        try await db.dbWriter.write { db in
            let existingId = try Int64.fetchOne(
                db,
                sql: "SELECT _id FROM history WHERE chapter_id = ?",
                arguments: [history.chapterId]
            )
            if let existingId {
                try db.execute(
                    sql: """
                    UPDATE history SET last_read = ?, time_read = time_read + ?
                    WHERE _id = ?
                    """,
                    arguments: [history.readAt ?? 0, history.readDuration, existingId]
                )
            } else {
                try db.execute(
                    sql: """
                    INSERT INTO history(chapter_id, last_read, time_read)
                    VALUES (?, ?, ?)
                    """,
                    arguments: [history.chapterId, history.readAt ?? 0, history.readDuration]
                )
            }
        }
    }

    public func removeHistory(ids: [Int64]) async throws {
        try await db.dbWriter.write { db in
            for id in ids {
                try db.execute(sql: "DELETE FROM history WHERE _id = ?", arguments: [id])
            }
        }
    }

    public func removeAll() async throws {
        try await db.dbWriter.write { db in
            try db.execute(sql: "DELETE FROM history")
        }
    }

    public func getTotalReadDuration() async throws -> Int64 {
        try await db.dbWriter.read { db in
            try Int64.fetchOne(db, sql: "SELECT COALESCE(SUM(time_read), 0) FROM history") ?? 0
        }
    }
}

// MARK: - Updates

public final class UpdatesRepositoryGRDB: UpdatesRepository, Sendable {
    private let db: AppDatabase

    public init(db: AppDatabase) {
        self.db = db
    }

    public func awaitUpdates(after: Int64, limit: Int) async throws -> [UpdatesWithRelations] {
        try await db.dbWriter.read { db in
            let rows = try Row.fetchAll(
                db,
                sql: """
                SELECT M._id AS manga_id, M.title AS manga_title, M.thumbnail_url,
                       M.source AS source_id, M.cover_last_modified,
                       C._id AS chapter_id, C.name AS chapter_name, C.scanlator,
                       C.read, C.bookmark, C.last_page_read, C.date_fetch
                FROM chapters C
                JOIN mangas M ON M._id = C.manga_id
                WHERE M.favorite = 1 AND C.date_fetch > ?
                ORDER BY C.date_fetch DESC
                LIMIT ?
                """,
                arguments: [after, limit]
            )
            return rows.map { row in
                UpdatesWithRelations(
                    mangaId: row["manga_id"],
                    mangaTitle: row["manga_title"],
                    chapterId: row["chapter_id"],
                    chapterName: row["chapter_name"],
                    scanlator: row["scanlator"],
                    read: row["read"],
                    bookmark: row["bookmark"],
                    lastPageRead: row["last_page_read"],
                    sourceId: row["source_id"],
                    dateFetch: row["date_fetch"],
                    coverLastModified: row["cover_last_modified"],
                    thumbnailUrl: row["thumbnail_url"]
                )
            }
        }
    }
}

// MARK: - Track

public final class TrackRepositoryGRDB: TrackRepository, Sendable {
    private let db: AppDatabase

    public init(db: AppDatabase) {
        self.db = db
    }

    public func getTracks(mangaId: Int64) async throws -> [Track] {
        try await db.dbWriter.read { db in
            try Row.fetchAll(
                db,
                sql: "SELECT * FROM manga_sync WHERE manga_id = ?",
                arguments: [mangaId]
            )
            .map(Self.mapTrack)
        }
    }

    public func getTracks() async throws -> [Track] {
        try await db.dbWriter.read { db in
            try Row.fetchAll(db, sql: "SELECT * FROM manga_sync")
                .map(Self.mapTrack)
        }
    }

    public func insert(_ track: Track) async throws -> Int64 {
        try await db.dbWriter.write { db in
            try db.execute(
                sql: """
                INSERT INTO manga_sync(
                    manga_id, sync_id, remote_id, library_id, title,
                    last_chapter_read, total_chapters, score, status,
                    started_reading_date, finished_reading_date, tracking_url, private
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    track.mangaId, track.syncId, track.mediaId, track.libraryId, track.title,
                    track.lastChapterRead, track.totalChapters, track.score, track.status,
                    track.startedReadingDate, track.finishedReadingDate, track.trackingUrl, track.privateTrack,
                ]
            )
            return db.lastInsertedRowID
        }
    }

    public func delete(id: Int64) async throws {
        try await db.dbWriter.write { db in
            try db.execute(sql: "DELETE FROM manga_sync WHERE _id = ?", arguments: [id])
        }
    }

    public func delete(mangaId: Int64, syncId: Int64) async throws {
        try await db.dbWriter.write { db in
            try db.execute(
                sql: "DELETE FROM manga_sync WHERE manga_id = ? AND sync_id = ?",
                arguments: [mangaId, syncId]
            )
        }
    }

    private static func mapTrack(_ row: Row) -> Track {
        Track(
            id: row["_id"],
            mangaId: row["manga_id"],
            syncId: row["sync_id"],
            mediaId: row["remote_id"],
            libraryId: row["library_id"],
            title: row["title"],
            lastChapterRead: row["last_chapter_read"],
            totalChapters: row["total_chapters"],
            score: row["score"],
            status: row["status"],
            startedReadingDate: row["started_reading_date"],
            finishedReadingDate: row["finished_reading_date"],
            trackingUrl: row["tracking_url"],
            privateTrack: row["private"]
        )
    }
}

// MARK: - Source metadata

public final class SourceRepositoryGRDB: SourceRepository, Sendable {
    private let db: AppDatabase

    public init(db: AppDatabase) {
        self.db = db
    }

    public func getSources() async throws -> [SourceInfo] {
        try await db.dbWriter.read { db in
            try Row.fetchAll(db, sql: "SELECT * FROM sources ORDER BY name").map { row in
                SourceInfo(
                    id: row["_id"],
                    lang: row["lang"] ?? "",
                    name: row["name"],
                    isStub: true
                )
            }
        }
    }

    public func getStubSources() async throws -> [SourceInfo] {
        try await getSources()
    }

    public func upsertStubSource(_ source: SourceInfo) async throws {
        try await db.dbWriter.write { db in
            try db.execute(
                sql: """
                INSERT INTO sources(_id, lang, name) VALUES (?, ?, ?)
                ON CONFLICT(_id) DO UPDATE SET lang = excluded.lang, name = excluded.name
                """,
                arguments: [source.id, source.lang, source.name]
            )
        }
    }
}
