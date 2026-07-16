import Foundation

/// Reader preferences (mirrors Android `ReaderPreferences` subset used in Phase 0–2).
public final class ReaderPreferences: @unchecked Sendable {
    public let store: PreferenceStore

    public init(store: PreferenceStore) {
        self.store = store
    }

    public var defaultReadingMode: Preference<Int> {
        store.getInt("pref_default_reading_mode_key", default: ReadingMode.rightToLeft.flagValue)
    }

    public var defaultOrientation: Preference<Int> {
        store.getInt("pref_default_orientation_type_key", default: ReaderOrientation.free.flagValue)
    }

    public var pageTransitions: Preference<Bool> {
        store.getBool("pref_enable_transitions_key", default: true)
    }

    public var showPageNumber: Preference<Bool> {
        store.getBool("pref_show_page_number_key", default: true)
    }

    public var fullscreen: Preference<Bool> {
        store.getBool("fullscreen", default: true)
    }

    public var keepScreenOn: Preference<Bool> {
        store.getBool("pref_keep_screen_on_key", default: false)
    }

    public var cropBorders: Preference<Bool> {
        store.getBool("crop_borders", default: false)
    }

    public var cropBordersWebtoon: Preference<Bool> {
        store.getBool("crop_borders_webtoon", default: false)
    }

    public var skipRead: Preference<Bool> {
        store.getBool("skip_read", default: false)
    }

    public var skipFiltered: Preference<Bool> {
        store.getBool("skip_filtered", default: true)
    }

    public var skipDupe: Preference<Bool> {
        store.getBool("skip_dupe", default: false)
    }

    public var readerTheme: Preference<Int> {
        store.getInt("pref_reader_theme_key", default: 1)
    }

    public var imageScaleType: Preference<Int> {
        store.getInt("pref_image_scale_type_key", default: 1)
    }

    public var webtoonSidePadding: Preference<Int> {
        store.getInt("webtoon_side_padding", default: 0)
    }

    public var doubleTapZoomWebtoon: Preference<Bool> {
        store.getBool("pref_enable_double_tap_zoom_webtoon", default: true)
    }
}

/// Reading modes — flag values must match Android `ReadingMode`.
public enum ReadingMode: Int, CaseIterable, Sendable, Codable {
    case `default` = 0x0000_0000
    case leftToRight = 0x0000_0001
    case rightToLeft = 0x0000_0002
    case vertical = 0x0000_0003
    case webtoon = 0x0000_0004
    case continuousVertical = 0x0000_0005

    public static let mask = 0x0000_0007

    public var flagValue: Int { rawValue }

    public var displayName: String {
        switch self {
        case .default: "Default"
        case .leftToRight: "Left to right"
        case .rightToLeft: "Right to left"
        case .vertical: "Vertical"
        case .webtoon: "Webtoon"
        case .continuousVertical: "Continuous vertical"
        }
    }

    public var isPager: Bool {
        switch self {
        case .leftToRight, .rightToLeft, .vertical: true
        default: false
        }
    }

    public var isWebtoon: Bool {
        switch self {
        case .webtoon, .continuousVertical: true
        default: false
        }
    }

    public static func fromPreference(_ value: Int?) -> ReadingMode {
        guard let value else { return .default }
        return ReadingMode(rawValue: value & mask) ?? .default
    }
}

public enum ReaderOrientation: Int, CaseIterable, Sendable, Codable {
    case free = 0x0000_0000
    case portrait = 0x0000_0008
    case landscape = 0x0000_0010
    case lockedPortrait = 0x0000_0018
    case lockedLandscape = 0x0000_0020
    case reversePortrait = 0x0000_0028

    public static let mask = 0x0000_0038

    public var flagValue: Int { rawValue }
}
