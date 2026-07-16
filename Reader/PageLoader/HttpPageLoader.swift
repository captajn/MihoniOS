import Foundation
import SourceAPI

/// Loads pages over HTTP (online sources / downloads later).
public struct HttpPageLoader: PageLoader, Sendable {
    public let pages: [Page]
    public let session: URLSession

    public init(pages: [Page], session: URLSession = .shared) {
        self.pages = pages
        self.session = session
    }

    public func loadPages() async throws -> [ReaderPageItem] {
        guard !pages.isEmpty else { throw PageLoaderError.emptyChapter }
        return pages.enumerated().map { index, page in
            if let image = page.imageUrl, let url = URL(string: image) {
                return ReaderPageItem(index: index, source: .remote(url))
            }
            if let url = URL(string: page.url) {
                return ReaderPageItem(index: index, source: .remote(url))
            }
            return ReaderPageItem(index: index, source: .data(Data()))
        }
    }

    public func imageSource(for page: ReaderPageItem) async throws -> PageImageSource {
        switch page.source {
        case .file, .data:
            return page.source
        case .remote(let url):
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw PageLoaderError.notFound(url.absoluteString)
            }
            return .data(data)
        }
    }
}
