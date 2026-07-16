import Foundation

/// Local filesystem source.
/// ID `0` matches Android LocalSource convention.
///
/// Layout under `rootDirectory`:
/// - `Series Name/` with chapter subfolders or `.cbz` files
/// - or a single `.cbz` / folder treated as one title
public struct LocalSource: CatalogueSource, Sendable {
    public static let idValue: Int64 = 0

    public let rootDirectory: URL?

    public init(rootDirectory: URL? = nil) {
        self.rootDirectory = rootDirectory
    }

    public var id: Int64 { Self.idValue }
    public var name: String { "Local source" }
    public var lang: String { "other" }
    public var supportsLatest: Bool { false }

    public func getPopularManga(page: Int) async throws -> MangasPage {
        try await scanLocalManga(page: page)
    }

    public func getLatestUpdates(page: Int) async throws -> MangasPage {
        try await scanLocalManga(page: page)
    }

    public func getSearchManga(page: Int, query: String, filters: FilterList) async throws -> MangasPage {
        let pageResult = try await scanLocalManga(page: page)
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return pageResult }
        let filtered = pageResult.mangas.filter { $0.title.lowercased().contains(q) }
        return MangasPage(mangas: filtered, hasNextPage: false)
    }

    public func getMangaUpdate(
        manga: SManga,
        chapters: [SChapter],
        fetchDetails: Bool,
        fetchChapters: Bool
    ) async throws -> SMangaUpdate {
        var result = manga
        result.initialized = true
        guard fetchChapters, let root = chapterDirectory(for: manga) else {
            return SMangaUpdate(manga: result, chapters: fetchChapters ? [] : nil)
        }
        let chaptersFound = try listChapters(in: root, mangaRelative: manga.url)
        return SMangaUpdate(manga: result, chapters: chaptersFound)
    }

    public func getPageList(chapter: SChapter) async throws -> [Page] {
        guard let root = rootDirectory else { return [] }
        let path = root.appendingPathComponent(chapter.url)
        return try listImagePages(in: path)
    }

    // MARK: - Private

    private func scanLocalManga(page: Int) async throws -> MangasPage {
        guard page == 1 else {
            return MangasPage(mangas: [], hasNextPage: false)
        }
        guard let root = rootDirectory else {
            return MangasPage(mangas: [], hasNextPage: false)
        }
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return MangasPage(mangas: [], hasNextPage: false)
        }

        let mangas: [SManga] = contents.compactMap { url in
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return nil }
            let name = url.lastPathComponent
            if isDir.boolValue || isArchive(url) {
                return SManga(
                    url: name,
                    title: name.deletingPathExtensionIfAny,
                    status: SManga.unknown,
                    initialized: false
                )
            }
            return nil
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

        return MangasPage(mangas: mangas, hasNextPage: false)
    }

    private func chapterDirectory(for manga: SManga) -> URL? {
        guard let root = rootDirectory else { return nil }
        return root.appendingPathComponent(manga.url)
    }

    private func listChapters(in directory: URL, mangaRelative: String) throws -> [SChapter] {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: directory.path, isDirectory: &isDir) else { return [] }

        // Single archive file = one chapter
        if !isDir.boolValue, isArchive(directory) {
            return [
                SChapter(
                    url: mangaRelative,
                    name: directory.deletingPathExtension().lastPathComponent,
                    dateUpload: fileDate(directory),
                    chapterNumber: 1
                ),
            ]
        }

        // Directory of images only = one chapter (the manga folder itself)
        let images = (try? listImagePages(in: directory)) ?? []
        let items = try fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        let chapterItems = items.filter { url in
            var itemIsDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &itemIsDir) else { return false }
            return itemIsDir.boolValue || isArchive(url)
        }

        if chapterItems.isEmpty, !images.isEmpty {
            return [
                SChapter(
                    url: mangaRelative,
                    name: directory.lastPathComponent,
                    dateUpload: fileDate(directory),
                    chapterNumber: 1
                ),
            ]
        }

        return chapterItems
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .enumerated()
            .map { index, url in
                let relative = (mangaRelative as NSString).appendingPathComponent(url.lastPathComponent)
                return SChapter(
                    url: relative,
                    name: url.deletingPathExtension().lastPathComponent,
                    dateUpload: fileDate(url),
                    chapterNumber: Double(index + 1)
                )
            }
    }

    private func listImagePages(in path: URL) throws -> [Page] {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path.path, isDirectory: &isDir) else { return [] }

        if !isDir.boolValue {
            // Archive pages are resolved by ArchivePageLoader in the reader
            return []
        }

        let images = try fm.contentsOfDirectory(
            at: path,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { isImage($0) }
        .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }

        return images.enumerated().map { index, url in
            Page(index: index, url: url.path, imageUrl: url.path, status: .ready)
        }
    }

    private func isArchive(_ url: URL) -> Bool {
        ["cbz", "zip", "cbr", "rar", "epub", "7z"].contains(url.pathExtension.lowercased())
    }

    private func isImage(_ url: URL) -> Bool {
        ["jpg", "jpeg", "png", "webp", "gif", "avif", "heic", "bmp"].contains(url.pathExtension.lowercased())
    }

    private func fileDate(_ url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        let date = values?.contentModificationDate ?? Date()
        return Int64(date.timeIntervalSince1970 * 1000)
    }
}

private extension String {
    var deletingPathExtensionIfAny: String {
        (self as NSString).deletingPathExtension
    }
}
