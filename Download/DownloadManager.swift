import Foundation
import Core
import Domain
import SourceAPI

public enum DownloadStatus: String, Sendable, Codable {
    case queued
    case downloading
    case downloaded
    case error
    case paused
}

public struct DownloadItem: Identifiable, Sendable, Hashable {
    public var id: String { "\(mangaId)-\(chapterId)" }
    public var mangaId: Int64
    public var chapterId: Int64
    public var mangaTitle: String
    public var chapterName: String
    public var sourceId: Int64
    public var chapterURL: String
    public var status: DownloadStatus
    public var progress: Double
    public var errorMessage: String?
    public var totalPages: Int
    public var downloadedPages: Int

    public init(
        mangaId: Int64,
        chapterId: Int64,
        mangaTitle: String,
        chapterName: String,
        sourceId: Int64,
        chapterURL: String,
        status: DownloadStatus = .queued,
        progress: Double = 0,
        errorMessage: String? = nil,
        totalPages: Int = 0,
        downloadedPages: Int = 0
    ) {
        self.mangaId = mangaId
        self.chapterId = chapterId
        self.mangaTitle = mangaTitle
        self.chapterName = chapterName
        self.sourceId = sourceId
        self.chapterURL = chapterURL
        self.status = status
        self.progress = progress
        self.errorMessage = errorMessage
        self.totalPages = totalPages
        self.downloadedPages = downloadedPages
    }
}

public actor DownloadManager {
    public static let shared = DownloadManager()

    private var queue: [DownloadItem] = []
    private var isRunning = false
    private var sourceManager: (any SourceManager)?
    private var continuations: [UUID: AsyncStream<[DownloadItem]>.Continuation] = [:]

    public func setSourceManager(_ manager: any SourceManager) {
        sourceManager = manager
    }

    public func items() -> [DownloadItem] { queue }

    public func observe() -> AsyncStream<[DownloadItem]> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.yield(queue)
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }

    private func removeContinuation(_ id: UUID) {
        continuations[id] = nil
    }

    private func broadcast() {
        for c in continuations.values {
            c.yield(queue)
        }
    }

    public func enqueue(_ item: DownloadItem) {
        guard !queue.contains(where: { $0.id == item.id && $0.status != .error }) else { return }
        var copy = item
        copy.status = .queued
        queue.append(copy)
        broadcast()
        Task { await processQueue() }
    }

    public func pauseAll() {
        for i in queue.indices where queue[i].status == .downloading || queue[i].status == .queued {
            queue[i].status = .paused
        }
        isRunning = false
        broadcast()
    }

    public func resumeAll() {
        for i in queue.indices where queue[i].status == .paused {
            queue[i].status = .queued
        }
        broadcast()
        Task { await processQueue() }
    }

    public func cancel(id: String) {
        queue.removeAll { $0.id == id }
        broadcast()
    }

    public func clearFinished() {
        queue.removeAll { $0.status == .downloaded || $0.status == .error }
        broadcast()
    }

    public func isChapterDownloaded(mangaId: Int64, chapterId: Int64) -> Bool {
        let dir = chapterDirectory(mangaId: mangaId, chapterId: chapterId)
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
              !files.isEmpty else { return false }
        return true
    }

    /// Auto-download new chapters based on user preferences
    public func autoDownloadNewChapters(mangaId: Int64, chapters: [Chapter], mangaTitle: String, sourceId: Int64) {
        let prefs = AppContainer.shared.downloadPreferences
        guard prefs.downloadNewChapters.get() else { return }

        let onlyUnread = prefs.downloadNewUnreadChaptersOnly.get()

        for chapter in chapters {
            // Skip if already downloaded
            guard !isChapterDownloaded(mangaId: mangaId, chapterId: chapter.id) else { continue }

            // Skip if only unread and chapter is already read
            if onlyUnread && chapter.read { continue }

            // Enqueue download
            let item = DownloadItem(
                mangaId: mangaId,
                chapterId: chapter.id,
                mangaTitle: mangaTitle,
                chapterName: chapter.name,
                sourceId: sourceId,
                chapterURL: chapter.url
            )
            enqueue(item)
        }
    }

    public func chapterDirectory(mangaId: Int64, chapterId: Int64) -> URL {
        downloadsRoot()
            .appendingPathComponent("\(mangaId)", isDirectory: true)
            .appendingPathComponent("\(chapterId)", isDirectory: true)
    }

    public func downloadsRoot() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let root = docs.appendingPathComponent("downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func processQueue() async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        while let index = queue.firstIndex(where: { $0.status == .queued }) {
            queue[index].status = .downloading
            broadcast()
            do {
                try await download(at: index)
                queue[index].status = .downloaded
                queue[index].progress = 1
            } catch {
                queue[index].status = .error
                queue[index].errorMessage = error.localizedDescription
                AppLog.error("Download failed", error: error, category: "download")
            }
            broadcast()
        }
    }

    private func download(at index: Int) async throws {
        let item = queue[index]
        let dest = chapterDirectory(mangaId: item.mangaId, chapterId: item.chapterId)
        try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)

        // Local source: copy from Documents/local
        if item.sourceId == LocalSource.idValue {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let src = docs.appendingPathComponent("local", isDirectory: true)
                .appendingPathComponent(item.chapterURL)
            try copyLocal(from: src, to: dest)
            queue[index].progress = 1
            queue[index].downloadedPages = 1
            queue[index].totalPages = 1
            return
        }

        guard let source = sourceManager?.get(item.sourceId) else {
            throw DownloadError.sourceMissing
        }

        let chapter = SChapter(url: item.chapterURL, name: item.chapterName)
        let pages = try await source.getPageList(chapter: chapter)
        queue[index].totalPages = pages.count
        broadcast()

        for (i, page) in pages.enumerated() {
            let imageURL: URL?
            if let img = page.imageUrl, let u = URL(string: img) {
                imageURL = u
            } else if let u = URL(string: page.url) {
                imageURL = u
            } else {
                imageURL = nil
            }
            guard let imageURL else { continue }

            let (data, _) = try await URLSession.shared.data(from: imageURL)
            let name = String(format: "%03d%@", i + 1, preferredExtension(data: data, url: imageURL))
            try data.write(to: dest.appendingPathComponent(name), options: .atomic)
            queue[index].downloadedPages = i + 1
            queue[index].progress = Double(i + 1) / Double(max(pages.count, 1))
            broadcast()
        }
    }

    private func copyLocal(from src: URL, to dest: URL) throws {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: src.path, isDirectory: &isDir) else {
            throw DownloadError.notFound
        }
        if isDir.boolValue {
            let files = try FileManager.default.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)
            for f in files {
                let target = dest.appendingPathComponent(f.lastPathComponent)
                if FileManager.default.fileExists(atPath: target.path) {
                    try FileManager.default.removeItem(at: target)
                }
                try FileManager.default.copyItem(at: f, to: target)
            }
        } else {
            let target = dest.appendingPathComponent(src.lastPathComponent)
            if FileManager.default.fileExists(atPath: target.path) {
                try FileManager.default.removeItem(at: target)
            }
            try FileManager.default.copyItem(at: src, to: target)
        }
    }

    private func preferredExtension(data: Data, url: URL) -> String {
        let ext = url.pathExtension
        if !ext.isEmpty { return ".\(ext)" }
        if data.starts(with: [0xFF, 0xD8]) { return ".jpg" }
        if data.starts(with: [0x89, 0x50]) { return ".png" }
        if data.count > 12, data[8] == 0x57, data[9] == 0x45 { return ".webp" }
        return ".img"
    }
}

public enum DownloadError: Error, LocalizedError {
    case sourceMissing
    case notFound

    public var errorDescription: String? {
        switch self {
        case .sourceMissing: "Source not available"
        case .notFound: "Chapter files not found"
        }
    }
}
