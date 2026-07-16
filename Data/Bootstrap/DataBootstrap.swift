import Foundation
import Core
import Domain

/// Wires Data layer into `AppContainer`.
public enum DataBootstrap {
    public static func start(container: AppContainer = .shared) throws {
        let database = try AppDatabase.makeDefault()

        let mangaRepo = MangaRepositoryGRDB(db: database)
        let chapterRepo = ChapterRepositoryGRDB(db: database)
        let categoryRepo = CategoryRepositoryGRDB(db: database)
        let historyRepo = HistoryRepositoryGRDB(db: database)
        let updatesRepo = UpdatesRepositoryGRDB(db: database)
        let trackRepo = TrackRepositoryGRDB(db: database)
        let sourceRepo = SourceRepositoryGRDB(db: database)

        container.register(database)
        container.register(mangaRepo as MangaRepository)
        container.register(chapterRepo as ChapterRepository)
        container.register(categoryRepo as CategoryRepository)
        container.register(historyRepo as HistoryRepository)
        container.register(updatesRepo as UpdatesRepository)
        container.register(trackRepo as TrackRepository)
        container.register(sourceRepo as SourceRepository)

        // Use cases
        container.register(GetLibraryManga(repository: mangaRepo))
        container.register(GetFavorites(repository: mangaRepo))
        container.register(GetManga(repository: mangaRepo))
        container.register(GetChaptersByMangaId(repository: chapterRepo))
        container.register(GetCategories(repository: categoryRepo))
        container.register(GetHistory(repository: historyRepo))
        container.register(GetUpdates(repository: updatesRepo))
        container.register(ToggleMangaFavorite(repository: mangaRepo))
        container.register(SyncChaptersWithSource(chapterRepository: chapterRepo))
        container.register(NetworkToLocalManga(mangaRepository: mangaRepo))
        container.register(UpdateChapterProgress(chapterRepository: chapterRepo, historyRepository: historyRepo))
        container.register(SetReadStatus(repository: chapterRepo))

        container.markDatabaseReady()
        AppLog.info("Data layer ready", category: "db")
    }
}
