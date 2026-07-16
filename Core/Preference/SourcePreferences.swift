import Foundation

public final class SourcePreferences: @unchecked Sendable {
    public let store: PreferenceStore

    public init(store: PreferenceStore) {
        self.store = store
    }

    public var enabledLanguages: Preference<Set<String>> {
        store.getStringSet("enabled_languages", default: [Locale.current.language.languageCode?.identifier ?? "en"])
    }

    public var disabledSources: Preference<Set<String>> {
        store.getStringSet("hidden_catalogues", default: [])
    }

    public var pinnedSources: Preference<Set<String>> {
        store.getStringSet("pinned_catalogues", default: [])
    }

    public var incognitoExtensions: Preference<Set<String>> {
        store.getStringSet("incognito_extensions", default: [])
    }

    public var showNsfwSource: Preference<Bool> {
        store.getBool("show_nsfw_source", default: true)
    }

    public var migrationSortingMode: Preference<String> {
        store.getString("pref_migration_sorting", default: "alphabetical")
    }

    public var migrationSortingDirection: Preference<String> {
        store.getString("pref_migration_direction", default: "ascending")
    }

    public var hideInLibraryItems: Preference<Bool> {
        store.getBool("browse_hide_in_library_items", default: false)
    }
}
