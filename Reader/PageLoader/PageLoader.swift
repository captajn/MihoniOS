import Foundation
import SourceAPI

/// Resolved image source for one reader page.
public enum PageImageSource: Sendable, Hashable {
    case file(URL)
    case data(Data)
    case remote(URL)
}

public struct ReaderPageItem: Identifiable, Sendable, Hashable {
    public let index: Int
    public let source: PageImageSource

    public var id: Int { index }

    public init(index: Int, source: PageImageSource) {
        self.index = index
        self.source = source
    }
}

public enum PageLoaderError: Error, LocalizedError, Sendable {
    case emptyChapter
    case notFound(String)
    case unsupportedFormat(String)
    case decodeFailed

    public var errorDescription: String? {
        switch self {
        case .emptyChapter: "No pages found in this chapter"
        case .notFound(let p): "Not found: \(p)"
        case .unsupportedFormat(let e): "Unsupported format: \(e)"
        case .decodeFailed: "Failed to decode image"
        }
    }
}

/// Loads ordered pages for a chapter (mirrors Android PageLoader hierarchy).
public protocol PageLoader: Sendable {
    func loadPages() async throws -> [ReaderPageItem]
    func imageSource(for page: ReaderPageItem) async throws -> PageImageSource
}

public extension PageLoader {
    func imageSource(for page: ReaderPageItem) async throws -> PageImageSource {
        page.source
    }
}

public enum PageLoaderFactory: Sendable {
    /// Create a loader for a filesystem path (directory or archive).
    public static func make(path: URL) -> any PageLoader {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path.path, isDirectory: &isDir)
        if exists, isDir.boolValue {
            return DirectoryPageLoader(directory: path)
        }
        let ext = path.pathExtension.lowercased()
        if ["cbz", "zip"].contains(ext) {
            return ArchivePageLoader(archiveURL: path)
        }
        // Single image file as 1-page chapter
        if ImageFileTypes.isImage(path) {
            return SingleImagePageLoader(url: path)
        }
        return DirectoryPageLoader(directory: path)
    }

    /// Build loader from LocalSource chapter relative path + root.
    public static func makeLocal(root: URL, chapterURL: String) -> any PageLoader {
        let path = root.appendingPathComponent(chapterURL)
        return make(path: path)
    }
}

public enum ImageFileTypes {
    public static let extensions: Set<String> = [
        "jpg", "jpeg", "png", "webp", "gif", "avif", "heic", "bmp",
    ]

    public static func isImage(_ url: URL) -> Bool {
        extensions.contains(url.pathExtension.lowercased())
    }

    public static func sortedImageURLs(in directory: URL) throws -> [URL] {
        let fm = FileManager.default
        let items = try fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        return items
            .filter { isImage($0) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }
}
