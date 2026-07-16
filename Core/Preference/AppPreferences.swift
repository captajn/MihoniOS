import Foundation

/// UI / theme preferences (mirrors Android `UiPreferences` + `BasePreferences` subset).
public final class AppPreferences: @unchecked Sendable {
    public let store: PreferenceStore

    public init(store: PreferenceStore) {
        self.store = store
    }

    // MARK: Theme

    public var themeMode: Preference<ThemeMode> {
        store.getObject("pref_theme_mode_key", default: .system)
    }

    public var appTheme: Preference<AppTheme> {
        store.getObject("pref_app_theme", default: .default)
    }

    public var themeDarkAmoled: Preference<Bool> {
        store.getBool("pref_dark_theme_pure_black", default: false)
    }

    // MARK: Onboarding / first run

    public var shownOnboarding: Preference<Bool> {
        store.getBool("onboarding_complete", default: false)
    }

    public var relativeTimestamps: Preference<Bool> {
        store.getBool("relative_time_v2", default: true)
    }

    public var dateFormat: Preference<String> {
        store.getString("app_date_format", default: "")
    }

    // MARK: Security

    public var useAuthenticator: Preference<Bool> {
        store.getBool("use_biometric_lock", default: false)
    }

    public var lockAppAfter: Preference<Int> {
        store.getInt("lock_app_after", default: 0)
    }

    public var secureScreen: Preference<Bool> {
        store.getBool("secure_screen", default: false)
    }

    // MARK: Incognito

    public var incognitoMode: Preference<Bool> {
        store.getBool("incognito_mode", default: false)
    }
}

// MARK: - Theme enums

public enum ThemeMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark

    public var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

/// Color schemes aligned with Android `AppTheme`.
public enum AppTheme: String, Codable, CaseIterable, Sendable {
    case `default`
    case monet
    case greenapple
    case lavender
    case midnightdusk
    case strawberrydaiquiri
    case tako
    case tealturquoise
    case tidalnord
    case yinandyang
    case yotsuba
    case tidalwave
    case monochrome
    case catppuccin

    public var displayName: String {
        switch self {
        case .default: "Default"
        case .monet: "Dynamic"
        case .greenapple: "Green Apple"
        case .lavender: "Lavender"
        case .midnightdusk: "Midnight Dusk"
        case .strawberrydaiquiri: "Strawberry"
        case .tako: "Tako"
        case .tealturquoise: "Teal & Turquoise"
        case .tidalnord: "Nord"
        case .yinandyang: "Yin & Yang"
        case .yotsuba: "Yotsuba"
        case .tidalwave: "Tidal Wave"
        case .monochrome: "Monochrome"
        case .catppuccin: "Catppuccin"
        }
    }
}
