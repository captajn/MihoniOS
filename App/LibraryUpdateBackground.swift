import Foundation
import BackgroundTasks
import UserNotifications
import WidgetKit
import Core
import Domain
import SourceAPI

private let widgetAppGroupID = "group.app.mihon.ios"
private let widgetTitlesKey = "widget.recent.titles"

/// Manages background library update tasks using BGAppRefreshTask and BGProcessingTask
public final class LibraryUpdateBackground {
    public static let shared = LibraryUpdateBackground()

    private let taskIdentifier = "com.mihon.library-update"

    public func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            Task {
                await self.handleTask(task as! BGProcessingTask)
            }
        }
    }

    public func scheduleNextUpdate() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        // Schedule based on user preference
        let interval = AppContainer.shared.libraryPreferences.autoUpdateInterval.get()
        guard interval > 0 else { return }

        let nextDate = Date(timeIntervalSinceNow: TimeInterval(interval * 3600))
        request.earliestBeginDate = nextDate

        try? BGTaskScheduler.shared.submit(request)
    }

    public func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour minimum
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleTask(_ task: BGProcessingTask) async {
        // Schedule next update before starting
        scheduleNextUpdate()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        do {
            let result = await runLibraryUpdate()
            let success = result.newChapters >= 0

            // Send notification if new chapters found
            if result.newChapters > 0 {
                await sendNotification(newChapters: result.newChapters)
            }
            await refreshWidgetData()

            task.setTaskCompleted(success: success)
        } catch {
            task.setTaskCompleted(success: false)
        }
    }

    private func runLibraryUpdate() async -> LibraryUpdateResult {
        guard let mangaRepo = AppContainer.shared.resolve(MangaRepository.self),
              let chapterRepo = AppContainer.shared.resolve(ChapterRepository.self),
              let syncChapters = AppContainer.shared.resolve(SyncChaptersWithSource.self)
        else {
            return LibraryUpdateResult(newChapters: -1)
        }

        let sourceManager: (any SourceManager)? = AppContainer.shared.resolve(SourceManager.self)
            ?? AppContainer.shared.resolve(DefaultSourceManager.self)

        // Create fetch chapters closure
        let fetchChapters: LibraryUpdateService.FetchChapters = { [sourceManager] mangaId, sourceId in
            guard let source = sourceManager?.get(Int64(sourceId) ?? 0) else {
                return []
            }
            let manga = try? await mangaRepo.getManga(id: mangaId)
            guard let manga else { return [] }
            let sManga = SManga(
                url: manga.url,
                title: manga.title,
                initialized: manga.initialized
            )
            let update = try await source.getMangaUpdate(
                manga: sManga,
                chapters: [],
                fetchDetails: true,
                fetchChapters: true
            )
            let chapters = update.chapters ?? []
            return chapters.map { ch in
                SyncChaptersWithSource.IncomingChapter(
                    url: ch.url,
                    name: ch.name,
                    dateUpload: ch.dateUpload,
                    chapterNumber: ch.chapterNumber,
                    scanlator: ch.scanlator
                )
            }
        }

        let service = LibraryUpdateService(
            mangaRepository: mangaRepo,
            chapterRepository: chapterRepo,
            sync: syncChapters,
            fetch: fetchChapters
        )

        let result = await service.updateLibrary()
        return LibraryUpdateResult(newChapters: result.newChapters)
    }

    func refreshWidgetData() async {
        guard let mangaRepo = AppContainer.shared.resolve(MangaRepository.self) else { return }
        let titles = (try? await mangaRepo.getLibraryManga())?
            .sorted { $0.manga.lastUpdate > $1.manga.lastUpdate }
            .prefix(6)
            .map(\.manga.title) ?? []
        UserDefaults(suiteName: widgetAppGroupID)?.set(titles, forKey: widgetTitlesKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func sendNotification(newChapters: Int) async {
        await AppNotifications.post(
            channel: .libraryUpdate,
            title: "Mihon",
            body: "\(newChapters) new chapters available"
        )
    }
}

private struct LibraryUpdateResult {
    let newChapters: Int
}
