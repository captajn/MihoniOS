import SwiftUI
import Core
import Domain
import SourceAPI
import DesignSystem

struct MigrateScreen: View {
    @State private var library: [LibraryManga] = []
    @State private var selected: LibraryManga?
    @State private var candidates: [(source: String, sourceId: Int64, manga: SManga, score: Double)] = []
    @State private var message: String?
    @State private var isWorking = false

    var body: some View {
        List {
            Section(String(localized: "label_library")) {
                if library.isEmpty {
                    Text(String(localized: "information_empty_library")).foregroundStyle(.secondary)
                } else {
                    ForEach(library) { item in
                        Button {
                            selected = item
                            Task { await search(for: item) }
                        } label: {
                            HStack {
                                Text(item.manga.title)
                                Spacer()
                                if selected?.id == item.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }

            if let selected {
                Section("\(String(localized: "label_migration")) \(selected.manga.title)") {
                    if isWorking {
                        ProgressView()
                    } else if candidates.isEmpty {
                        Text(String(localized: "label_migration")).foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(candidates.enumerated()), id: \.offset) { _, row in
                            Button {
                                Task { await migrate(to: row) }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(row.manga.title)
                                    Text("\(row.source) · score \(String(format: "%.2f", row.score))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            if let message {
                Section { Text(message).font(.footnote) }
            }
        }
        .navigationTitle(String(localized: "label_migration"))
        .task { await loadLibrary() }
    }

    private func loadLibrary() async {
        guard let get = AppContainer.shared.resolve(GetLibraryManga.self) else { return }
        library = (try? await get.await()) ?? []
    }

    private func search(for item: LibraryManga) async {
        isWorking = true
        defer { isWorking = false }
        candidates = []
        guard let manager = AppContainer.shared.resolve(SourceManager.self)
            ?? AppContainer.shared.resolve(DefaultSourceManager.self) else { return }

        var found: [(String, Int64, SManga, Double)] = []
        for source in manager.getCatalogueSources() where source.id != item.manga.source {
            do {
                let page = try await source.getSearchManga(
                    page: 1,
                    query: item.manga.title,
                    filters: FilterList()
                )
                for m in page.mangas.prefix(5) {
                    let score = SmartSearch.score(query: item.manga.title, candidate: m.title)
                    if score >= 0.4 {
                        found.append((source.name, source.id, m, score))
                    }
                }
            } catch { continue }
        }
        candidates = found.sorted { $0.3 > $1.3 }
    }

    private func migrate(to row: (source: String, sourceId: Int64, manga: SManga, score: Double)) async {
        guard let selected,
              let mangaRepo = AppContainer.shared.resolve(MangaRepository.self),
              let chapterRepo = AppContainer.shared.resolve(ChapterRepository.self),
              let categoryRepo = AppContainer.shared.resolve(CategoryRepository.self),
              let trackRepo = AppContainer.shared.resolve(TrackRepository.self)
        else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            let newManga = try await LibraryImportService.openManga(
                sourceId: row.sourceId,
                sManga: row.manga,
                addToLibrary: true
            )
            let migrator = MigrateManga(
                mangaRepo: mangaRepo,
                chapterRepo: chapterRepo,
                categoryRepo: categoryRepo,
                trackRepo: trackRepo
            )
            _ = try await migrator.await(
                oldManga: selected.manga,
                newManga: newManga,
                flags: [.chapters, .categories, .tracking, .extra, .deleteOld]
            )
            message = "\(String(localized: "label_migration")) \(row.source)"
            await loadLibrary()
            candidates = []
            self.selected = nil
        } catch {
            message = error.localizedDescription
        }
    }
}
