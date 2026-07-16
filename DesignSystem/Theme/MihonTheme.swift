import SwiftUI
import Core

public struct MihonTheme {
    public let colorScheme: ColorScheme?
    public let appTheme: AppTheme
    public let pureBlack: Bool

    public init(colorScheme: ColorScheme?, appTheme: AppTheme, pureBlack: Bool) {
        self.colorScheme = colorScheme
        self.appTheme = appTheme
        self.pureBlack = pureBlack
    }

    public var accent: Color {
        switch appTheme {
        case .default: Color(red: 0.0, green: 0.345, blue: 0.627) // #0058A0 Android accent_blue
        case .monet: .accentColor
        case .greenapple: Color(red: 0.30, green: 0.69, blue: 0.31)
        case .lavender: Color(red: 0.66, green: 0.55, blue: 0.91)
        case .midnightdusk: Color(red: 0.91, green: 0.30, blue: 0.24)
        case .strawberrydaiquiri: Color(red: 0.91, green: 0.30, blue: 0.45)
        case .tako: Color(red: 0.95, green: 0.55, blue: 0.20)
        case .tealturquoise: Color(red: 0.00, green: 0.59, blue: 0.53)
        case .tidalnord: Color(red: 0.53, green: 0.75, blue: 0.82)
        case .yinandyang: Color(red: 0.50, green: 0.50, blue: 0.50)
        case .yotsuba: Color(red: 0.96, green: 0.49, blue: 0.00)
        case .tidalwave: Color(red: 0.20, green: 0.60, blue: 0.86)
        case .monochrome: Color(white: 0.55)
        case .catppuccin: Color(red: 0.80, green: 0.65, blue: 0.97)
        }
    }

    public var background: Color {
        if pureBlack, colorScheme == .dark {
            return .black
        }
        return Color(.systemBackground)
    }

    public var secondaryBackground: Color {
        if pureBlack, colorScheme == .dark {
            return Color(white: 0.08)
        }
        return Color(.secondarySystemBackground)
    }
}

private struct MihonThemeKey: EnvironmentKey {
    static let defaultValue = MihonTheme(colorScheme: nil, appTheme: .default, pureBlack: false)
}

public extension EnvironmentValues {
    var mihonTheme: MihonTheme {
        get { self[MihonThemeKey.self] }
        set { self[MihonThemeKey.self] = newValue }
    }
}

public struct MihonThemeModifier: ViewModifier {
    @AppStorage("pref_theme_mode_key") private var themeModeRaw: String = ThemeMode.system.rawValue
    @AppStorage("pref_app_theme") private var appThemeRaw: String = AppTheme.default.rawValue
    @AppStorage("pref_dark_theme_pure_black") private var pureBlack: Bool = false
    @Environment(\.colorScheme) private var systemScheme

    public init() {}

    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }

    private var appTheme: AppTheme {
        // AppStorage stores raw string; Codable Preference uses JSON — keep simple raw for SwiftUI
        AppTheme(rawValue: appThemeRaw) ?? .default
    }

    private var preferredScheme: ColorScheme? {
        switch themeMode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    private var resolvedScheme: ColorScheme? {
        preferredScheme ?? systemScheme
    }

    public func body(content: Content) -> some View {
        let theme = MihonTheme(
            colorScheme: resolvedScheme,
            appTheme: appTheme,
            pureBlack: pureBlack
        )
        content
            .environment(\.mihonTheme, theme)
            .preferredColorScheme(preferredScheme)
            .tint(theme.accent)
    }
}

public extension View {
    func mihonTheme() -> some View {
        modifier(MihonThemeModifier())
    }
}
