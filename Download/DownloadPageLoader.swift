import Foundation
import Reader

/// Loads pages from completed download directory.
public struct DownloadPageLoader: PageLoader, Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func loadPages() async throws -> [ReaderPageItem] {
        // If directory contains a single archive, use ArchivePageLoader
        let fm = FileManager.default
        let items = (try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
        if let archive = items.first(where: {
            let e = $0.pathExtension.lowercased()
            return e == "cbz" || e == "zip"
        }), items.count == 1 {
            return try await ArchivePageLoader(archiveURL: archive).loadPages()
        }
        return try await DirectoryPageLoader(directory: directory).loadPages()
    }
}
