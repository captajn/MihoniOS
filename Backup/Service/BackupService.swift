import Foundation
import Core
import Domain

public struct BackupValidation: Sendable {
    public var missingSources: [(id: Int64, name: String)]
    public var missingTrackers: [Int64]
    public var mangaCount: Int
    public var categoryCount: Int
}

public final class BackupService: Sendable {
    private let mangaRepo: MangaRepository
    private let chapterRepo: ChapterRepository
    private let categoryRepo: CategoryRepository
    private let historyRepo: HistoryRepository
    private let trackRepo: TrackRepository
    private let sourceRepo: SourceRepository

    public init(
        mangaRepo: MangaRepository,
        chapterRepo: ChapterRepository,
        categoryRepo: CategoryRepository,
        historyRepo: HistoryRepository,
        trackRepo: TrackRepository,
        sourceRepo: SourceRepository
    ) {
        self.mangaRepo = mangaRepo
        self.chapterRepo = chapterRepo
        self.categoryRepo = categoryRepo
        self.historyRepo = historyRepo
        self.trackRepo = trackRepo
        self.sourceRepo = sourceRepo
    }

    // MARK: Create

    public func createBackup() async throws -> Data {
        let favorites = try await mangaRepo.getFavorites()
        let categories = try await categoryRepo.getAll().filter { !$0.isSystemCategory }
        var doc = BackupDocument()

        doc.categories = categories.map {
            BackupCategory(name: $0.name, order: $0.order, id: $0.id, flags: $0.flags)
        }

        var sourceMap: [Int64: String] = [:]

        for manga in favorites {
            var bm = BackupManga()
            bm.source = manga.source
            bm.url = manga.url
            bm.title = manga.title
            bm.artist = manga.artist
            bm.author = manga.author
            bm.description = manga.description
            bm.genre = manga.genre ?? []
            bm.status = Int32(manga.status)
            bm.thumbnailUrl = manga.thumbnailUrl
            bm.dateAdded = manga.dateAdded
            bm.viewer = Int32(manga.viewerFlags)
            bm.viewerFlags = Int32(manga.viewerFlags)
            bm.favorite = manga.favorite
            bm.chapterFlags = Int32(manga.chapterFlags)
            bm.updateStrategy = Int32(manga.updateStrategy.rawValue)
            bm.lastModifiedAt = manga.lastModifiedAt
            bm.favoriteModifiedAt = manga.favoriteModifiedAt
            bm.version = manga.version
            bm.notes = manga.notes
            bm.initialized = manga.initialized

            let cats = try await categoryRepo.getCategories(mangaId: manga.id)
            bm.categories = cats.map(\.id)

            let chapters = try await chapterRepo.getChapters(mangaId: manga.id)
            bm.chapters = chapters.map { ch in
                var bc = BackupChapter()
                bc.url = ch.url
                bc.name = ch.name
                bc.scanlator = ch.scanlator
                bc.read = ch.read
                bc.bookmark = ch.bookmark
                bc.lastPageRead = ch.lastPageRead
                bc.dateFetch = ch.dateFetch
                bc.dateUpload = ch.dateUpload
                bc.chapterNumber = Float(ch.chapterNumber)
                bc.sourceOrder = ch.sourceOrder
                bc.lastModifiedAt = ch.lastModifiedAt
                bc.version = ch.version
                return bc
            }

            let history = try await historyRepo.getHistory(mangaId: manga.id)
            let chapterById = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0) })
            bm.history = history.compactMap { h in
                guard let ch = chapterById[h.chapterId] else { return nil }
                return BackupHistory(url: ch.url, lastRead: h.readAt ?? 0, readDuration: h.readDuration)
            }

            let tracks = try await trackRepo.getTracks(mangaId: manga.id)
            bm.tracking = tracks.map { t in
                var bt = BackupTracking()
                bt.syncId = Int32(t.syncId)
                bt.libraryId = t.libraryId ?? 0
                bt.mediaId = t.mediaId
                bt.trackingUrl = t.trackingUrl
                bt.title = t.title
                bt.lastChapterRead = Float(t.lastChapterRead)
                bt.totalChapters = Int32(t.totalChapters)
                bt.score = Float(t.score)
                bt.status = Int32(t.status)
                bt.startedReadingDate = t.startedReadingDate
                bt.finishedReadingDate = t.finishedReadingDate
                bt.privateTrack = t.privateTrack
                return bt
            }

            sourceMap[manga.source] = sourceMap[manga.source] ?? "Source \(manga.source)"
            doc.manga.append(bm)
        }

        doc.sources = sourceMap.map { BackupSource(name: $0.value, sourceId: $0.key) }
        AppLog.info("Created backup with \(doc.manga.count) manga", category: "backup")
        return try BackupEncoder.encodeGzip(doc)
    }

    // MARK: Validate

    public func validate(data: Data) throws -> BackupValidation {
        let doc = try BackupDecoder.decode(data: data)
        let missingSources = doc.sources.map { ($0.sourceId, $0.name) }
        var trackerIds = Set<Int64>()
        for m in doc.manga {
            for t in m.tracking { trackerIds.insert(Int64(t.syncId)) }
        }
        return BackupValidation(
            missingSources: missingSources,
            missingTrackers: Array(trackerIds).sorted(),
            mangaCount: doc.manga.count,
            categoryCount: doc.categories.count
        )
    }

    // MARK: Restore

    public func restore(data: Data) async throws {
        let doc = try BackupDecoder.decode(data: data)
        AppLog.info("Restoring \(doc.manga.count) manga", category: "backup")

        // Categories: map backup id → new id
        var categoryMap: [Int64: Int64] = [0: 0]
        for cat in doc.categories {
            let newId = try await categoryRepo.insert(
                Category(name: cat.name, order: cat.order, flags: cat.flags)
            )
            if cat.id != 0 {
                categoryMap[cat.id] = newId
            }
        }

        for bm in doc.manga {
            var manga = Manga(
                source: bm.source,
                favorite: bm.favorite,
                lastUpdate: 0,
                nextUpdate: 0,
                fetchInterval: 0,
                dateAdded: bm.dateAdded,
                viewerFlags: Int64(bm.viewerFlags ?? bm.viewer),
                chapterFlags: Int64(bm.chapterFlags),
                coverLastModified: 0,
                url: bm.url,
                title: bm.title,
                artist: bm.artist,
                author: bm.author,
                description: bm.description,
                genre: bm.genre,
                status: Int64(bm.status),
                thumbnailUrl: bm.thumbnailUrl,
                updateStrategy: UpdateStrategy(rawValue: Int(bm.updateStrategy)) ?? .alwaysUpdate,
                initialized: bm.initialized,
                lastModifiedAt: bm.lastModifiedAt,
                favoriteModifiedAt: bm.favoriteModifiedAt,
                version: bm.version,
                notes: bm.notes
            )

            if let existing = try await mangaRepo.getManga(url: bm.url, sourceId: bm.source) {
                manga.id = existing.id
                try await mangaRepo.update(manga)
            } else {
                let id = try await mangaRepo.insert(manga)
                manga.id = id
            }

            let mappedCats = bm.categories.compactMap { categoryMap[$0] }.filter { $0 > 0 }
            try await categoryRepo.setMangaCategories(mangaId: manga.id, categoryIds: mappedCats)

            let incoming = bm.chapters.enumerated().map { index, ch in
                Chapter(
                    mangaId: manga.id,
                    read: ch.read,
                    bookmark: ch.bookmark,
                    lastPageRead: ch.lastPageRead,
                    dateFetch: ch.dateFetch,
                    sourceOrder: ch.sourceOrder != 0 ? ch.sourceOrder : Int64(index),
                    url: ch.url,
                    name: ch.name,
                    dateUpload: ch.dateUpload,
                    chapterNumber: Double(ch.chapterNumber),
                    scanlator: ch.scanlator,
                    lastModifiedAt: ch.lastModifiedAt,
                    version: ch.version
                )
            }

            // Replace chapters simply: insert missing by URL
            let existingCh = try await chapterRepo.getChapters(mangaId: manga.id)
            let existingURLs = Set(existingCh.map(\.url))
            let toInsert = incoming.filter { !existingURLs.contains($0.url) }
            if !toInsert.isEmpty {
                try await chapterRepo.insert(toInsert)
            }
            // Update progress for existing
            let byURL = Dictionary(uniqueKeysWithValues: (try await chapterRepo.getChapters(mangaId: manga.id)).map { ($0.url, $0) })
            var updates: [Chapter] = []
            for ch in incoming {
                if var found = byURL[ch.url] {
                    found.read = ch.read
                    found.bookmark = ch.bookmark
                    found.lastPageRead = ch.lastPageRead
                    updates.append(found)
                }
            }
            if !updates.isEmpty {
                try await chapterRepo.updateAll(updates)
            }

            let chaptersNow = try await chapterRepo.getChapters(mangaId: manga.id)
            let chapterByURL = Dictionary(uniqueKeysWithValues: chaptersNow.map { ($0.url, $0) })
            for h in bm.history {
                if let ch = chapterByURL[h.url] {
                    try await historyRepo.upsert(
                        History(chapterId: ch.id, readAt: h.lastRead, readDuration: h.readDuration)
                    )
                }
            }

            for t in bm.tracking {
                let mediaId = t.mediaId != 0 ? t.mediaId : Int64(t.mediaIdInt)
                _ = try await trackRepo.insert(
                    Track(
                        mangaId: manga.id,
                        syncId: Int64(t.syncId),
                        mediaId: mediaId,
                        libraryId: t.libraryId == 0 ? nil : t.libraryId,
                        title: t.title,
                        lastChapterRead: Double(t.lastChapterRead),
                        totalChapters: Int(t.totalChapters),
                        score: Double(t.score),
                        status: Int(t.status),
                        startedReadingDate: t.startedReadingDate,
                        finishedReadingDate: t.finishedReadingDate,
                        trackingUrl: t.trackingUrl,
                        privateTrack: t.privateTrack
                    )
                )
            }

            try await sourceRepo.upsertStubSource(
                SourceInfo(id: bm.source, name: doc.sources.first(where: { $0.sourceId == bm.source })?.name ?? "Source \(bm.source)", isStub: true)
            )
        }
    }
}
