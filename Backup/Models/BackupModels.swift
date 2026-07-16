import Foundation

/// Field numbers match Android `eu.kanade.tachiyomi.data.backup.models`.
public struct BackupDocument: Sendable {
    public var manga: [BackupManga] = []
    public var categories: [BackupCategory] = []
    public var sources: [BackupSource] = []
    public var preferences: [BackupPreference] = []
    public var sourcePreferences: [BackupSourcePreferences] = []
    public var extensionStores: [BackupExtensionStore] = []

    public init() {}
}

public struct BackupManga: Sendable {
    public var source: Int64 = 0
    public var url: String = ""
    public var title: String = ""
    public var artist: String?
    public var author: String?
    public var description: String?
    public var genre: [String] = []
    public var status: Int32 = 0
    public var thumbnailUrl: String?
    public var dateAdded: Int64 = 0
    public var viewer: Int32 = 0
    public var chapters: [BackupChapter] = []
    public var categories: [Int64] = []
    public var tracking: [BackupTracking] = []
    public var favorite: Bool = true
    public var chapterFlags: Int32 = 0
    public var viewerFlags: Int32?
    public var history: [BackupHistory] = []
    public var updateStrategy: Int32 = 0
    public var lastModifiedAt: Int64 = 0
    public var favoriteModifiedAt: Int64?
    public var excludedScanlators: [String] = []
    public var version: Int64 = 0
    public var notes: String = ""
    public var initialized: Bool = false
    public var memo: Data = Data()
}

public struct BackupChapter: Sendable {
    public var url: String = ""
    public var name: String = ""
    public var scanlator: String?
    public var read: Bool = false
    public var bookmark: Bool = false
    public var lastPageRead: Int64 = 0
    public var dateFetch: Int64 = 0
    public var dateUpload: Int64 = 0
    public var chapterNumber: Float = 0
    public var sourceOrder: Int64 = 0
    public var lastModifiedAt: Int64 = 0
    public var version: Int64 = 0
    public var memo: Data = Data()
}

public struct BackupCategory: Sendable {
    public var name: String = ""
    public var order: Int64 = 0
    public var id: Int64 = 0
    public var flags: Int64 = 0
}

public struct BackupHistory: Sendable {
    public var url: String = ""
    public var lastRead: Int64 = 0
    public var readDuration: Int64 = 0
}

public struct BackupTracking: Sendable {
    public var syncId: Int32 = 0
    public var libraryId: Int64 = 0
    public var mediaIdInt: Int32 = 0
    public var trackingUrl: String = ""
    public var title: String = ""
    public var lastChapterRead: Float = 0
    public var totalChapters: Int32 = 0
    public var score: Float = 0
    public var status: Int32 = 0
    public var startedReadingDate: Int64 = 0
    public var finishedReadingDate: Int64 = 0
    public var privateTrack: Bool = false
    public var mediaId: Int64 = 0
}

public struct BackupSource: Sendable {
    public var name: String = ""
    public var sourceId: Int64 = 0
}

public struct BackupPreference: Sendable {
    public var key: String = ""
    public var type: PreferenceType = .string
    public var stringValue: String = ""
    public var intValue: Int32 = 0
    public var longValue: Int64 = 0
    public var floatValue: Float = 0
    public var boolValue: Bool = false
    public var stringSet: [String] = []
}

public enum PreferenceType: Sendable {
    case int, long, float, string, bool, stringSet
}

public struct BackupSourcePreferences: Sendable {
    public var sourceKey: String = ""
    public var prefs: [BackupPreference] = []
}

public struct BackupExtensionStore: Sendable {
    public var indexUrl: String = ""
    public var name: String = ""
    public var badgeLabel: String?
    public var contactWebsite: String = ""
    public var signingKey: String = ""
    public var contactDiscord: String?
    public var isLegacy: Bool?
    public var extensionListUrl: String?
}
