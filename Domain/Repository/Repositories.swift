import Foundation

// MARK: - Manga

public protocol MangaRepository: Sendable {
    func getManga(id: Int64) async throws -> Manga?
    func getManga(url: String, sourceId: Int64) async throws -> Manga?
    func getFavorites() async throws -> [Manga]
    func getLibraryManga() async throws -> [LibraryManga]
    func insert(_ manga: Manga) async throws -> Int64
    func update(_ manga: Manga) async throws
    func partialUpdate(id: Int64, favorite: Bool?, viewerFlags: Int64?, chapterFlags: Int64?, notes: String?) async throws
    func delete(id: Int64) async throws
}

// MARK: - Chapter

public protocol ChapterRepository: Sendable {
    func getChapter(id: Int64) async throws -> Chapter?
    func getChapters(mangaId: Int64) async throws -> [Chapter]
    func getBookmarkedChapters(mangaId: Int64) async throws -> [Chapter]
    func insert(_ chapters: [Chapter]) async throws
    func update(_ chapter: Chapter) async throws
    func updateAll(_ chapters: [Chapter]) async throws
    func removeChapters(ids: [Int64]) async throws
}

// MARK: - Category

public protocol CategoryRepository: Sendable {
    func getAll() async throws -> [Category]
    func getCategories(mangaId: Int64) async throws -> [Category]
    func insert(_ category: Category) async throws -> Int64
    func update(_ category: Category) async throws
    func delete(id: Int64) async throws
    func setMangaCategories(mangaId: Int64, categoryIds: [Int64]) async throws
}

// MARK: - History

public protocol HistoryRepository: Sendable {
    func getHistory(query: String) async throws -> [HistoryWithRelations]
    func getHistory(mangaId: Int64) async throws -> [History]
    func upsert(_ history: History) async throws
    func removeHistory(ids: [Int64]) async throws
    func removeAll() async throws
    func getTotalReadDuration() async throws -> Int64
}

// MARK: - Updates

public protocol UpdatesRepository: Sendable {
    func awaitUpdates(after: Int64, limit: Int) async throws -> [UpdatesWithRelations]
}

// MARK: - Track

public protocol TrackRepository: Sendable {
    func getTracks(mangaId: Int64) async throws -> [Track]
    func getTracks() async throws -> [Track]
    func insert(_ track: Track) async throws -> Int64
    func delete(id: Int64) async throws
    func delete(mangaId: Int64, syncId: Int64) async throws
}

// MARK: - Source metadata

public protocol SourceRepository: Sendable {
    func getSources() async throws -> [SourceInfo]
    func getStubSources() async throws -> [SourceInfo]
    func upsertStubSource(_ source: SourceInfo) async throws
}
