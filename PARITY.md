# Mihon iOS — Feature parity checklist

Tracking Android → iOS port progress. See [plan-ios.md](../plan-ios.md).

Legend: ✅ done · 🧩 partial · ⏳ planned · ❌ N/A Android-only

> **Cập nhật:** 2026-07-15 — Phân tích chi tiết Android vs iOS source code.

## Phase 0 — Bootstrap

| Feature | Status | Notes |
|---------|--------|-------|
| XcodeGen project + SPM modules | ✅ | `ios/project.yml`, `Package.swift` |
| Design system (theme, empty, cover) | ✅ | module `DesignSystem` — MihonTheme, EmptyStateView, MangaCoverView, LoadingView |
| PreferenceStore + theme prefs | ✅ | module `Core` — PreferenceStore, ReaderPreferences, LibraryPreferences, SourcePreferences |
| DI container | ✅ | `AppContainer` — resolve/tactory pattern |
| 5-tab shell | ✅ | Library / Updates / History / Browse / More — `AppState.selectedTab` |
| Onboarding | ✅ | `OnboardingView` — localized 3-page flow |
| Logging | ✅ | `AppLog` / OSLog |

## Phase 1 — Data foundation

| Feature | Status | Notes |
|---------|--------|-------|
| Domain models | ✅ | Manga, Chapter, Category, History, Track, Updates, SourceInfo |
| Repository protocols | ✅ | MangaRepository, ChapterRepository, CategoryRepository, HistoryRepository, TrackRepository, SourceRepository |
| Use cases (core) | ✅ | Library, chapters, history, updates, categories, stats, migration |
| GRDB schema v1 | ✅ | Mirror SQLDelight tables |
| GRDB repositories | ✅ | MangaRepositoryGRDB, ChapterRepositoryGRDB, CategoryHistoryRepositoriesGRDB |
| Cover pipeline (Nuke) | 🧩 | AsyncImage placeholder; Nuke chưa tích hợp |
| Storage manager / folder picker | ⏳ | Documents/local hardcoded |

## Phase 2 — Local + Reader

| Feature | Status | Notes |
|---------|--------|-------|
| LocalSource scan folders | ✅ | Folders + CBZ titles, chapter layouts |
| ZIP/CBZ page loader | ✅ | `ArchivePageLoader` store+deflate |
| Directory page loader | ✅ | `DirectoryPageLoader` |
| HTTP page loader | ✅ | `HttpPageLoader` |
| Reader LTR/RTL/Vertical | ✅ | `PagerReaderView` TabView + zoom |
| Reader Webtoon | ✅ | `WebtoonReaderView` vertical continuous scroll |
| Reading mode switcher | ✅ | In-reader menu — 5 modes (RTL/LTR/Vert/Webtoon/Cont.) |
| Reader settings | 🧩 | ReadingMode, showPageNumber, keepScreenOn, cropBorders, skipRead |
| History on read | ✅ | Progress + duration upsert |
| Mark read at chapter end | ✅ | |
| Browse → detail → reader | ✅ | `LibraryImportService.openManga` |
| Add to library from detail | ✅ | Toggle favorite |
| Zoom double-tap | ✅ | `ZoomablePageView` UIScrollView |
| Edge tap navigation zones | ✅ | Left 28% prev, Center 44% menu, Right 28% next |

## Phase 3 — Download + Backup

| Feature | Status | Notes |
|---------|--------|-------|
| Download manager | ✅ | `DownloadManager` actor — queue, pause/resume, cancel, processQueue |
| Download queue UI | ✅ | `DownloadsScreen` — list, progress %, swipe cancel, pause/resume/clear toolbar |
| DownloadPageLoader | ✅ | `DownloadPageLoader` — offline reading từ downloaded files |
| Protobuf backup create | ✅ | `BackupService.createBackup()` — Manga/Chapters/History/Tracks/Categories/Sources |
| Protobuf backup restore | ✅ | `BackupService.restore()` — cross-platform with Android |
| Backup validator | ✅ | `BackupService.validate()` — missing sources/trackers |
| Backup gzip encode/decode | ✅ | `BackupEncoder.encodeGzip` / `BackupDecoder.decode` |
| Auto-download new chapters | ✅ | `autoDownloadNewChapters()` in DownloadManager |
| Background library update | ✅ | `LibraryUpdateBackground` — BGAppRefreshTask + BGProcessingTask + notifications |

## Phase 4 — Extensions + Browse

| Feature | Status | Notes |
|---------|--------|-------|
| Source protocols | ✅ | SourceAPI — `Source`, `CatalogueSource`, `SManga`, `SChapter`, `Filter` |
| SourceManager | ✅ | `DefaultSourceManager` — local registered |
| Browse sources UI | ✅ | `BrowseScreen` — sources list, Popular/Latest/Search mode, pinned sources |
| Source browse (popular/latest/search) | ✅ | `SourceBrowseScreen` — segmented picker |
| JS extension runtime | 🧩 | `JSExtensionSource` — QuickJS sandbox cơ bản |
| Extension stores | 🧩 | `ExtensionStoreManager` — add/remove stores, fetch remote index |
| Extensions screen UI | ✅ | `ExtensionsScreen` — installed/stores/available lists |
| Global search | ✅ | `GlobalSearchScreen` — search all sources |
| WebView login | ✅ | `WebViewScreen` — WKWebView wrapper |
| StubSource | 🧩 | DB table + repo ready, chưa full wiring |

## Phase 5 — Tracking + Library polish

| Feature | Status | Notes |
|---------|--------|-------|
| Library grid + badges | ✅ | `LibraryScreen` LazyVGrid + unread badge (blue capsule) |
| Library search | ✅ | `.searchable` trong Library |
| Categories CRUD UI | ✅ | `CategoriesScreen` — add/delete categories |
| Sort / filter / display modes | ✅ | `LibrarySortFilterSheet` — 3-tab sheet (Filter/Sort/Display) |
| Category tabs | ✅ | Category tab bar trên cùng Library screen |
| Multi-select | ✅ | Long-press selection + batch toolbar |
| Manga detail | ✅ | `MangaDetailScreen` — cover, author, description, chapter list, notes, scanlator filter |
| Trackers (11) | 🧩 | `TrackerManager` — 11 tracker classes, AniList GraphQL search works, MAL placeholder |
| Tracker protocol | ✅ | `Tracker` protocol + `BaseTracker` — login/logout/search/bind/update/refresh |
| Library update job | ⏳ | Chưa implement background refresh |

## Phase 6 — Rest

| Feature | Status | Notes |
|---------|--------|-------|
| Migrate | ✅ | `MigrateScreen` — smart search, score candidates, migrate with flags |
| Stats | ✅ | `StatsScreen` — library/chapters/reading time |
| Upcoming | ✅ | `UpcomingScreen` — calendar-based upcoming manga list |
| Full settings screens | ✅ | 9 screens: Appearance ✅, Library ✅, Reader ✅, Downloads ✅, Tracking ✅, Browse ✅, Data/Backup ✅, Security ✅, Advanced ✅ |
| Security / Face ID | ✅ | `SecuritySettingsScreen` — LAContext biometric auth |
| Widgets | 🧩 | `UpdatesWidget` stub — WidgetKit placeholder, chưa có real target |
| Deep links | ✅ | `DeepLinkHandler` — Universal Links + custom URL scheme |
| i18n (67 locales) | ✅ | `Localizable.xcstrings` — 935 keys, 67 languages, all screens localized |
| Reader navigation modes | ✅ | `NavigationMode.swift` — 5 modes (L-shape, Kindlish, Edge, R&L, Disabled) |
| Reader color filter | 🧩 | `ReaderColorFilter` enum defined, chưa apply trong view |
| Crash screen | ✅ | `CrashHandler` + `CrashScreen` — uncaught exceptions + signals |
| Support us | ✅ | `SupportScreen` — donation links |
| Incognito mode | ✅ | Toggle in MoreScreen + preference |
| Delete library dialog | ✅ | `DeleteLibraryDialog` — conditional "delete downloaded" checkbox |
| Updates filter | ✅ | `UpdatesFilterDialog` — filter by read/unread |

## Android-only (not ported)

| Feature | Status |
|---------|--------|
| APK extension installer | ❌ — iOS dùng JS runtime thay thế |
| Shizuku | ❌ |
| Material You wallpaper exact | ❌ (Dynamic Color approx via Monet theme) |
| Exact alarms / WorkManager | ❌ — iOS dùng BGAppRefreshTask |
| CrashActivity / GlobalExceptionHandler | ❌ — iOS dùng SwiftUI scene |

---

**Current milestone:** Phase 0–3 core + Phase 4–6 partial complete.  
**Next priorities:** Auto-download BG, i18n, WebView login, Upcoming, Real Widget target, Library sort/filter.
