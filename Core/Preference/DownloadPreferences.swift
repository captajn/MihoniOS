import Foundation

public final class DownloadPreferences: @unchecked Sendable {
    public let store: PreferenceStore

    public init(store: PreferenceStore) {
        self.store = store
    }

    public var downloadOnlyOverWifi: Preference<Bool> {
        store.getBool("pref_download_only_over_wifi_key", default: true)
    }

    public var autoDownloadWhileReading: Preference<Int> {
        store.getInt("auto_download_while_reading", default: 0)
    }

    public var removeAfterReadSlots: Preference<Int> {
        store.getInt("remove_after_read_slots", default: -1)
    }

    public var removeAfterMarkedAsRead: Preference<Bool> {
        store.getBool("pref_remove_after_marked_as_read_key", default: false)
    }

    public var removeBookmarkedChapters: Preference<Bool> {
        store.getBool("pref_remove_bookmarked", default: false)
    }

    public var downloadNewChapters: Preference<Bool> {
        store.getBool("download_new", default: false)
    }

    public var downloadNewUnreadChaptersOnly: Preference<Bool> {
        store.getBool("download_new_unread_chapters_only", default: false)
    }

    public var saveChaptersAsCBZ: Preference<Bool> {
        store.getBool("save_chapter_as_cbz", default: true)
    }

    public var splitTallImages: Preference<Bool> {
        store.getBool("split_tall_images", default: false)
    }
}
