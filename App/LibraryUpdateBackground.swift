import Foundation
import BackgroundTasks
import UserNotifications
import Core
import Domain
import SourceAPI

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

    private func sendNotification(newChapters: Int) async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Mihon"
        content.body = "\(newChapters) new chapters available"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "library-update-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }
}

private struct LibraryUpdateResult {
    let newChapters: Int
}
