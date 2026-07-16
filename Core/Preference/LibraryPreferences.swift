import Foundation

/// Library-related preferences (mirrors Android `LibraryPreferences` subset).
public final class LibraryPreferences: @unchecked Sendable {
    public let store: PreferenceStore

    public init(store: PreferenceStore) {
        self.store = store
    }

    public var displayMode: Preference<LibraryDisplayMode> {
        store.getObject("pref_display_mode_library", default: .comfortableGrid)
    }

    public var sortingMode: Preference<LibrarySortMode> {
        store.getObject("library_sorting_mode", default: .alphabetical)
    }

    public var sortingDirection: Preference<SortDirection> {
        store.getObject("library_sorting_ascending", default: .ascending)
    }

    public var autoUpdateInterval: Preference<Int> {
        // hours; 0 = manual only
        store.getInt("pref_library_update_interval_key", default: 0)
    }

    public var autoUpdateDeviceRestrictions: Preference<Set<String>> {
        store.getStringSet("library_update_restriction", default: ["wifi"])
    }

    public var autoUpdateMangaRestrictions: Preference<Set<String>> {
        store.getStringSet("library_update_manga_restriction", default: ["manga_ongoing", "manga_fully_read", "manga_started", "manga_uncompleted"])
    }

    public var badgeDownloadedChapters: Preference<Bool> {
        store.getBool("display_download_badge", default: false)
    }

    public var badgeUnreadChapters: Preference<Bool> {
        store.getBool("display_unread_badge", default: true)
    }

    public var badgeLocalSource: Preference<Bool> {
        store.getBool("display_local_badge", default: true)
    }

    public var badgeLanguage: Preference<Bool> {
        store.getBool("display_language_badge", default: false)
    }

    public var filterDownloaded: Preference<TriState> {
        store.getObject("pref_filter_library_downloaded", default: .disabled)
    }

    public var filterUnread: Preference<TriState> {
        store.getObject("pref_filter_library_unread", default: .disabled)
    }

    public var filterStarted: Preference<TriState> {
        store.getObject("pref_filter_library_started", default: .disabled)
    }

    public var filterBookmarked: Preference<TriState> {
        store.getObject("pref_filter_library_bookmarked", default: .disabled)
    }

    public var filterCompleted: Preference<TriState> {
        store.getObject("pref_filter_library_completed", default: .disabled)
    }

    public var defaultCategory: Preference<Int> {
        store.getInt("default_category", default: -1)
    }

    public var perCategorySettings: Preference<Bool> {
        store.getBool("category_per_category_settings", default: false)
    }

    /// Sort mode for a specific category. Falls back to the global `sortingMode` when
    /// per-category settings are disabled or no override exists yet.
    public func sortingMode(forCategory categoryId: Int64) -> LibrarySortMode {
        guard perCategorySettings.get() else { return sortingMode.get() }
        return store.getObject("library_sorting_mode_cat_\(categoryId)", default: sortingMode.get()).get()
    }

    public func setSortingMode(_ mode: LibrarySortMode, forCategory categoryId: Int64) {
        store.getObject("library_sorting_mode_cat_\(categoryId)", default: sortingMode.get()).set(mode)
    }

    public func sortingDirection(forCategory categoryId: Int64) -> SortDirection {
        guard perCategorySettings.get() else { return sortingDirection.get() }
        return store.getObject("library_sorting_dir_cat_\(categoryId)", default: sortingDirection.get()).get()
    }

    public func setSortingDirection(_ direction: SortDirection, forCategory categoryId: Int64) {
        store.getObject("library_sorting_dir_cat_\(categoryId)", default: sortingDirection.get()).set(direction)
    }
}

public enum LibraryDisplayMode: String, Codable, CaseIterable, Hashable, Sendable {
    case compactGrid
    case comfortableGrid
    case coverOnlyGrid
    case list

    public var displayName: String {
        switch self {
        case .compactGrid: "Compact grid"
        case .comfortableGrid: "Comfortable grid"
        case .coverOnlyGrid: "Cover-only grid"
        case .list: "List"
        }
    }
}

public enum LibrarySortMode: String, Codable, CaseIterable, Hashable, Sendable {
    case alphabetical
    case lastRead
    case lastUpdate
    case unreadCount
    case totalChapters
    case latestChapter
    case chapterFetchDate
    case dateAdded
    case random
}

public enum SortDirection: String, Codable, CaseIterable, Sendable {
    case ascending
    case descending
}

/// Three-state filter matching Android `TriState`.
public enum TriState: String, Codable, CaseIterable, Sendable {
    case disabled
    case enabledIs
    case enabledNot
}
