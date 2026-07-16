import Foundation

/// Upserts chapters for a manga (insert new by URL, keep read progress on existing).
public struct SyncChaptersWithSource {
    private let chapterRepository: ChapterRepository

    public init(chapterRepository: ChapterRepository) {
        self.chapterRepository = chapterRepository
    }

    public struct IncomingChapter: Sendable {
        public var url: String
        public var name: String
        public var dateUpload: Int64
        public var chapterNumber: Double
        public var scanlator: String?

        public init(url: String, name: String, dateUpload: Int64, chapterNumber: Double, scanlator: String? = nil) {
            self.url = url
            self.name = name
            self.dateUpload = dateUpload
            self.chapterNumber = chapterNumber
            self.scanlator = scanlator
        }
    }

    public func await(mangaId: Int64, sourceChapters: [IncomingChapter]) async throws -> [Chapter] {
        let existing = try await chapterRepository.getChapters(mangaId: mangaId)
        let byURL = Dictionary(uniqueKeysWithValues: existing.map { ($0.url, $0) })
        let now = Int64(Date().timeIntervalSince1970 * 1000)

        var toInsert: [Chapter] = []
        var toUpdate: [Chapter] = []
        var result: [Chapter] = []

        for (index, incoming) in sourceChapters.enumerated() {
            if var found = byURL[incoming.url] {
                found.name = incoming.name
                found.dateUpload = incoming.dateUpload
                found.chapterNumber = incoming.chapterNumber
                found.scanlator = incoming.scanlator
                found.sourceOrder = Int64(index)
                toUpdate.append(found)
                result.append(found)
            } else {
                let chapter = Chapter(
                    mangaId: mangaId,
                    read: false,
                    bookmark: false,
                    lastPageRead: 0,
                    dateFetch: now,
                    sourceOrder: Int64(index),
                    url: incoming.url,
                    name: incoming.name,
                    dateUpload: incoming.dateUpload,
                    chapterNumber: incoming.chapterNumber,
                    scanlator: incoming.scanlator
                )
                toInsert.append(chapter)
                result.append(chapter)
            }
        }

        if !toInsert.isEmpty {
            try await chapterRepository.insert(toInsert)
        }
        if !toUpdate.isEmpty {
            try await chapterRepository.updateAll(toUpdate)
        }

        // Return fresh from DB so IDs are populated
        return try await chapterRepository.getChapters(mangaId: mangaId)
    }
}

public struct NetworkToLocalManga {
    private let mangaRepository: MangaRepository

    public init(mangaRepository: MangaRepository) {
        self.mangaRepository = mangaRepository
    }

    public func await(
        sourceId: Int64,
        url: String,
        title: String,
        artist: String? = nil,
        author: String? = nil,
        description: String? = nil,
        thumbnailUrl: String? = nil,
        status: Int64 = 0,
        favorite: Bool = false
    ) async throws -> Manga {
        if let existing = try await mangaRepository.getManga(url: url, sourceId: sourceId) {
            return existing
        }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let manga = Manga(
            source: sourceId,
            favorite: favorite,
            dateAdded: favorite ? now : 0,
            url: url,
            title: title,
            artist: artist,
            author: author,
            description: description,
            status: status,
            thumbnailUrl: thumbnailUrl,
            initialized: true,
            lastModifiedAt: now / 1000
        )
        let id = try await mangaRepository.insert(manga)
        return try await mangaRepository.getManga(id: id) ?? manga
    }
}
