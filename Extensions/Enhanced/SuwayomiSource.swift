import Foundation
import SourceAPI
import Core

/// A manga source backed by a self-hosted Suwayomi-Server instance (REST API).
/// Suwayomi itself runs on the JVM (desktop/NAS/VPS) and executes real Tachiyomi/Keiyoushi
/// extensions there — iOS just talks HTTP to it, which sidesteps the "APK can't run on iOS"
/// wall entirely. One `SuwayomiSource` wraps exactly one upstream source already installed
/// on that server (picked via `SuwayomiConnectScreen`).
public final class SuwayomiSource: CatalogueSource, HttpSource, @unchecked Sendable {
    public let id: Int64
    public let name: String
    public let lang: String
    public let supportsLatest: Bool
    public var baseUrl: String { serverURL }

    private let serverURL: String
    private let upstreamSourceId: String
    private let session: URLSession

    public init(serverURL: String, upstreamSourceId: String, name: String, lang: String, supportsLatest: Bool, session: URLSession = .shared) {
        self.serverURL = serverURL.hasSuffix("/") ? String(serverURL.dropLast()) : serverURL
        self.upstreamSourceId = upstreamSourceId
        self.name = name
        self.lang = lang
        self.supportsLatest = supportsLatest
        self.session = session
        // Stable synthetic id: hash of server URL + upstream source id, kept positive.
        self.id = Int64(bitPattern: UInt64(abs((serverURL + ":" + upstreamSourceId).hashValue))) & 0x7FFF_FFFF_FFFF_FFFF
    }

    public func getFilterList() -> FilterList { FilterList() }

    public func getPopularManga(page: Int) async throws -> MangasPage {
        try await fetchMangaList(path: "/api/v1/source/\(upstreamSourceId)/popular/\(page)")
    }

    public func getLatestUpdates(page: Int) async throws -> MangasPage {
        try await fetchMangaList(path: "/api/v1/source/\(upstreamSourceId)/latest/\(page)")
    }

    public func getSearchManga(page: Int, query: String, filters: FilterList) async throws -> MangasPage {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return try await fetchMangaList(path: "/api/v1/source/\(upstreamSourceId)/search?searchTerm=\(q)&pageNum=\(page)")
    }

    public func getMangaUpdate(
        manga: SManga,
        chapters: [SChapter],
        fetchDetails: Bool,
        fetchChapters: Bool
    ) async throws -> SMangaUpdate {
        // manga.url stores the Suwayomi-internal numeric manga id.
        var updated = manga
        if fetchDetails {
            let data = try await get("/api/v1/manga/\(manga.url)?onlineFetch=true")
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            updated = mapManga(dict, existingUrl: manga.url)
        }
        var chapterList: [SChapter]?
        if fetchChapters {
            let data = try await get("/api/v1/manga/\(manga.url)/chapters?onlineFetch=true")
            let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
            chapterList = arr.map(mapChapter)
        }
        return SMangaUpdate(manga: updated, chapters: chapterList)
    }

    public func getPageList(chapter: SChapter) async throws -> [Page] {
        // chapter.url stores "<mangaId>/<chapterIndex>" packed by mapChapter().
        let parts = chapter.url.split(separator: "/")
        guard parts.count == 2 else {
            throw ExtensionError.storeError("Malformed Suwayomi chapter reference: \(chapter.url)")
        }
        return try await resolvePages(mangaId: String(parts[0]), chapterIndex: String(parts[1]))
    }

    private func resolvePages(mangaId: String, chapterIndex: String) async throws -> [Page] {
        let data = try await get("/api/v1/manga/\(mangaId)/chapter/\(chapterIndex)")
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let pageCount = (dict["pageCount"] as? Int) ?? 0
        return (0..<max(pageCount, 0)).map { index in
            let url = "\(serverURL)/api/v1/manga/\(mangaId)/chapter/\(chapterIndex)/page/\(index)"
            return Page(index: index, url: url, imageUrl: url, status: .queue)
        }
    }

    // MARK: - HTTP

    private func get(_ path: String) async throws -> Data {
        guard let url = URL(string: serverURL + path) else {
            throw ExtensionError.storeError("Invalid Suwayomi URL: \(path)")
        }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ExtensionError.storeError("Suwayomi server HTTP \(http.statusCode) for \(path)")
        }
        return data
    }

    private func fetchMangaList(path: String) async throws -> MangasPage {
        let data = try await get(path)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let mangaArray = dict["mangaList"] as? [[String: Any]] ?? []
        let mangas = mangaArray.map { mapManga($0, existingUrl: nil) }
        let hasNext = dict["hasNextPage"] as? Bool ?? false
        return MangasPage(mangas: mangas, hasNextPage: hasNext)
    }

    private func mapManga(_ dict: [String: Any], existingUrl: String?) -> SManga {
        let mangaId = (dict["id"] as? Int).map(String.init) ?? existingUrl ?? ""
        let thumbPath = dict["thumbnailUrl"] as? String
        let thumbnailUrl = thumbPath.map { _ in serverURL + "/api/v1/manga/\(mangaId)/thumbnail" }
        return SManga(
            url: mangaId,
            title: dict["title"] as? String ?? "Untitled",
            artist: dict["artist"] as? String,
            author: dict["author"] as? String,
            description: dict["description"] as? String,
            genre: (dict["genre"] as? [String])?.joined(separator: ", "),
            status: mapStatus(dict["status"] as? String),
            thumbnailUrl: thumbnailUrl,
            initialized: dict["initialized"] as? Bool ?? false
        )
    }

    private func mapStatus(_ raw: String?) -> Int {
        switch raw?.uppercased() {
        case "ONGOING": SManga.ongoing
        case "COMPLETED": SManga.completed
        case "LICENSED": SManga.licensed
        case "PUBLISHING_FINISHED": SManga.publishingFinished
        case "CANCELLED": SManga.cancelled
        default: SManga.unknown
        }
    }

    private func mapChapter(_ dict: [String: Any]) -> SChapter {
        let mangaId = dict["mangaId"] as? Int ?? 0
        let chapterIndex = dict["index"] as? Int ?? 0
        let uploadMs = (dict["uploadDate"] as? NSNumber)?.int64Value ?? 0
        return SChapter(
            url: "\(mangaId)/\(chapterIndex)",
            name: dict["name"] as? String ?? "Chapter",
            dateUpload: uploadMs,
            chapterNumber: (dict["chapterNumber"] as? NSNumber)?.doubleValue ?? -1,
            scanlator: dict["scanlator"] as? String
        )
    }
}

/// One upstream source as reported by `GET /api/v1/source/list` on a Suwayomi-Server.
public struct SuwayomiUpstreamSource: Identifiable, Codable, Sendable, Hashable {
    public var id: String
    public var name: String
    public var lang: String
    public var supportsLatest: Bool

    public init(id: String, name: String, lang: String, supportsLatest: Bool) {
        self.id = id
        self.name = name
        self.lang = lang
        self.supportsLatest = supportsLatest
    }
}

/// A saved connection: one server + one chosen upstream source, persisted so it can be
/// re-registered as a `SuwayomiSource` on every app launch.
public struct SuwayomiConnection: Identifiable, Codable, Sendable, Hashable {
    public var id: String { serverURL + ":" + upstreamSourceId }
    public var serverURL: String
    public var upstreamSourceId: String
    public var name: String
    public var lang: String
    public var supportsLatest: Bool

    public init(serverURL: String, upstreamSourceId: String, name: String, lang: String, supportsLatest: Bool) {
        self.serverURL = serverURL
        self.upstreamSourceId = upstreamSourceId
        self.name = name
        self.lang = lang
        self.supportsLatest = supportsLatest
    }

    public func makeSource() -> SuwayomiSource {
        SuwayomiSource(serverURL: serverURL, upstreamSourceId: upstreamSourceId, name: name, lang: lang, supportsLatest: supportsLatest)
    }
}

/// Fetches the list of sources currently installed on a Suwayomi-Server, and persists
/// chosen connections across launches.
public final class SuwayomiManager: @unchecked Sendable {
    public static let shared = SuwayomiManager()
    private let defaultsKey = "mihon.suwayomi.connections"

    public func fetchAvailableSources(serverURL: String) async throws -> [SuwayomiUpstreamSource] {
        let trimmed = serverURL.hasSuffix("/") ? String(serverURL.dropLast()) : serverURL
        guard let url = URL(string: trimmed + "/api/v1/source/list") else {
            throw ExtensionError.storeError("Invalid server URL")
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ExtensionError.storeError("Server HTTP \(http.statusCode) — check the URL and that Suwayomi-Server is reachable")
        }
        let raw = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return raw.compactMap { dict in
            guard let id = dict["id"] as? String ?? (dict["id"] as? NSNumber).map({ $0.stringValue }) else { return nil }
            return SuwayomiUpstreamSource(
                id: id,
                name: dict["name"] as? String ?? "Source \(id)",
                lang: dict["lang"] as? String ?? "en",
                supportsLatest: dict["supportsLatest"] as? Bool ?? false
            )
        }
    }

    public func getConnections() -> [SuwayomiConnection] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([SuwayomiConnection].self, from: data)
        else { return [] }
        return decoded
    }

    public func addConnection(_ connection: SuwayomiConnection) {
        var all = getConnections()
        guard !all.contains(where: { $0.id == connection.id }) else { return }
        all.append(connection)
        persist(all)
    }

    public func removeConnection(id: String) {
        persist(getConnections().filter { $0.id != id })
    }

    private func persist(_ connections: [SuwayomiConnection]) {
        if let data = try? JSONEncoder().encode(connections) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
