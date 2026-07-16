import Foundation
import GRDB
import Core

/// Application database wrapper.
public final class AppDatabase: Sendable {
    public let dbWriter: any DatabaseWriter

    public init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try migrator.migrate(dbWriter)
    }

    /// Open (or create) the main app database under Application Support.
    public static func makeDefault() throws -> AppDatabase {
        let fm = FileManager.default
        let support = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = support.appendingPathComponent("mihon", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let dbURL = dir.appendingPathComponent("mihon.db")
        AppLog.info("Opening database at \(dbURL.path)", category: "db")

        var config = Configuration()
        config.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        let pool = try DatabasePool(path: dbURL.path, configuration: config)
        return try AppDatabase(pool)
    }

    /// In-memory DB for tests.
    public static func makeEmpty() throws -> AppDatabase {
        let db = try DatabaseQueue()
        return try AppDatabase(db)
    }

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial") { db in
            try db.create(table: "mangas") { t in
                t.autoIncrementedPrimaryKey("_id")
                t.column("source", .integer).notNull()
                t.column("url", .text).notNull()
                t.column("artist", .text)
                t.column("author", .text)
                t.column("description", .text)
                t.column("genre", .text)
                t.column("title", .text).notNull()
                t.column("status", .integer).notNull()
                t.column("thumbnail_url", .text)
                t.column("favorite", .boolean).notNull()
                t.column("last_update", .integer)
                t.column("next_update", .integer)
                t.column("initialized", .boolean).notNull()
                t.column("viewer", .integer).notNull()
                t.column("chapter_flags", .integer).notNull()
                t.column("cover_last_modified", .integer).notNull()
                t.column("date_added", .integer).notNull()
                t.column("update_strategy", .integer).notNull().defaults(to: 0)
                t.column("calculate_interval", .integer).notNull().defaults(to: 0)
                t.column("last_modified_at", .integer).notNull().defaults(to: 0)
                t.column("favorite_modified_at", .integer)
                t.column("version", .integer).notNull().defaults(to: 0)
                t.column("is_syncing", .integer).notNull().defaults(to: 0)
                t.column("notes", .text).notNull().defaults(to: "")
            }
            try db.create(index: "library_favorite_index", on: "mangas", columns: ["favorite"])
            try db.create(index: "mangas_url_index", on: "mangas", columns: ["url"])
            try db.create(index: "idx_mangas_source", on: "mangas", columns: ["source"])

            try db.create(table: "chapters") { t in
                t.autoIncrementedPrimaryKey("_id")
                t.column("manga_id", .integer).notNull()
                    .references("mangas", onDelete: .cascade)
                t.column("url", .text).notNull()
                t.column("name", .text).notNull()
                t.column("scanlator", .text)
                t.column("read", .boolean).notNull()
                t.column("bookmark", .boolean).notNull()
                t.column("last_page_read", .integer).notNull()
                t.column("chapter_number", .double).notNull()
                t.column("source_order", .integer).notNull()
                t.column("date_fetch", .integer).notNull()
                t.column("date_upload", .integer).notNull()
                t.column("last_modified_at", .integer).notNull().defaults(to: 0)
                t.column("version", .integer).notNull().defaults(to: 0)
                t.column("is_syncing", .integer).notNull().defaults(to: 0)
            }
            try db.create(index: "chapters_manga_id_index", on: "chapters", columns: ["manga_id"])
            try db.create(index: "idx_chapters_url", on: "chapters", columns: ["url"])

            try db.create(table: "categories") { t in
                t.primaryKey("_id", .integer)
                t.column("name", .text).notNull()
                t.column("sort", .integer).notNull()
                t.column("flags", .integer).notNull()
            }
            try db.execute(sql: """
                INSERT OR IGNORE INTO categories(_id, name, sort, flags) VALUES (0, '', -1, 0)
                """)

            try db.create(table: "mangas_categories") { t in
                t.column("manga_id", .integer).notNull()
                    .references("mangas", onDelete: .cascade)
                t.column("category_id", .integer).notNull()
                    .references("categories", onDelete: .cascade)
                t.primaryKey(["manga_id", "category_id"])
            }

            try db.create(table: "history") { t in
                t.autoIncrementedPrimaryKey("_id")
                t.column("chapter_id", .integer).notNull().unique()
                    .references("chapters", onDelete: .cascade)
                t.column("last_read", .integer)
                t.column("time_read", .integer).notNull()
            }
            try db.create(index: "history_history_chapter_id_index", on: "history", columns: ["chapter_id"])

            try db.create(table: "manga_sync") { t in
                t.autoIncrementedPrimaryKey("_id")
                t.column("manga_id", .integer).notNull()
                    .references("mangas", onDelete: .cascade)
                t.column("sync_id", .integer).notNull()
                t.column("remote_id", .integer).notNull()
                t.column("library_id", .integer)
                t.column("title", .text).notNull()
                t.column("last_chapter_read", .double).notNull()
                t.column("total_chapters", .integer).notNull()
                t.column("score", .double).notNull()
                t.column("status", .integer).notNull()
                t.column("started_reading_date", .integer).notNull()
                t.column("finished_reading_date", .integer).notNull()
                t.column("tracking_url", .text).notNull()
                t.column("private", .boolean).notNull().defaults(to: false)
            }

            try db.create(table: "sources") { t in
                t.primaryKey("_id", .integer)
                t.column("lang", .text)
                t.column("name", .text).notNull()
            }

            try db.create(table: "excluded_scanlators") { t in
                t.column("manga_id", .integer).notNull()
                    .references("mangas", onDelete: .cascade)
                t.column("scanlator", .text).notNull()
                t.primaryKey(["manga_id", "scanlator"])
            }

            try db.create(table: "extension_store") { t in
                t.autoIncrementedPrimaryKey("_id")
                t.column("name", .text).notNull()
                t.column("url", .text).notNull()
            }
        }

        return migrator
    }
}
