import Foundation

public struct GetChaptersByMangaId {
    private let repository: ChapterRepository

    public init(repository: ChapterRepository) {
        self.repository = repository
    }

    public func await(mangaId: Int64) async throws -> [Chapter] {
        try await repository.getChapters(mangaId: mangaId)
    }
}

public struct SetReadStatus {
    private let repository: ChapterRepository

    public init(repository: ChapterRepository) {
        self.repository = repository
    }

    public func await(chapters: [Chapter], read: Bool) async throws {
        let updated = chapters.map { chapter -> Chapter in
            var copy = chapter
            copy.read = read
            if read {
                // keep lastPageRead
            } else {
                copy.lastPageRead = 0
            }
            return copy
        }
        try await repository.updateAll(updated)
    }
}

public struct UpdateChapterProgress {
    private let chapterRepository: ChapterRepository
    private let historyRepository: HistoryRepository

    public init(chapterRepository: ChapterRepository, historyRepository: HistoryRepository) {
        self.chapterRepository = chapterRepository
        self.historyRepository = historyRepository
    }

    public func await(chapter: Chapter, lastPageRead: Int64, readDuration: Int64 = 0) async throws {
        var updated = chapter
        updated.lastPageRead = lastPageRead
        try await chapterRepository.update(updated)

        let history = History(
            chapterId: chapter.id,
            readAt: Int64(Date().timeIntervalSince1970 * 1000),
            readDuration: readDuration
        )
        try await historyRepository.upsert(history)
    }
}
