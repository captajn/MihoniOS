import SwiftUI
import Core
import Extensions
import SourceAPI
import DesignSystem

struct ExtensionsScreen: View {
    @State private var installed: [InstalledExtension] = []
    @State private var stores: [ExtensionStoreEntry] = []
    @State private var remote: [RemoteExtensionInfo] = []
    @State private var message: String?
    @State private var storeURL = ""
    @State private var storeName = ""

    var body: some View {
        List {
            Section(String(localized: "label_extensions")) {
                if installed.isEmpty {
                    Text(String(localized: "extensions_empty"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(installed) { ext in
                        VStack(alignment: .leading) {
                            Text(ext.name)
                            Text("\(ext.lang) · v\(ext.version) · id \(ext.id)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Button(String(localized: "install_demo_extension")) {
                    installDemo()
                }
            }

            Section(String(localized: "extension_stores")) {
                ForEach(stores) { store in
                    VStack(alignment: .leading) {
                        Text(store.name)
                        Text(store.indexUrl)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            ExtensionStoreManager.shared.removeStore(indexUrl: store.indexUrl)
                            reload()
                        } label: {
                            Label(String(localized: "action_remove"), systemImage: "trash")
                        }
                    }
                }
                TextField(String(localized: "extension_store_name"), text: $storeName)
                TextField(String(localized: "extension_index_url"), text: $storeURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                Button(String(localized: "extension_add_store")) {
                    guard !storeURL.isEmpty else { return }
                    ExtensionStoreManager.shared.addStore(
                        ExtensionStoreEntry(indexUrl: storeURL, name: storeName.isEmpty ? storeURL : storeName)
                    )
                    storeURL = ""
                    storeName = ""
                    reload()
                }
                Button(String(localized: "extension_refresh")) {
                    Task { await fetchRemote() }
                }
            }

            if !remote.isEmpty {
                Section(String(localized: "extension_available")) {
                    ForEach(remote) { item in
                        VStack(alignment: .leading) {
                            Text(item.name)
                            Text("\(item.lang) · \(item.version)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let message {
                Section {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section {
                Text(String(localized: "extensions_description"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("How to add sources") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Go to Browse → Extensions")
                        .font(.footnote)
                    Text("2. Tap 'Refresh remote index' to load available extensions")
                        .font(.footnote)
                    Text("3. Extensions from Keiyoushi store are listed below")
                        .font(.footnote)
                    Text("4. Note: APK extensions from Android are NOT supported on iOS")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("5. Use Local source (Documents/local) for offline CBZ/ZIP files")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(String(localized: "label_extensions"))
        .onAppear { reload() }
        .refreshable { reload() }
    }

    private func reload() {
        installed = ExtensionStoreManager.shared.installedExtensions()
        stores = ExtensionStoreManager.shared.getStores()
        if let manager = AppContainer.shared.resolve(DefaultSourceManager.self) {
            ExtensionStoreManager.shared.loadAll(into: manager)
        }
    }

    private func installDemo() {
        do {
            try ExtensionStoreManager.shared.installDemoExtension()
            reload()
            message = String(localized: "demo_extension_installed")
        } catch {
            message = error.localizedDescription
        }
    }

    private func fetchRemote() async {
        var all: [RemoteExtensionInfo] = []
        for store in ExtensionStoreManager.shared.getStores() {
            do {
                let list = try await ExtensionStoreManager.shared.fetchIndex(store: store)
                all.append(contentsOf: list)
            } catch {
                message = error.localizedDescription
            }
        }
        remote = all
    }
}

struct GlobalSearchScreen: View {
    @State private var query = ""
    @State private var results: [(source: String, manga: SManga)] = []
    @State private var isSearching = false
    @State private var navigateId: MangaNavID?

    var body: some View {
        List {
            Section {
                TextField(String(localized: "global_search_hint"), text: $query)
                    .textInputAutocapitalization(.never)
                    .onSubmit { Task { await search() } }
                Button(String(localized: "action_search")) { Task { await search() } }
                    .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
            }

            if isSearching {
                ProgressView()
            }

            Section(String(localized: "global_search_results")) {
                if results.isEmpty {
                    Text(String(localized: "No results"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(results.enumerated()), id: \.offset) { _, row in
                        Button {
                            Task { await open(row.manga, sourceName: row.source) }
                        } label: {
                            VStack(alignment: .leading) {
                                Text(row.manga.title)
                                Text(row.source)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "action_search"))
        .background(
            NavigationLink(
                destination: Group {
                    if let nav = navigateId {
                        MangaDetailScreen(mangaId: nav.id)
                    }
                },
                isActive: Binding(
                    get: { navigateId != nil },
                    set: { if !$0 { navigateId = nil } }
                )
            ) { EmptyView() }
            .hidden()
        )
    }

    private func search() async {
        isSearching = true
        defer { isSearching = false }
        results = []
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        guard let manager = AppContainer.shared.resolve(SourceManager.self)
            ?? AppContainer.shared.resolve(DefaultSourceManager.self) else { return }

        var found: [(String, SManga)] = []
        for source in manager.getCatalogueSources() {
            do {
                let page = try await source.getSearchManga(page: 1, query: q, filters: FilterList())
                for m in page.mangas.prefix(10) {
                    found.append((source.name, m))
                }
            } catch {
                continue
            }
        }
        results = found
    }

    private func open(_ manga: SManga, sourceName: String) async {
        guard let manager = AppContainer.shared.resolve(SourceManager.self)
            ?? AppContainer.shared.resolve(DefaultSourceManager.self),
              let source = manager.getCatalogueSources().first(where: { $0.name == sourceName })
        else { return }
        do {
            let saved = try await LibraryImportService.openManga(
                sourceId: source.id,
                sManga: manga,
                addToLibrary: false
            )
            navigateId = MangaNavID(id: saved.id)
        } catch {}
    }
}
