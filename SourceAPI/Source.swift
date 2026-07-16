import Foundation

/// Core source contract — mirrors Android `eu.kanade.tachiyomi.source.Source`.
public protocol Source: Sendable {
    var id: Int64 { get }
    var name: String { get }
    var lang: String { get }
    var supportsLatest: Bool { get }

    func getFilterList() -> FilterList

    func getPopularManga(page: Int) async throws -> MangasPage
    func getLatestUpdates(page: Int) async throws -> MangasPage
    func getSearchManga(page: Int, query: String, filters: FilterList) async throws -> MangasPage

    func getMangaUpdate(
        manga: SManga,
        chapters: [SChapter],
        fetchDetails: Bool,
        fetchChapters: Bool
    ) async throws -> SMangaUpdate

    func getPageList(chapter: SChapter) async throws -> [Page]
}

public extension Source {
    var lang: String { "" }
    var supportsLatest: Bool { false }

    func getFilterList() -> FilterList { FilterList() }
}

/// Catalogue source marker (popular / latest / search).
public protocol CatalogueSource: Source {}

/// HTTP-backed catalogue (online extensions / servers).
public protocol HttpSource: CatalogueSource {
    var baseUrl: String { get }
    func headers() -> [String: String]
}

public extension HttpSource {
    func headers() -> [String: String] { [:] }
}

/// Source that can resolve deep links / shared URLs.
public protocol ResolvableSource: Source {
    func getMangaUrl(url: String) async throws -> SManga?
}

/// Optional per-source preferences UI host will render later.
public protocol ConfigurableSource: Source {
    // Preference keys registered under source id namespace.
}

public enum SourceError: Error, LocalizedError, Sendable {
    case notSupported
    case httpError(code: Int)
    case parseError(String)
    case emptyResult
    case underlying(String)

    public var errorDescription: String? {
        switch self {
        case .notSupported: "Operation not supported by this source"
        case .httpError(let code): "HTTP error \(code)"
        case .parseError(let msg): "Parse error: \(msg)"
        case .emptyResult: "No results"
        case .underlying(let msg): msg
        }
    }
}
