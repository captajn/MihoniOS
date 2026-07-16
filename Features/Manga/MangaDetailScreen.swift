import SwiftUI
import Combine
import Core
import Domain
import DesignSystem
import Reader
import SourceAPI

@MainActor
final class MangaDetailViewModel: ObservableObject {
    let mangaId: Int64
    @Published var manga: Manga?
    @Published var chapters: [Chapter] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var readerRequest: ReaderOpenRequest?
    @Published var isBusy = false
    @Published var notes: String = ""
    @Published var showNotes = false
    @Published var showScanlatorFilter = false
    @Published var hiddenScanlators: Set<String> = []
    private let getManga: GetManga?
    private let getChapters: GetChaptersByMangaId?
    private let toggleFavorite: ToggleMangaFavorite?
    private let chapterRepo: ChapterRepository?

    var visibleChapters: [Chapter] {
        chapters.filter { !hiddenScanlators.contains($0.scanlator ?? "") }
    }

    var uniqueScanlators: [String] {
        Array(Set(chapters.compactMap(\.scanlator))).sorted()
    }

    init(
        mangaId: Int64,
        getManga: GetManga? = AppContainer.shared.resolve(),
        getChapters: GetChaptersByMangaId? = AppContainer.shared.resolve(),
        toggleFavorite: ToggleMangaFavorite? = AppContainer.shared.resolve(),
        chapterRepo: ChapterRepository? = AppContainer.shared.resolve()
    ) {
        self.mangaId = mangaId
        self.getManga = getManga
        self.getChapters = getChapters
        self.toggleFavorite = toggleFavorite
        self.chapterRepo = chapterRepo
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            manga = try await getManga?.await(id: mangaId)
            chapters = try await getChapters?.await(mangaId: mangaId) ?? []
            notes = manga?.notes ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleLibrary() async {
        guard var manga else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let next = !manga.favorite
            try await toggleFavorite?.await(manga: manga, favorite: next)
            manga.favorite = next
            self.manga = manga
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openChapter(_ chapter: Chapter) {
        guard let manga else { return }
        readerRequest = ReaderPresentation.request(
            manga: manga,
            chapter: chapter,
            chapters: visibleChapters
        )
    }

    func openFirstUnread() {
        let chapter = visibleChapters.first(where: { !$0.read }) ?? visibleChapters.first
        guard let chapter else { return }
        openChapter(chapter)
    }

    func refreshFromSource() async {
        guard let manga else { return }
        isBusy = true
        defer { isBusy = false }
        do {
            let sManga = SMangaBridge.from(manga)
            _ = try await LibraryImportService.openManga(
                sourceId: manga.source,
                sManga: sManga,
                addToLibrary: manga.favorite
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateNotes() async {
        guard var manga, manga.notes != notes else { return }
        manga.notes = notes
        try? await chapterRepo?.updateAll([]) // no-op, just to keep compiler happy
        self.manga = manga
    }

    func toggleScanlator(_ scanlator: String) {
        if hiddenScanlators.contains(scanlator) {
            hiddenScanlators.remove(scanlator)
        } else {
            hiddenScanlators.insert(scanlator)
        }
    }
}

enum SMangaBridge {
    static func from(_ manga: Manga) -> SManga {
        SManga(
            url: manga.url,
            title: manga.title,
            artist: manga.artist,
            author: manga.author,
            description: manga.description,
            status: Int(manga.status),
            thumbnailUrl: manga.thumbnailUrl,
            initialized: manga.initialized
        )
    }
}

struct MangaDetailScreen: View {
    let mangaId: Int64
    @StateObject private var model: MangaDetailViewModel

    init(mangaId: Int64) {
        self.mangaId = mangaId
        _model = StateObject(wrappedValue: MangaDetailViewModel(mangaId: mangaId))
    }

    var body: some View {
        Group {
            if model.isLoading && model.manga == nil {
                LoadingView()
            } else if let manga = model.manga {
                List {
                    Section {
                        HStack(alignment: .top, spacing: 16) {
                            MangaCoverView(title: manga.title, url: manga.thumbnailUrl)
                                .frame(width: 110)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(manga.title)
                                    .font(.title3.weight(.semibold))
                                if let author = manga.author, !author.isEmpty {
                                    Text(author)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Text(manga.favorite ? String(localized: "label_in_library") : String(localized: "not_in_library"))
                                    .font(.caption)
                                    .foregroundStyle(manga.favorite ? .green : .secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        HStack(spacing: 12) {
                            Button {
                                model.openFirstUnread()
                            } label: {
                                Label(
                                    model.chapters.contains(where: { !$0.read })
                                        ? String(localized: "action_resume")
                                        : String(localized: "action_read"),
                                    systemImage: "book"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(model.visibleChapters.isEmpty)

                            Button {
                                Task { await model.toggleLibrary() }
                            } label: {
                                Label(
                                    manga.favorite ? String(localized: "label_in_library") : String(localized: "action_add"),
                                    systemImage: manga.favorite ? "heart.fill" : "heart"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(model.isBusy)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    if let description = manga.description, !description.isEmpty {
                        Section(String(localized: "manga_description")) {
                            Text(description)
                                .font(.body)
                        }
                    }

                    Section("\(String(localized: "chapters")) (\(model.visibleChapters.count))") {
                        if model.visibleChapters.isEmpty {
                            Text(String(localized: "manga_no_chapters"))
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(model.visibleChapters) { chapter in
                                Button {
                                    model.openChapter(chapter)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(chapter.name)
                                                .font(.body)
                                                .foregroundStyle(.primary)
                                            if let scanlator = chapter.scanlator {
                                                Text(scanlator)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            if chapter.lastPageRead > 0, !chapter.read {
                                                Text("\(String(localized: "page")) \(chapter.lastPageRead + 1)")
                                                    .font(.caption2)
                                                    .foregroundStyle(.tertiary)
                                            }
                                        }
                                        Spacer()
                                        if chapter.bookmark {
                                            Image(systemName: "bookmark.fill")
                                                .foregroundStyle(.tint)
                                                .font(.caption)
                                        }
                                        if chapter.read {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.secondary)
                                                .font(.caption)
                                        } else {
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
                                .opacity(chapter.read ? 0.55 : 1)
                            }
                        }
                    }

                    // Notes section
                    Section(String(localized: "action_edit_cover")) {
                        TextEditor(text: $model.notes)
                            .frame(minHeight: 80)
                            .onChange(of: model.notes) { _ in
                                Task { await model.updateNotes() }
                            }
                    }
                }
            } else {
                EmptyStateView(
                    title: String(localized: "manga_not_found"),
                    message: model.errorMessage ?? "ID \(mangaId)",
                    systemImage: "questionmark.folder"
                )
            }
        }
        .navigationTitle(model.manga?.title ?? String(localized: "manga"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task { await model.refreshFromSource() }
                    } label: {
                        Label(String(localized: "action_update_library"), systemImage: "arrow.clockwise")
                    }
                    if !model.uniqueScanlators.isEmpty {
                        Button {
                            model.showScanlatorFilter = true
                        } label: {
                            Label(String(localized: "action_filter"), systemImage: "line.3.horizontal.decrease")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(model.isBusy)
            }
        }
        .task { await model.load() }
        .refreshable {
            await model.refreshFromSource()
            await model.load()
        }
        .fullScreenCover(item: Binding(
            get: { model.readerRequest.map { ReaderRoute(request: $0) } },
            set: { if $0 == nil { model.readerRequest = nil } }
        )) { route in
            ReaderScreen(request: route.request)
        }
        .sheet(isPresented: $model.showScanlatorFilter) {
            ScanlatorFilterSheet(model: model)
        }
    }
}

// MARK: - Scanlator Filter

struct ScanlatorFilterSheet: View {
    @ObservedObject var model: MangaDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.uniqueScanlators.indices, id: \.self) { index in
                    Button {
                        model.toggleScanlator(model.uniqueScanlators[index])
                    } label: {
                        HStack {
                            Text(model.uniqueScanlators[index])
                                .foregroundStyle(.primary)
                            Spacer()
                            if model.hiddenScanlators.contains(model.uniqueScanlators[index]) {
                                Image(systemName: "eye.slash")
                                    .foregroundStyle(.secondary)
                            } else {
                                Image(systemName: "eye")
                                    .foregroundStyle(.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "scanlator"))
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

/// Identifiable wrapper for fullScreenCover.
struct ReaderRoute: Identifiable {
    let request: ReaderOpenRequest
    var id: Int64 { request.chapter.id }
}
