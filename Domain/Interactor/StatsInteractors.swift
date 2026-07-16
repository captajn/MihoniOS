import Foundation

public struct LibraryStats: Sendable {
    public var totalLibrary: Int
    public var readChapters: Int
    public var totalChapters: Int
    public var trackedTitles: Int
    public var completedTitles: Int
    public var totalReadDurationMs: Int64

    public var readDurationHours: Double {
        Double(totalReadDurationMs) / 3_600_000.0
    }

    public init(
        totalLibrary: Int = 0,
        readChapters: Int = 0,
        totalChapters: Int = 0,
        trackedTitles: Int = 0,
        completedTitles: Int = 0,
        totalReadDurationMs: Int64 = 0
    ) {
        self.totalLibrary = totalLibrary
        self.readChapters = readChapters
        self.totalChapters = totalChapters
        self.trackedTitles = trackedTitles
        self.completedTitles = completedTitles
        self.totalReadDurationMs = totalReadDurationMs
    }
}

public struct GetLibraryStats {
    private let mangaRepo: MangaRepository
    private let chapterRepo: ChapterRepository
    private let trackRepo: TrackRepository
    private let historyRepo: HistoryRepository

    public init(
        mangaRepo: MangaRepository,
        chapterRepo: ChapterRepository,
        trackRepo: TrackRepository,
        historyRepo: HistoryRepository
    ) {
        self.mangaRepo = mangaRepo
        self.chapterRepo = chapterRepo
        self.trackRepo = trackRepo
        self.historyRepo = historyRepo
    }

    public func await() async throws -> LibraryStats {
        let library = try await mangaRepo.getLibraryManga()
        var read = 0
        var total = 0
        var completed = 0
        for item in library {
            read += item.readCount
            total += item.totalChapters
            if item.manga.status == MangaStatus.completed.rawValue {
                completed += 1
            }
        }
        let tracks = try await trackRepo.getTracks()
        let trackedManga = Set(tracks.map(\.mangaId)).count
        let duration = try await historyRepo.getTotalReadDuration()
        return LibraryStats(
            totalLibrary: library.count,
            readChapters: read,
            totalChapters: total,
            trackedTitles: trackedManga,
            completedTitles: completed,
            totalReadDurationMs: duration
        )
    }
}
