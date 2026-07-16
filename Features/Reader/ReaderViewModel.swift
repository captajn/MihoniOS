import Foundation
import Combine
import Core
import Domain
import Reader
import SourceAPI
import UIKit

@MainActor
final class ReaderViewModel: ObservableObject {
    @Published var pages: [ReaderPageItem] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var menuVisible = false
    @Published var readingMode: ReadingMode
    @Published var mangaTitle: String
    @Published var chapterName: String
    @Published var showPageNumber: Bool
    @Published var navigationMode: Int = NavigationMode.lShaped.rawValue
    @Published var colorFilter: ReaderColorFilter = .none
    private(set) var request: ReaderOpenRequest
    private var pageCache: [Int: UIImage] = [:]
    private let progress: UpdateChapterProgress?
    private let setRead: SetReadStatus?
    private let chapterRepo: ChapterRepository?
    private var hasMarkedRead = false
    private var sessionStarted = Date()

    init(
        request: ReaderOpenRequest,
        progress: UpdateChapterProgress? = AppContainer.shared.resolve(),
        setRead: SetReadStatus? = AppContainer.shared.resolve(),
        chapterRepo: ChapterRepository? = AppContainer.shared.resolve()
    ) {
        self.request = request
        self.mangaTitle = request.mangaTitle
        self.chapterName = request.chapter.name
        self.readingMode = request.readingMode
        self.progress = progress
        self.setRead = setRead
        self.chapterRepo = chapterRepo
        self.showPageNumber = AppContainer.shared.readerPreferences.showPageNumber.get()
        self.navigationMode = UserDefaults.standard.integer(forKey: "reader_navigation_mode")

        // Resolve DEFAULT to preference
        if readingMode == .default {
            self.readingMode = ReadingMode.fromPreference(
                AppContainer.shared.readerPreferences.defaultReadingMode.get()
            )
            if self.readingMode == .default {
                self.readingMode = .rightToLeft
            }
        }
    }

    var pageCount: Int { pages.count }

    var pageLabel: String {
        guard pageCount > 0 else { return "—" }
        return "\(currentIndex + 1) / \(pageCount)"
    }

    var isPagerMode: Bool { readingMode.isPager }
    var isWebtoonMode: Bool { readingMode.isWebtoon }
    var isRTL: Bool { readingMode == .rightToLeft }
    var isVerticalPager: Bool { readingMode == .vertical }

    func load() async {
        isLoading = true
        errorMessage = nil
        sessionStarted = Date()
        defer { isLoading = false }

        do {
            let loader = try makeLoader()
            var loaded = try await loader.loadPages()
            // For archive loaders pages already have data; for directory resolve is fine
            // If loader is Archive, data is ready. For remote-like, expand.
            if loader is ArchivePageLoader {
                // already eager
            } else if !(loader is DirectoryPageLoader || loader is SingleImagePageLoader) {
                var resolved: [ReaderPageItem] = []
                for page in loaded {
                    let source = try await loader.imageSource(for: page)
                    resolved.append(ReaderPageItem(index: page.index, source: source))
                }
                loaded = resolved
            }

            pages = loaded
            let start = Int(request.chapter.lastPageRead)
            currentIndex = min(max(0, start), max(0, loaded.count - 1))
            await prefetch(around: currentIndex)
            AppLog.info("Reader loaded \(loaded.count) pages for \(chapterName)", category: "reader")
        } catch {
            errorMessage = error.localizedDescription
            AppLog.error("Reader load failed", error: error, category: "reader")
        }
    }

    func toggleMenu() {
        menuVisible.toggle()
    }

    func goToPage(_ index: Int) {
        guard pageCount > 0 else { return }
        currentIndex = min(max(0, index), pageCount - 1)
        Task { await prefetch(around: currentIndex) }
        Task { await persistProgress(markReadIfEnd: true) }
    }

    func nextPage() {
        if isRTL {
            goToPage(currentIndex - 1)
        } else {
            goToPage(currentIndex + 1)
        }
    }

    func previousPage() {
        if isRTL {
            goToPage(currentIndex + 1)
        } else {
            goToPage(currentIndex - 1)
        }
    }

    func image(for index: Int) -> UIImage? {
        if let cached = pageCache[index] { return cached }
        guard pages.indices.contains(index) else { return nil }
        // Sync path for file/data; remote should be prefetched
        switch pages[index].source {
        case .file(let url):
            let img = UIImage(contentsOfFile: url.path)
            pageCache[index] = img
            return img
        case .data(let data):
            let img = ReaderImageLoader.downsample(data: data, maxPixel: maxScreenPixel())
                ?? UIImage(data: data)
            pageCache[index] = img
            return img
        case .remote:
            return pageCache[index]
        }
    }

    func onDisappear() {
        Task { await persistProgress(markReadIfEnd: true) }
    }

    func cycleReadingMode() {
        let modes: [ReadingMode] = [.rightToLeft, .leftToRight, .vertical, .webtoon, .continuousVertical]
        if let idx = modes.firstIndex(of: readingMode) {
            readingMode = modes[(idx + 1) % modes.count]
        } else {
            readingMode = .rightToLeft
        }
    }

    // MARK: - Private

    private func makeLoader() throws -> any PageLoader {
        if let local = request.localPath {
            let loader = PageLoaderFactory.make(path: local)
            // Prefer eager archive extraction
            if local.pathExtension.lowercased() == "cbz" || local.pathExtension.lowercased() == "zip" {
                return ArchivePageLoader(archiveURL: local)
            }
            return loader
        }
        if !request.remotePages.isEmpty {
            let pages = request.remotePages.map {
                Page(index: $0.index, url: $0.url, imageUrl: $0.imageUrl)
            }
            return HttpPageLoader(pages: pages)
        }
        // Fallback: local source root + chapter url
        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let root = docs.appendingPathComponent("local", isDirectory: true)
            return PageLoaderFactory.makeLocal(root: root, chapterURL: request.chapter.url)
        }
        throw PageLoaderError.notFound("No page source")
    }

    private func prefetch(around index: Int) async {
        let range = max(0, index - 1)...min(pageCount - 1, index + 2)
        for i in range {
            if pageCache[i] != nil { continue }
            guard pages.indices.contains(i) else { continue }
            if let img = await ReaderImageLoader.uiImage(from: pages[i].source) {
                // Downsample large bitmaps
                if let data = pages[i].source.sourceData,
                   let down = ReaderImageLoader.downsample(data: data, maxPixel: maxScreenPixel()) {
                    pageCache[i] = down
                } else {
                    pageCache[i] = img
                }
            }
        }
    }

    private func maxScreenPixel() -> CGFloat {
        let scale = UIScreen.main.scale
        let bounds = UIScreen.main.bounds
        return max(bounds.width, bounds.height) * scale * 1.5
    }

    private func persistProgress(markReadIfEnd: Bool) async {
        guard request.chapter.id > 0 else { return }
        let duration = Int64(Date().timeIntervalSince(sessionStarted))
        sessionStarted = Date()

        if var chapter = try? await chapterRepo?.getChapter(id: request.chapter.id) {
            chapter.lastPageRead = Int64(currentIndex)
            let atEnd = pageCount > 0 && currentIndex >= pageCount - 1
            if markReadIfEnd, atEnd, !hasMarkedRead {
                chapter.read = true
                hasMarkedRead = true
            }
            try? await progress?.await(chapter: chapter, lastPageRead: Int64(currentIndex), readDuration: duration)
            if hasMarkedRead {
                try? await setRead?.await(chapters: [chapter], read: true)
            }
        }
    }
}

private extension PageImageSource {
    var sourceData: Data? {
        if case .data(let d) = self { return d }
        return nil
    }
}

/// Color filter for reader pages
public enum ReaderColorFilter: Int, CaseIterable, Sendable {
    case none = 0
    case sepia = 1
    case grayscale = 2
    case invertColors = 3

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .sepia: return "Sepia"
        case .grayscale: return "Grayscale"
        case .invertColors: return "Invert"
        }
    }
}
