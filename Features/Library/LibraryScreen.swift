import SwiftUI
import Combine
import Core
import Domain
import DesignSystem

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var items: [LibraryManga] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategoryId: Int64 = -1
    @Published var categories: [Domain.Category] = []
    @Published var sortMode: LibrarySortMode = .alphabetical
    @Published var sortAscending: Bool = true
    @Published var displayMode: LibraryDisplayMode = .comfortableGrid
    @Published var isSelectMode = false
    @Published var selectedMangaIds: Set<Int64> = []

    private let getLibrary: GetLibraryManga?
    private let getCategories: GetCategories?
    private let libraryPrefs: LibraryPreferences

    init(
        getLibrary: GetLibraryManga? = AppContainer.shared.resolve(),
        getCategories: GetCategories? = AppContainer.shared.resolve(),
        libraryPrefs: LibraryPreferences = AppContainer.shared.libraryPreferences
    ) {
        self.getLibrary = getLibrary
        self.getCategories = getCategories
        self.libraryPrefs = libraryPrefs
        self.sortMode = libraryPrefs.sortingMode.get()
        self.sortAscending = libraryPrefs.sortingDirection.get() == .ascending
        self.displayMode = libraryPrefs.displayMode.get()
    }

    var filtered: [LibraryManga] {
        var result = items

        // Filter by category
        if selectedCategoryId >= 0 {
            result = result.filter { $0.categories.contains(selectedCategoryId) }
        }

        // Filter by search
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            result = result.filter { $0.manga.title.localizedCaseInsensitiveContains(q) }
        }

        // Sort using sorted(by:) to avoid compiler confusion
        let sortedResult: [LibraryManga]
        switch sortMode {
        case .alphabetical:
            sortedResult = result.sorted(by: { (a: LibraryManga, b: LibraryManga) -> Bool in
                let cmp = a.manga.title.localizedCaseInsensitiveCompare(b.manga.title) == .orderedAscending
                return sortAscending ? cmp : !cmp
            })
        case .lastRead:
            sortedResult = result.sorted(by: { (a: LibraryManga, b: LibraryManga) -> Bool in
                sortAscending ? a.lastRead < b.lastRead : a.lastRead > b.lastRead
            })
        case .lastUpdate:
            sortedResult = result.sorted(by: { (a: LibraryManga, b: LibraryManga) -> Bool in
                sortAscending ? a.manga.lastUpdate < b.manga.lastUpdate : a.manga.lastUpdate > b.manga.lastUpdate
            })
        case .unreadCount:
            sortedResult = result.sorted(by: { (a: LibraryManga, b: LibraryManga) -> Bool in
                sortAscending ? a.unreadCount < b.unreadCount : a.unreadCount > b.unreadCount
            })
        case .totalChapters:
            sortedResult = result.sorted(by: { (a: LibraryManga, b: LibraryManga) -> Bool in
                sortAscending ? a.totalChapters < b.totalChapters : a.totalChapters > b.totalChapters
            })
        case .latestChapter:
            sortedResult = result.sorted(by: { (a: LibraryManga, b: LibraryManga) -> Bool in
                sortAscending ? a.latestUpload < b.latestUpload : a.latestUpload > b.latestUpload
            })
        case .chapterFetchDate:
            sortedResult = result.sorted(by: { (a: LibraryManga, b: LibraryManga) -> Bool in
                sortAscending ? a.chapterFetchedAt < b.chapterFetchedAt : a.chapterFetchedAt > b.chapterFetchedAt
            })
        case .dateAdded:
            sortedResult = result.sorted { a, b in
                sortAscending ? a.manga.dateAdded < b.manga.dateAdded : a.manga.dateAdded > b.manga.dateAdded
            }
        case .random:
            sortedResult = result.shuffled()
        }

        return sortedResult
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if let getCategories {
                categories = try await getCategories.await()
            }
            guard let getLibrary else {
                errorMessage = String(localized: "Database not ready")
                return
            }
            items = try await getLibrary.await()
        } catch {
            errorMessage = error.localizedDescription
            AppLog.error("Failed to load library", error: error, category: "library")
        }
    }

    func loadPrefs() {
        sortMode = libraryPrefs.sortingMode.get()
        sortAscending = libraryPrefs.sortingDirection.get() == .ascending
        displayMode = libraryPrefs.displayMode.get()
    }

    func toggleSelection(_ mangaId: Int64) {
        if selectedMangaIds.contains(mangaId) {
            selectedMangaIds.remove(mangaId)
        } else {
            selectedMangaIds.insert(mangaId)
        }
        isSelectMode = !selectedMangaIds.isEmpty
    }

    func clearSelection() {
        selectedMangaIds.removeAll()
        isSelectMode = false
    }
}

struct LibraryScreen: View {
    @StateObject private var model = LibraryViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var showSortFilter = false

    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 160), spacing: 12),
    ]

    var body: some View {
        Group {
            if model.isLoading && model.items.isEmpty {
                LoadingView(String(localized: "loading"))
            } else if model.filtered.isEmpty {
                EmptyStateView(
                    title: model.searchText.isEmpty
                        ? String(localized: "Empty library")
                        : String(localized: "No results"),
                    message: model.searchText.isEmpty
                        ? String(localized: "library_empty_description")
                        : String(localized: "Try a different search."),
                    systemImage: "books.vertical",
                    actionTitle: model.searchText.isEmpty ? String(localized: "label_sources") : nil,
                    action: model.searchText.isEmpty
                        ? { appState.selectedTab = .browse }
                        : nil
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(model.filtered) { item in
                            NavigationLink(value: item.manga.id) {
                                LibraryGridItem(item: item, isSelected: model.selectedMangaIds.contains(item.manga.id))
                                    .overlay(alignment: .topTrailing) {
                                        if model.isSelectMode {
                                            Image(systemName: model.selectedMangaIds.contains(item.manga.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(model.selectedMangaIds.contains(item.manga.id) ? .blue : .gray)
                                                .padding(6)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .onLongPressGesture {
                                model.toggleSelection(item.manga.id)
                            }
                            .onTapGesture {
                                if model.isSelectMode {
                                    model.toggleSelection(item.manga.id)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(String(localized: "label_library"))
        .navigationDestination(for: Int64.self) { mangaId in
            MangaDetailScreen(mangaId: mangaId)
        }
        .searchable(text: $model.searchText, prompt: String(localized: "action_search"))
        .refreshable { await model.load() }
        .task { await model.load() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if model.isSelectMode {
                    Button(String(localized: "action_cancel")) {
                        model.clearSelection()
                    }
                } else {
                    Menu {
                        Button {
                            showSortFilter = true
                        } label: {
                            Label(String(localized: "action_sort"), systemImage: "arrow.up.arrow.down")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if let error = model.errorMessage {
                ErrorBanner(message: error) {
                    Task { await model.load() }
                }
            }
        }
        .sheet(isPresented: $showSortFilter) {
            LibrarySortFilterSheet(model: model)
        }
    }
}

// MARK: - Sort/Filter Sheet

struct LibrarySortFilterSheet: View {
    @ObservedObject var model: LibraryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "action_sort")) {
                    ForEach(LibrarySortMode.allCases, id: \.rawValue) { mode in
                        Button {
                            if model.sortMode == mode {
                                model.sortAscending.toggle()
                            } else {
                                model.sortMode = mode
                            }
                        } label: {
                            HStack {
                                Text(mode.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if model.sortMode == mode {
                                    Image(systemName: model.sortAscending ? "arrow.up" : "arrow.down")
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                    }
                }

                Section(String(localized: "action_display")) {
                    ForEach(LibraryDisplayMode.allCases, id: \.rawValue) { mode in
                        Button {
                            model.displayMode = mode
                        } label: {
                            HStack {
                                Text(mode.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if model.displayMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        }
                    }
                }

                Section(String(localized: "categories")) {
                    Button {
                        model.selectedCategoryId = -1
                    } label: {
                        HStack {
                            Text(String(localized: "all"))
                                .foregroundStyle(.primary)
                            Spacer()
                            if model.selectedCategoryId == -1 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.accent)
                            }
                        }
                    }
                    ForEach(model.categories.filter { !$0.isSystemCategory }) { cat in
                        Button {
                            model.selectedCategoryId = cat.id
                        } label: {
                            HStack {
                                Text(cat.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if model.selectedCategoryId == cat.id {
                                    Image(systemName: "checkmark")
                                    .foregroundStyle(.accent)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "action_filter"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "action_done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Grid Item

private struct LibraryGridItem: View {
    let item: LibraryManga
    var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                MangaCoverView(title: item.manga.title, url: item.manga.thumbnailUrl)
                    .opacity(isSelected ? 0.7 : 1)
                if item.unreadCount > 0 {
                    Text("\(item.unreadCount)")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue, in: Capsule())
                        .foregroundStyle(.white)
                        .padding(6)
                }
            }
            Text(item.manga.title)
                .font(.caption)
                .lineLimit(2)
                .foregroundStyle(.primary)
        }
    }
}
