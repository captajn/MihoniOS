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
    @State private var installingId: Int64?

    var body: some View {
        List {
            Section(String(localized: "label_extensions")) {
                if installed.isEmpty {
                    Text(String(localized: "label_extensions"))
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
                Button(String(localized: "action_install")) {
                    installDemo()
                }
            }

            Section(String(localized: "extensionStores")) {
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
                TextField(String(localized: "extensionStores"), text: $storeName)
                TextField(String(localized: "extensionStores"), text: $storeURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                Button(String(localized: "extensionStores")) {
                    guard !storeURL.isEmpty else { return }
                    ExtensionStoreManager.shared.addStore(
                        ExtensionStoreEntry(indexUrl: storeURL, name: storeName.isEmpty ? storeURL : storeName)
                    )
                    storeURL = ""
                    storeName = ""
                    reload()
                }
                Button(String(localized: "action_retry")) {
                    Task { await fetchRemote() }
                }
            }

            if !remote.isEmpty {
                Section(String(localized: "label_extensions")) {
                    ForEach(remote) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                Text("\(item.lang) · \(item.version)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if installingId == item.id {
                                ProgressView()
                            } else {
                                Button(String(localized: "action_install")) {
                                    Task { await install(item) }
                                }
                                .buttonStyle(.borderless)
                            }
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
                Text(String(localized: "label_extensions"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "how_to_add_sources_title")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "how_to_add_sources_local"))
                        .font(.footnote)
                    Text(String(localized: "how_to_add_sources_enhanced"))
                        .font(.footnote)
                    Text(String(localized: "how_to_add_sources_apk_warning"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(String(localized: "label_extensions"))
        .onAppear {
            reload()
            Task { await fetchRemote() }
        }
        .refreshable {
            reload()
            await fetchRemote()
        }
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
            message = String(localized: "action_install")
        } catch {
            message = error.localizedDescription
        }
    }

    private func install(_ item: RemoteExtensionInfo) async {
        installingId = item.id
        defer { installingId = nil }
        do {
            let manifest = try await ExtensionStoreManager.shared.installRemote(item)
            reload()
            message = "Installed \(manifest.name)"
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
                TextField(String(localized: "action_global_search_hint"), text: $query)
                    .textInputAutocapitalization(.never)
                    .onSubmit { Task { await search() } }
                Button(String(localized: "action_search")) { Task { await search() } }
                    .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
            }

            if isSearching {
                ProgressView()
            }

            Section(String(localized: "action_global_search")) {
                if results.isEmpty {
                    Text(String(localized: "no_results_found"))
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
