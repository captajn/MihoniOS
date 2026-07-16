import SwiftUI
import Combine
import Core
import SourceAPI
import DesignSystem
import Domain

@MainActor
final class BrowseViewModel: ObservableObject {
    @Published var sources: [SourceRow] = []
    @Published var pinnedSourceIds: Set<String> = []

    struct SourceRow: Identifiable {
        let id: Int64
        let name: String
        let lang: String
        let supportsLatest: Bool
    }

    func load() {
        let manager = AppContainer.shared.resolve(SourceManager.self)
            ?? AppContainer.shared.resolve(DefaultSourceManager.self)
        guard let manager else {
            sources = []
            return
        }
        pinnedSourceIds = AppContainer.shared.sourcePreferences.pinnedSources.get()
        sources = manager.getCatalogueSources().sorted { a, b in
            let aPinned = pinnedSourceIds.contains(String(a.id))
            let bPinned = pinnedSourceIds.contains(String(b.id))
            if aPinned != bPinned { return aPinned }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }.map {
            SourceRow(
                id: $0.id,
                name: $0.name,
                lang: $0.lang,
                supportsLatest: $0.supportsLatest
            )
        }
    }
}

struct BrowseScreen: View {
    @StateObject private var model = BrowseViewModel()

    var body: some View {
        List {
            Section {
                NavigationLink {
                    GlobalSearchScreen()
                } label: {
                    Label(String(localized: "action_search"), systemImage: "magnifyingglass")
                }
                NavigationLink {
                    ExtensionsScreen()
                } label: {
                    Label(String(localized: "label_extensions"), systemImage: "puzzlepiece.extension")
                }
                NavigationLink {
                    MigrateScreen()
                } label: {
                    Label(String(localized: "label_migration"), systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section(String(localized: "label_sources")) {
                if model.sources.isEmpty {
                    Text(String(localized: "empty_screen"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.sources) { source in
                        NavigationLink {
                            SourceBrowseScreen(sourceId: source.id, sourceName: source.name)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        if model.pinnedSourceIds.contains(String(source.id)) {
                                            Image(systemName: "pin.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(source.name)
                                    }
                                    if !source.lang.isEmpty {
                                        Text(source.lang.uppercased())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if source.id == LocalSource.idValue {
                                    Text(String(localized: "label_local"))
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.blue.opacity(0.15), in: Capsule())
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "label_sources"))
        .task { model.load() }
        .refreshable { model.load() }
    }
}

struct SourceBrowseScreen: View {
    let sourceId: Int64
    let sourceName: String

    @State private var mangas: [SManga] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var mode: BrowseMode = .popular
    @State private var openingURL: String?
    @State private var navigateMangaId: MangaNavID?
    @State private var alertError: String?

    enum BrowseMode: String, CaseIterable {
        case popular = "Popular"
        case latest = "Latest"
        case search = "Search"
    }

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        Group {
            if isLoading && mangas.isEmpty {
                LoadingView()
            } else if let errorMessage {
                EmptyStateView(title: String(localized: "action_show_errors"), message: errorMessage, systemImage: "exclamationmark.triangle")
            } else if mangas.isEmpty {
                EmptyStateView(
                    title: String(localized: "empty_screen"),
                    message: sourceId == LocalSource.idValue
                        ? String(localized: "empty_screen")
                        : String(localized: "empty_screen"),
                    systemImage: "tray"
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(mangas.enumerated()), id: \.offset) { _, manga in
                            Button {
                                Task { await open(manga) }
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    ZStack {
                                        MangaCoverView(title: manga.title, url: manga.thumbnailUrl)
                                        if openingURL == manga.url {
                                            Color.black.opacity(0.35)
                                            ProgressView().tint(.white)
                                        }
                                    }
                                    Text(manga.title)
                                        .font(.caption)
                                        .lineLimit(2)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(openingURL != nil)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(sourceName)
        .background(
            NavigationLink(
                destination: Group {
                    if let nav = navigateMangaId {
                        MangaDetailScreen(mangaId: nav.id)
                    }
                },
                isActive: Binding(
                    get: { navigateMangaId != nil },
                    set: { if !$0 { navigateMangaId = nil } }
                )
            ) { EmptyView() }
            .hidden()
        )
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Mode", selection: $mode) {
                    ForEach(BrowseMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
            }
        }
        .onChange(of: mode) { _ in
            Task { await load() }
        }
        .task { await load() }
        .refreshable { await load() }
        .alert(String(localized: "action_show_errors"), isPresented: Binding(
            get: { alertError != nil },
            set: { if !$0 { alertError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertError ?? "")
        }
    }

    private func open(_ manga: SManga) async {
        openingURL = manga.url
        defer { openingURL = nil }
        do {
            let saved = try await LibraryImportService.openManga(
                sourceId: sourceId,
                sManga: manga,
                addToLibrary: false
            )
            navigateMangaId = MangaNavID(id: saved.id)
        } catch {
            alertError = error.localizedDescription
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let manager = AppContainer.shared.resolve(SourceManager.self)
            ?? AppContainer.shared.resolve(DefaultSourceManager.self),
              let source = manager.get(sourceId) as? any CatalogueSource
        else {
            errorMessage = String(localized: "local_source")
            return
        }

        do {
            let page: MangasPage
            switch mode {
            case .popular:
                page = try await source.getPopularManga(page: 1)
            case .latest:
                page = try await source.getLatestUpdates(page: 1)
            case .search:
                page = try await source.getSearchManga(page: 1, query: "", filters: FilterList())
            }
            mangas = page.mangas
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct MangaNavID: Hashable, Identifiable {
    let id: Int64
}
