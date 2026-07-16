import Foundation

/// Coordinates refreshing library manga chapter lists from sources.
public struct LibraryUpdateService: Sendable {
    public struct Result: Sendable {
        public var updatedManga: Int
        public var newChapters: Int
        public var errors: [String]

        public init(updatedManga: Int = 0, newChapters: Int = 0, errors: [String] = []) {
            self.updatedManga = updatedManga
            self.newChapters = newChapters
            self.errors = errors
        }
    }

    public typealias FetchChapters = @Sendable (Int64, String) async throws -> [SyncChaptersWithSource.IncomingChapter]

    private let mangaRepository: MangaRepository
    private let chapterRepository: ChapterRepository
    private let sync: SyncChaptersWithSource
    private let fetch: FetchChapters

    public init(
        mangaRepository: MangaRepository,
        chapterRepository: ChapterRepository,
        sync: SyncChaptersWithSource,
        fetch: @escaping FetchChapters
    ) {
        self.mangaRepository = mangaRepository
        self.chapterRepository = chapterRepository
        self.sync = sync
        self.fetch = fetch
    }

    public func updateLibrary() async -> Result {
        var result = Result()
        do {
            let library = try await mangaRepository.getFavorites()
            for manga in library {
                do {
                    let before = try await chapterRepository.getChapters(mangaId: manga.id)
                    let beforeURLs = Set(before.map(\.url))
                    let incoming = try await fetch(manga.source, manga.url)
                    _ = try await sync.await(mangaId: manga.id, sourceChapters: incoming)
                    let after = try await chapterRepository.getChapters(mangaId: manga.id)
                    let newCount = after.filter { !beforeURLs.contains($0.url) }.count
                    result.updatedManga += 1
                    result.newChapters += newCount
                } catch {
                    result.errors.append("\(manga.title): \(error.localizedDescription)")
                }
            }
        } catch {
            result.errors.append(error.localizedDescription)
        }
        return result
    }
}
