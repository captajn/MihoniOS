import Foundation

public struct DirectoryPageLoader: PageLoader, Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public func loadPages() async throws -> [ReaderPageItem] {
        let urls = try ImageFileTypes.sortedImageURLs(in: directory)
        guard !urls.isEmpty else { throw PageLoaderError.emptyChapter }
        return urls.enumerated().map { index, url in
            ReaderPageItem(index: index, source: .file(url))
        }
    }
}

public struct SingleImagePageLoader: PageLoader, Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func loadPages() async throws -> [ReaderPageItem] {
        [ReaderPageItem(index: 0, source: .file(url))]
    }
}
