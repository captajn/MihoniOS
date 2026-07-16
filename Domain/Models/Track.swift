import Foundation

/// Tracking entry — aligns with Android `Track` / `manga_sync` table.
public struct Track: Identifiable, Hashable, Sendable, Codable {
    public var id: Int64
    public var mangaId: Int64
    public var syncId: Int64
    public var mediaId: Int64
    public var libraryId: Int64?
    public var title: String
    public var lastChapterRead: Double
    public var totalChapters: Int
    public var score: Double
    public var status: Int
    public var startedReadingDate: Int64
    public var finishedReadingDate: Int64
    public var trackingUrl: String
    public var privateTrack: Bool

    public init(
        id: Int64 = -1,
        mangaId: Int64,
        syncId: Int64,
        mediaId: Int64 = 0,
        libraryId: Int64? = nil,
        title: String = "",
        lastChapterRead: Double = 0,
        totalChapters: Int = 0,
        score: Double = 0,
        status: Int = 0,
        startedReadingDate: Int64 = 0,
        finishedReadingDate: Int64 = 0,
        trackingUrl: String = "",
        privateTrack: Bool = false
    ) {
        self.id = id
        self.mangaId = mangaId
        self.syncId = syncId
        self.mediaId = mediaId
        self.libraryId = libraryId
        self.title = title
        self.lastChapterRead = lastChapterRead
        self.totalChapters = totalChapters
        self.score = score
        self.status = status
        self.startedReadingDate = startedReadingDate
        self.finishedReadingDate = finishedReadingDate
        self.trackingUrl = trackingUrl
        self.privateTrack = privateTrack
    }
}

/// Tracker service IDs — must match Android `TrackerManager`.
public enum TrackerId: Int64, Sendable, CaseIterable {
    case myAnimeList = 1
    case aniList = 2
    case kitsu = 3
    case shikimori = 4
    case bangumi = 5
    case komga = 6
    case mangaUpdates = 7
    case kavita = 8
    case suwayomi = 9
    case hikka = 10
    case mangaBaka = 11

    public var displayName: String {
        switch self {
        case .myAnimeList: "MyAnimeList"
        case .aniList: "AniList"
        case .kitsu: "Kitsu"
        case .shikimori: "Shikimori"
        case .bangumi: "Bangumi"
        case .komga: "Komga"
        case .mangaUpdates: "MangaUpdates"
        case .kavita: "Kavita"
        case .suwayomi: "Suwayomi"
        case .hikka: "Hikka"
        case .mangaBaka: "MangaBaka"
        }
    }
}
