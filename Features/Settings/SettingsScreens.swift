import SwiftUI
import LocalAuthentication
import Core
import DesignSystem
import Extensions
import SourceAPI

// MARK: - Library settings

struct LibrarySettingsScreen: View {
    private let prefs = AppContainer.shared.libraryPreferences
    @State private var displayMode: String = ""
    @State private var interval: Int = 0
    @State private var badgeUnread = true
    @State private var badgeDownload = false

    var body: some View {
        Form {
            Section(String(localized: "action_display")) {
                Picker(String(localized: "action_display_mode"), selection: $displayMode) {
                    ForEach(LibraryDisplayMode.allCases, id: \.rawValue) {
                        Text($0.displayName).tag($0.rawValue)
                    }
                }
                .onChange(of: displayMode) { v in
                    if let m = LibraryDisplayMode(rawValue: v) {
                        prefs.displayMode.set(m)
                    }
                }
            }
            Section(String(localized: "action_filter")) {
                Toggle(String(localized: "action_filter_unread"), isOn: $badgeUnread)
                    .onChange(of: badgeUnread) { v in prefs.badgeUnreadChapters.set(v) }
                Toggle(String(localized: "label_downloaded"), isOn: $badgeDownload)
                    .onChange(of: badgeDownload) { v in prefs.badgeDownloadedChapters.set(v) }
            }
            Section(String(localized: "pref_library_update_interval")) {
                Stepper(
                    "\(String(localized: "pref_library_update_interval")): \(interval == 0 ? String(localized: "update_never") : "\(interval)h")",
                    value: $interval,
                    in: 0...72
                )
                .onChange(of: interval) { v in prefs.autoUpdateInterval.set(v) }
                Text(String(localized: "pref_library_update_restriction"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(String(localized: "label_library"))
        .onAppear {
            displayMode = prefs.displayMode.get().rawValue
            interval = prefs.autoUpdateInterval.get()
            badgeUnread = prefs.badgeUnreadChapters.get()
            badgeDownload = prefs.badgeDownloadedChapters.get()
        }
    }
}

// MARK: - Reader settings

struct ReaderSettingsScreen: View {
    private let prefs = AppContainer.shared.readerPreferences
    @State private var mode: Int = ReadingMode.rightToLeft.flagValue
    @State private var pageNumber = true
    @State private var keepOn = false
    @State private var crop = false
    @State private var skipRead = false

    var body: some View {
        Form {
            Section(String(localized: "pref_viewer_type")) {
                Picker(String(localized: "pref_viewer_type"), selection: $mode) {
                    ForEach([ReadingMode.rightToLeft, .leftToRight, .vertical, .webtoon, .continuousVertical], id: \.flagValue) {
                        Text($0.displayName).tag($0.flagValue)
                    }
                }
                .onChange(of: mode) { v in prefs.defaultReadingMode.set(v) }
            }
            Section {
                Toggle(String(localized: "pref_show_page_number"), isOn: $pageNumber)
                    .onChange(of: pageNumber) { v in prefs.showPageNumber.set(v) }
                Toggle(String(localized: "pref_keep_screen_on"), isOn: $keepOn)
                    .onChange(of: keepOn) { v in prefs.keepScreenOn.set(v) }
                Toggle(String(localized: "pref_custom_color_filter"), isOn: $crop)
                    .onChange(of: crop) { v in prefs.cropBorders.set(v) }
                Toggle(String(localized: "pref_reader_navigation"), isOn: $skipRead)
                    .onChange(of: skipRead) { v in prefs.skipRead.set(v) }
            }
        }
        .navigationTitle(String(localized: "pref_category_reader"))
        .onAppear {
            mode = prefs.defaultReadingMode.get()
            pageNumber = prefs.showPageNumber.get()
            keepOn = prefs.keepScreenOn.get()
            crop = prefs.cropBorders.get()
            skipRead = prefs.skipRead.get()
        }
    }
}

// MARK: - Download settings

struct DownloadSettingsScreen: View {
    private let prefs = AppContainer.shared.downloadPreferences
    @State private var wifiOnly = true
    @State private var saveCBZ = true
    @State private var downloadNew = false

    var body: some View {
        Form {
            Toggle(String(localized: "pref_download_new"), isOn: $wifiOnly)
                .onChange(of: wifiOnly) { v in prefs.downloadOnlyOverWifi.set(v) }
            Toggle(String(localized: "save_chapter_as_cbz"), isOn: $saveCBZ)
                .onChange(of: saveCBZ) { v in prefs.saveChaptersAsCBZ.set(v) }
            Toggle(String(localized: "pref_download_new"), isOn: $downloadNew)
                .onChange(of: downloadNew) { v in prefs.downloadNewChapters.set(v) }
        }
        .navigationTitle(String(localized: "pref_category_downloads"))
        .onAppear {
            wifiOnly = prefs.downloadOnlyOverWifi.get()
            saveCBZ = prefs.saveChaptersAsCBZ.get()
            downloadNew = prefs.downloadNewChapters.get()
        }
    }
}

// MARK: - Browse settings

struct BrowseSettingsScreen: View {
    private let prefs = AppContainer.shared.sourcePreferences
    @State private var showNSFW = true
    @State private var hideInLibrary = false

    var body: some View {
        Form {
            Toggle(String(localized: "pref_show_nsfw_source"), isOn: $showNSFW)
                .onChange(of: showNSFW) { v in prefs.showNsfwSource.set(v) }
            Toggle(String(localized: "pref_browse_summary"), isOn: $hideInLibrary)
                .onChange(of: hideInLibrary) { v in prefs.hideInLibraryItems.set(v) }
            NavigationLink(String(localized: "label_extensions")) {
                ExtensionsScreen()
            }
        }
        .navigationTitle(String(localized: "label_sources"))
        .onAppear {
            showNSFW = prefs.showNsfwSource.get()
            hideInLibrary = prefs.hideInLibraryItems.get()
        }
    }
}

// MARK: - Security

struct SecuritySettingsScreen: View {
    private let prefs = AppContainer.shared.appPreferences
    @State private var useLock = false
    @State private var status = ""

    var body: some View {
        Form {
            Toggle(String(localized: "lock_with_biometrics"), isOn: $useLock)
                .onChange(of: useLock) { v in
                    if v {
                        Task { await enableLock() }
                    } else {
                        prefs.useAuthenticator.set(false)
                    }
                }
            if !status.isEmpty {
                Text(status).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(String(localized: "pref_category_security"))
        .onAppear { useLock = prefs.useAuthenticator.get() }
    }

    private func enableLock() async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            status = error?.localizedDescription ?? String(localized: "pref_security")
            useLock = false
            return
        }
        do {
            let ok = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "lock_with_biometrics")
            )
            prefs.useAuthenticator.set(ok)
            useLock = ok
            status = ok ? String(localized: "pref_security") : String(localized: "action_cancel")
        } catch {
            useLock = false
            status = error.localizedDescription
        }
    }
}

// MARK: - Advanced

struct AdvancedSettingsScreen: View {
    @State private var message = ""

    var body: some View {
        Form {
            Section {
                Button(String(localized: "pref_category_advanced"), role: .destructive) {
                    clearCaches()
                }
                Button(String(localized: "action_install")) {
                    do {
                        try ExtensionStoreManager.shared.installDemoExtension()
                        if let manager = AppContainer.shared.resolve(DefaultSourceManager.self) {
                            ExtensionStoreManager.shared.loadAll(into: manager)
                        }
                        message = String(localized: "action_install")
                    } catch {
                        message = error.localizedDescription
                    }
                }
            }
            if !message.isEmpty {
                Text(message).font(.footnote)
            }
            Section(String(localized: "pref_category_advanced")) {
                LabeledContent(String(localized: "pref_category_advanced")) {
                    Text(AppContainer.shared.databaseReady ? String(localized: "on") : String(localized: "off"))
                }
                LabeledContent(String(localized: "pref_category_advanced")) {
                    Text("0.1.0-dev")
                }
            }
        }
        .navigationTitle(String(localized: "pref_category_advanced"))
    }

    private func clearCaches() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        try? FileManager.default.removeItem(at: caches.appendingPathComponent("covers"))
        message = String(localized: "pref_category_advanced")
    }
}
