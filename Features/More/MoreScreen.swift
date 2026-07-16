import SwiftUI
import Core
import DesignSystem

struct MoreScreen: View {
    @AppStorage("incognito_mode") private var incognitoMode = false

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "book.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading) {
                        Text("Mihon")
                            .font(.title2.weight(.bold))
                        Text("iOS · modular build")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section {
                NavigationLink {
                    DownloadsScreen()
                } label: {
                    Label(String(localized: "label_download_queue"), systemImage: "arrow.down.circle")
                }
                NavigationLink {
                    CategoriesScreen()
                } label: {
                    Label(String(localized: "categories"), systemImage: "folder")
                }
                NavigationLink {
                    UpcomingScreen()
                } label: {
                    Label(String(localized: "label_upcoming"), systemImage: "calendar")
                }
                NavigationLink {
                    StatsScreen()
                } label: {
                    Label(String(localized: "label_stats"), systemImage: "chart.bar")
                }
            }

            Section {
                Toggle(String(localized: "incognito_mode"), isOn: $incognitoMode)
                    .tint(.purple)
            }

            Section(String(localized: "label_settings")) {
                NavigationLink {
                    AppearanceSettingsScreen()
                } label: {
                    Label(String(localized: "pref_category_general"), systemImage: "paintpalette")
                }
                NavigationLink {
                    LibrarySettingsScreen()
                } label: {
                    Label(String(localized: "label_library"), systemImage: "books.vertical")
                }
                NavigationLink {
                    ReaderSettingsScreen()
                } label: {
                    Label(String(localized: "pref_category_reader"), systemImage: "book")
                }
                NavigationLink {
                    DownloadSettingsScreen()
                } label: {
                    Label(String(localized: "pref_category_downloads"), systemImage: "arrow.down.circle")
                }
                NavigationLink {
                    TrackingSettingsScreen()
                } label: {
                    Label(String(localized: "pref_category_tracking"), systemImage: "point.3.connected.trianglepath.dotted")
                }
                NavigationLink {
                    BrowseSettingsScreen()
                } label: {
                    Label(String(localized: "label_sources"), systemImage: "globe")
                }
                NavigationLink {
                    DataBackupScreen()
                } label: {
                    Label(String(localized: "label_data_storage"), systemImage: "externaldrive")
                }
                NavigationLink {
                    SecuritySettingsScreen()
                } label: {
                    Label(String(localized: "label_security"), systemImage: "lock")
                }
                NavigationLink {
                    AdvancedSettingsScreen()
                } label: {
                    Label(String(localized: "pref_category_advanced"), systemImage: "gearshape.2")
                }
            }

            Section {
                NavigationLink {
                    AboutScreen()
                } label: {
                    Label(String(localized: "pref_category_about"), systemImage: "info.circle")
                }
                NavigationLink {
                    SupportScreen()
                } label: {
                    Label(String(localized: "label_support_us"), systemImage: "heart")
                }
                NavigationLink {
                    CrashScreen()
                } label: {
                    Label(String(localized: "crash_log"), systemImage: "exclamationmark.triangle")
                }
            }
        }
        .navigationTitle(String(localized: "label_more"))
    }
}

struct AppearanceSettingsScreen: View {
    @AppStorage("pref_theme_mode_key") private var themeModeRaw: String = ThemeMode.system.rawValue
    @AppStorage("pref_app_theme") private var appThemeRaw: String = AppTheme.default.rawValue
    @AppStorage("pref_dark_theme_pure_black") private var pureBlack = false

    var body: some View {
        Form {
            Section(String(localized: "pref_app_theme")) {
                Picker(String(localized: "pref_theme_mode"), selection: $themeModeRaw) {
                    ForEach(ThemeMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                Picker(String(localized: "pref_app_theme"), selection: $appThemeRaw) {
                    ForEach(AppTheme.allCases, id: \.rawValue) { theme in
                        Text(theme.displayName).tag(theme.rawValue)
                    }
                }
                Toggle(String(localized: "pref_dark_theme_pure_black"), isOn: $pureBlack)
            }
        }
        .navigationTitle(String(localized: "pref_category_general"))
    }
}

struct AboutScreen: View {
    var body: some View {
        List {
            Section {
                LabeledContent(String(localized: "Version"), value: "0.1.0-dev")
                LabeledContent(String(localized: "Platform"), value: "iOS")
            }
            Section {
                Text(String(localized: "about_description"))
                    .font(.footnote)
            }
            Section(String(localized: "Disclaimer")) {
                Text(String(localized: "about_disclaimer"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(String(localized: "pref_category_about"))
    }
}
