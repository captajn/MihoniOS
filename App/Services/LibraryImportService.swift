import Foundation
import Core
import Domain
import SourceAPI

/// Opens / imports titles from a catalogue source into the local DB.
@MainActor
enum LibraryImportService {
    static func openManga(sourceId: Int64, sManga: SManga, addToLibrary: Bool = false) async throws -> Manga {
        let network = AppContainer.shared.require(NetworkToLocalManga.self)
        let sync = AppContainer.shared.require(SyncChaptersWithSource.self)
        let toggle = AppContainer.shared.resolve(ToggleMangaFavorite.self)
        let sourceManager = AppContainer.shared.resolve(SourceManager.self)
            ?? AppContainer.shared.resolve(DefaultSourceManager.self)

        var manga = try await network.await(
            sourceId: sourceId,
            url: sManga.url,
            title: sManga.title,
            artist: sManga.artist,
            author: sManga.author,
            description: sManga.description,
            thumbnailUrl: sManga.thumbnailUrl,
            status: Int64(sManga.status),
            favorite: addToLibrary
        )

        if addToLibrary, !manga.favorite {
            try await toggle?.await(manga: manga, favorite: true)
            manga.favorite = true
        }

        // Fetch chapters from source
        if let source = sourceManager?.get(sourceId) {
            let update = try await source.getMangaUpdate(
                manga: sManga,
                chapters: [],
                fetchDetails: true,
                fetchChapters: true
            )
            if let chapters = update.chapters {
                let incoming = chapters.map {
                    SyncChaptersWithSource.IncomingChapter(
                        url: $0.url,
                        name: $0.name,
                        dateUpload: $0.dateUpload,
                        chapterNumber: $0.chapterNumber,
                        scanlator: $0.scanlator
                    )
                }
                _ = try await sync.await(mangaId: manga.id, sourceChapters: incoming)
            }

            // Update metadata from source
            if let repo = AppContainer.shared.resolve(MangaRepository.self) {
                var updated = manga
                updated.title = update.manga.title.isEmpty ? manga.title : update.manga.title
                updated.author = update.manga.author ?? manga.author
                updated.artist = update.manga.artist ?? manga.artist
                updated.description = update.manga.description ?? manga.description
                updated.thumbnailUrl = update.manga.thumbnailUrl ?? manga.thumbnailUrl
                updated.status = Int64(update.manga.status)
                updated.initialized = true
                try await repo.update(updated)
                manga = updated
            }
        }

        return manga
    }
}
