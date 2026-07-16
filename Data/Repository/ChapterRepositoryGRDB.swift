import Foundation
import GRDB
import Domain

public final class ChapterRepositoryGRDB: ChapterRepository, Sendable {
    private let db: AppDatabase

    public init(db: AppDatabase) {
        self.db = db
    }

    public func getChapter(id: Int64) async throws -> Chapter? {
        try await db.dbWriter.read { db in
            try ChapterRecord.fetchOne(db, key: id)?.toDomain()
        }
    }

    public func getChapters(mangaId: Int64) async throws -> [Chapter] {
        try await db.dbWriter.read { db in
            try ChapterRecord
                .filter(Column("manga_id") == mangaId)
                .order(Column("source_order"))
                .fetchAll(db)
                .map { $0.toDomain() }
        }
    }

    public func getBookmarkedChapters(mangaId: Int64) async throws -> [Chapter] {
        try await db.dbWriter.read { db in
            try ChapterRecord
                .filter(Column("manga_id") == mangaId && Column("bookmark") == true)
                .order(Column("source_order"))
                .fetchAll(db)
                .map { $0.toDomain() }
        }
    }

    public func insert(_ chapters: [Chapter]) async throws {
        try await db.dbWriter.write { db in
            for chapter in chapters {
                var record = ChapterRecord.fromDomain(chapter)
                record.lastModifiedAt = Int64(Date().timeIntervalSince1970)
                try record.insert(db)
            }
        }
    }

    public func update(_ chapter: Chapter) async throws {
        try await db.dbWriter.write { db in
            var record = ChapterRecord.fromDomain(chapter)
            record.lastModifiedAt = Int64(Date().timeIntervalSince1970)
            try record.update(db)
        }
    }

    public func updateAll(_ chapters: [Chapter]) async throws {
        try await db.dbWriter.write { db in
            for chapter in chapters {
                var record = ChapterRecord.fromDomain(chapter)
                record.lastModifiedAt = Int64(Date().timeIntervalSince1970)
                try record.update(db)
            }
        }
    }

    public func removeChapters(ids: [Int64]) async throws {
        try await db.dbWriter.write { db in
            for id in ids {
                _ = try ChapterRecord.deleteOne(db, key: id)
            }
        }
    }
}
