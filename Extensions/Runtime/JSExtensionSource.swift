import Foundation
import JavaScriptCore
import SourceAPI
import Core

/// Host for a sandboxed JS extension implementing the Source contract.
/// Extension package: folder with `index.js` + `extension.json`.
public final class JSExtensionSource: CatalogueSource, @unchecked Sendable {
    public let id: Int64
    public let name: String
    public let lang: String
    public let supportsLatest: Bool

    private let context: JSContext
    private let packageURL: URL
    private let session: URLSession

    public init(packageURL: URL, session: URLSession = .shared) throws {
        self.packageURL = packageURL
        self.session = session
        self.context = JSContext()!

        let manifestURL = packageURL.appendingPathComponent("extension.json")
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(ExtensionManifest.self, from: manifestData)
        self.id = manifest.id
        self.name = manifest.name
        self.lang = manifest.lang
        self.supportsLatest = manifest.supportsLatest

        configureContext()
        let scriptURL = packageURL.appendingPathComponent(manifest.script)
        let script = try String(contentsOf: scriptURL, encoding: .utf8)
        context.evaluateScript(script)
        if let exception = context.exception {
            throw ExtensionError.scriptError(exception.toString() ?? "Unknown JS error")
        }
        AppLog.info("Loaded JS extension \(name) (\(id))", category: "ext")
    }

    public func getFilterList() -> FilterList { FilterList() }

    public func getPopularManga(page: Int) async throws -> MangasPage {
        try await callPage("getPopularManga", args: [page])
    }

    public func getLatestUpdates(page: Int) async throws -> MangasPage {
        try await callPage("getLatestUpdates", args: [page])
    }

    public func getSearchManga(page: Int, query: String, filters: FilterList) async throws -> MangasPage {
        try await callPage("getSearchManga", args: [page, query])
    }

    public func getMangaUpdate(
        manga: SManga,
        chapters: [SChapter],
        fetchDetails: Bool,
        fetchChapters: Bool
    ) async throws -> SMangaUpdate {
        let mangaJSON = try jsonObject(from: manga)
        let result = try await callJS("getMangaUpdate", args: [mangaJSON, fetchDetails, fetchChapters])
        guard let dict = result as? [String: Any] else {
            throw ExtensionError.invalidResult
        }
        let updated = try parseSManga(dict["manga"] as? [String: Any] ?? mangaJSON)
        var chapterList: [SChapter]?
        if let rawChapters = dict["chapters"] as? [[String: Any]] {
            chapterList = try rawChapters.map { try parseSChapter($0) }
        }
        return SMangaUpdate(manga: updated, chapters: chapterList)
    }

    public func getPageList(chapter: SChapter) async throws -> [Page] {
        let chJSON = try jsonObject(from: chapter)
        let result = try await callJS("getPageList", args: [chJSON])
        guard let list = result as? [[String: Any]] else {
            throw ExtensionError.invalidResult
        }
        return list.enumerated().map { index, item in
            Page(
                index: (item["index"] as? Int) ?? index,
                url: item["url"] as? String ?? "",
                imageUrl: item["imageUrl"] as? String,
                status: .queue
            )
        }
    }

    // MARK: - JS bridge

    private func configureContext() {
        context.exceptionHandler = { _, exception in
            AppLog.error("JS exception: \(exception?.toString() ?? "?")", category: "ext")
        }

        // fetch(url, headers?) -> Promise-like via block (sync wrapper uses semaphore in async path)
        let fetchBlock: @convention(block) (String, JSValue?) -> JSValue = { [weak self] urlString, headersVal in
            guard let self else {
                return JSValue(undefinedIn: JSContext.current())
            }
            let context = self.context
            let semaphore = DispatchSemaphore(value: 0)
            var body = ""
            var status = 0
            var err: String?

            Task {
                defer { semaphore.signal() }
                do {
                    guard let url = URL(string: urlString) else {
                        err = "bad url"
                        return
                    }
                    var req = URLRequest(url: url)
                    if let headers = headersVal?.toDictionary() as? [String: String] {
                        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
                    }
                    let (data, response) = try await self.session.data(for: req)
                    status = (response as? HTTPURLResponse)?.statusCode ?? 0
                    body = String(data: data, encoding: .utf8) ?? ""
                } catch {
                    err = error.localizedDescription
                }
            }
            _ = semaphore.wait(timeout: .now() + 30)

            let result = JSValue(newObjectIn: context)!
            result.setValue(status, forProperty: "status")
            result.setValue(body, forProperty: "body")
            result.setValue(err, forProperty: "error")
            return result
        }
        context.setObject(fetchBlock, forKeyedSubscript: "mihonFetch" as NSString)

        // Helper helpers
        context.evaluateScript("""
        var console = {
          log: function() {},
          error: function() {},
          warn: function() {}
        };
        function fetch(url, headers) {
          return mihonFetch(String(url), headers || null);
        }
        """)
    }

    private func callPage(_ name: String, args: [Any]) async throws -> MangasPage {
        let result = try await callJS(name, args: args)
        guard let dict = result as? [String: Any] else { throw ExtensionError.invalidResult }
        let mangasRaw = dict["mangas"] as? [[String: Any]] ?? []
        let mangas = try mangasRaw.map { try parseSManga($0) }
        let hasNext = dict["hasNextPage"] as? Bool ?? false
        return MangasPage(mangas: mangas, hasNextPage: hasNext)
    }

    private func callJS(_ function: String, args: [Any]) async throws -> Any? {
        try await withCheckedThrowingContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    guard let fn = self.context.objectForKeyedSubscript(function), fn.isObject || fn.isUndefined == false else {
                        throw ExtensionError.missingFunction(function)
                    }
                    if fn.isUndefined || fn.isNull {
                        throw ExtensionError.missingFunction(function)
                    }
                    let jsArgs = args.map { self.toJS($0) }
                    let value = fn.call(withArguments: jsArgs)
                    if let exception = self.context.exception {
                        throw ExtensionError.scriptError(exception.toString() ?? "JS error")
                    }
                    cont.resume(returning: value?.toObject())
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    private func toJS(_ value: Any) -> Any {
        if let dict = value as? [String: Any] { return dict }
        if let arr = value as? [Any] { return arr }
        return value
    }

    private func jsonObject(from manga: SManga) throws -> [String: Any] {
        [
            "url": manga.url,
            "title": manga.title,
            "artist": manga.artist as Any,
            "author": manga.author as Any,
            "description": manga.description as Any,
            "genre": manga.genre as Any,
            "status": manga.status,
            "thumbnailUrl": manga.thumbnailUrl as Any,
            "initialized": manga.initialized,
        ]
    }

    private func jsonObject(from chapter: SChapter) throws -> [String: Any] {
        [
            "url": chapter.url,
            "name": chapter.name,
            "dateUpload": chapter.dateUpload,
            "chapterNumber": chapter.chapterNumber,
            "scanlator": chapter.scanlator as Any,
        ]
    }

    private func parseSManga(_ dict: [String: Any]) throws -> SManga {
        SManga(
            url: dict["url"] as? String ?? "",
            title: dict["title"] as? String ?? "",
            artist: dict["artist"] as? String,
            author: dict["author"] as? String,
            description: dict["description"] as? String,
            genre: dict["genre"] as? String,
            status: dict["status"] as? Int ?? 0,
            thumbnailUrl: dict["thumbnailUrl"] as? String,
            initialized: dict["initialized"] as? Bool ?? false
        )
    }

    private func parseSChapter(_ dict: [String: Any]) throws -> SChapter {
        SChapter(
            url: dict["url"] as? String ?? "",
            name: dict["name"] as? String ?? "",
            dateUpload: (dict["dateUpload"] as? NSNumber)?.int64Value ?? 0,
            chapterNumber: (dict["chapterNumber"] as? NSNumber)?.doubleValue ?? -1,
            scanlator: dict["scanlator"] as? String
        )
    }
}

public struct ExtensionManifest: Codable, Sendable {
    public var id: Int64
    public var name: String
    public var lang: String
    public var version: String
    public var script: String
    public var supportsLatest: Bool
    public var nsfw: Bool?

    public init(
        id: Int64,
        name: String,
        lang: String,
        version: String = "1.0.0",
        script: String = "index.js",
        supportsLatest: Bool = true,
        nsfw: Bool? = false
    ) {
        self.id = id
        self.name = name
        self.lang = lang
        self.version = version
        self.script = script
        self.supportsLatest = supportsLatest
        self.nsfw = nsfw
    }
}

public enum ExtensionError: Error, LocalizedError {
    case scriptError(String)
    case missingFunction(String)
    case invalidResult
    case notInstalled
    case storeError(String)

    public var errorDescription: String? {
        switch self {
        case .scriptError(let s): s
        case .missingFunction(let f): "Missing JS function: \(f)"
        case .invalidResult: "Invalid extension result"
        case .notInstalled: "Extension not installed"
        case .storeError(let s): s
        }
    }
}
