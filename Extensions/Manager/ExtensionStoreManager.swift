import Foundation
import CryptoKit
import Core
import SourceAPI

public struct ExtensionStoreEntry: Identifiable, Codable, Sendable, Hashable {
    public var id: String { indexUrl }
    public var indexUrl: String
    public var name: String
    public var signingKey: String

    public init(indexUrl: String, name: String, signingKey: String = "") {
        self.indexUrl = indexUrl
        self.name = name
        self.signingKey = signingKey
    }
}

public struct RemoteExtensionInfo: Identifiable, Codable, Sendable, Hashable {
    public var id: Int64
    public var pkg: String
    public var name: String
    public var lang: String
    public var version: String
    public var nsfw: Bool
    public var downloadURL: String?

    public init(
        id: Int64,
        pkg: String,
        name: String,
        lang: String,
        version: String,
        nsfw: Bool = false,
        downloadURL: String? = nil
    ) {
        self.id = id
        self.pkg = pkg
        self.name = name
        self.lang = lang
        self.version = version
        self.nsfw = nsfw
        self.downloadURL = downloadURL
    }
}

public struct InstalledExtension: Identifiable, Sendable, Hashable {
    public var id: Int64
    public var name: String
    public var lang: String
    public var version: String
    public var packagePath: String
}

/// Manages extension stores + install folders under Application Support/extensions.
public final class ExtensionStoreManager: @unchecked Sendable {
    public static let shared = ExtensionStoreManager()

    private let lock = NSLock()
    private var stores: [ExtensionStoreEntry] = []
    private let defaultsKey = "mihon.extension.stores"

    public var extensionsRoot: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let url = support.appendingPathComponent("mihon/extensions", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public init() {
        loadStores()
        // NOTE: Keiyoushi's index lists real Android APK extensions, which cannot run on
        // iOS (JSExtensionSource only executes the app's own JS package format). Do NOT
        // add it as a default store — every entry from it would be a fake "Install" button
        // that does nothing. Real content sources on iOS: LocalSource, Enhanced sources
        // (Komga/Kavita/Suwayomi), and hand-authored JS packages added as custom stores.
    }

    // MARK: Stores

    public func getStores() -> [ExtensionStoreEntry] {
        lock.lock(); defer { lock.unlock() }
        return stores
    }

    public func addStore(_ store: ExtensionStoreEntry) {
        lock.lock()
        if !stores.contains(where: { $0.indexUrl == store.indexUrl }) {
            stores.append(store)
            persistStores()
        }
        lock.unlock()
    }

    public func removeStore(indexUrl: String) {
        lock.lock()
        stores.removeAll { $0.indexUrl == indexUrl }
        persistStores()
        lock.unlock()
    }

    private func loadStores() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([ExtensionStoreEntry].self, from: data) {
            stores = decoded
        }
        // Migrate away from the previously auto-added Keiyoushi store (APK-only, unusable on iOS).
        let before = stores.count
        stores.removeAll { $0.indexUrl.contains("keiyoushi/extensions") }
        if stores.count != before {
            persistStores()
        }
    }

    private func persistStores() {
        if let data = try? JSONEncoder().encode(stores) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    // MARK: Install / load

    public func installedExtensions() -> [InstalledExtension] {
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(
            at: extensionsRoot,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return dirs.compactMap { dir -> InstalledExtension? in
            let manifestURL = dir.appendingPathComponent("extension.json")
            guard let data = try? Data(contentsOf: manifestURL),
                  let m = try? JSONDecoder().decode(ExtensionManifest.self, from: data) else { return nil }
            return InstalledExtension(
                id: m.id,
                name: m.name,
                lang: m.lang,
                version: m.version,
                packagePath: dir.path
            )
        }
    }

    public func loadAll(into manager: DefaultSourceManager) {
        for ext in installedExtensions() {
            let url = URL(fileURLWithPath: ext.packagePath)
            do {
                let source = try JSExtensionSource(packageURL: url)
                manager.register(source)
            } catch {
                AppLog.error("Failed to load extension \(ext.name)", error: error, category: "ext")
            }
        }
    }

    /// Install from a local folder (already unzipped package). Verifies `sha256` in the
    /// manifest against the script file when the store provided one (trust check for §4-D).
    public func installLocalPackage(from sourceDir: URL) throws -> ExtensionManifest {
        let manifestURL = sourceDir.appendingPathComponent("extension.json")
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(ExtensionManifest.self, from: data)

        if let expected = manifest.sha256, !expected.isEmpty {
            let scriptURL = sourceDir.appendingPathComponent(manifest.script)
            let scriptData = try Data(contentsOf: scriptURL)
            let actual = SHA256.hash(data: scriptData).map { String(format: "%02x", $0) }.joined()
            guard actual.caseInsensitiveCompare(expected) == .orderedSame else {
                throw ExtensionError.storeError("SHA-256 mismatch for \(manifest.name) — install aborted")
            }
        }

        let dest = extensionsRoot.appendingPathComponent(manifest.name.safeFileName, isDirectory: true)
        let fm = FileManager.default
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.copyItem(at: sourceDir, to: dest)
        return manifest
    }

    /// Download and install a remote extension entry. Only works for entries whose
    /// `downloadURL` serves the app's own JS package format (a `{ "manifest": ExtensionManifest,
    /// "script": "...js source..." }` JSON document) — NOT Android APKs (e.g. Keiyoushi), which
    /// cannot run on iOS. Callers should hide/disable install for APK-style entries.
    public func installRemote(_ info: RemoteExtensionInfo) async throws -> ExtensionManifest {
        guard let urlString = info.downloadURL, let url = URL(string: urlString) else {
            throw ExtensionError.storeError("Missing download URL for \(info.name)")
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ExtensionError.storeError("HTTP \(http.statusCode) downloading \(info.name)")
        }

        struct RemotePackage: Codable {
            var manifest: ExtensionManifest
            var script: String
        }
        guard let package = try? JSONDecoder().decode(RemotePackage.self, from: data) else {
            throw ExtensionError.storeError(
                "\(info.name) is not an iOS-compatible package (likely an Android APK extension)"
            )
        }

        if let expected = package.manifest.sha256, !expected.isEmpty {
            let actual = SHA256.hash(data: Data(package.script.utf8)).map { String(format: "%02x", $0) }.joined()
            guard actual.caseInsensitiveCompare(expected) == .orderedSame else {
                throw ExtensionError.storeError("SHA-256 mismatch for \(package.manifest.name) — install aborted")
            }
        }

        let dest = extensionsRoot.appendingPathComponent(package.manifest.name.safeFileName, isDirectory: true)
        let fm = FileManager.default
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.createDirectory(at: dest, withIntermediateDirectories: true)
        try JSONEncoder().encode(package.manifest).write(to: dest.appendingPathComponent("extension.json"))
        try package.script.write(to: dest.appendingPathComponent(package.manifest.script), atomically: true, encoding: .utf8)
        return package.manifest
    }

    /// Fetch remote index JSON — supports both formats:
    /// 1. `{ "extensions": [RemoteExtensionInfo] }` (custom)
    /// 2. Flat array of Keiyoushi format: `[{ name, pkg, apk, lang, code, version, nsfw, sources }]`
    public func fetchIndex(store: ExtensionStoreEntry) async throws -> [RemoteExtensionInfo] {
        guard let url = URL(string: store.indexUrl) else {
            throw ExtensionError.storeError("Invalid store URL")
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ExtensionError.storeError("HTTP \(http.statusCode)")
        }

        // Try custom format first: { "extensions": [...] }
        struct CustomIndex: Codable {
            var extensions: [RemoteExtensionInfo]
        }
        if let index = try? JSONDecoder().decode(CustomIndex.self, from: data) {
            return index.extensions
        }

        // Try Keiyoushi format: flat array of { name, pkg, apk, lang, code, version, nsfw, sources }
        struct KeiyoushiExt: Codable {
            var name: String
            var pkg: String
            var apk: String
            var lang: String
            var code: Int
            var version: String
            var nsfw: Int?
            var sources: [KeiyoushiSource]?
        }
        struct KeiyoushiSource: Codable {
            var name: String
            var lang: String
            var id: String
            var baseUrl: String
        }

        if let items = try? JSONDecoder().decode([KeiyoushiExt].self, from: data) {
            var result: [RemoteExtensionInfo] = []
            for item in items {
                // Convert source IDs to Int64
                for src in (item.sources ?? []) {
                    let sourceId = Int64(src.id) ?? Int64(abs(src.id.hashValue))
                    result.append(RemoteExtensionInfo(
                        id: sourceId,
                        pkg: item.pkg,
                        name: src.name,
                        lang: src.lang,
                        version: item.version,
                        nsfw: (item.nsfw ?? 0) == 1,
                        downloadURL: "https://github.com/keiyoushi/extensions/raw/refs/heads/repo/apk/\(item.apk)"
                    ))
                }
            }
            return result
        }

        // Fallback: bare array of RemoteExtensionInfo
        return try JSONDecoder().decode([RemoteExtensionInfo].self, from: data)
    }

    /// Download zip is simplified: expects downloadURL pointing to a folder listing is not supported;
    /// for MVP, if downloadURL ends with .json package descriptor with embedded script — skip.
    /// Install the built-in MangaDex source (JSON REST API — no HTML scraping needed, so it
    /// actually works inside the JS sandbox, unlike Keiyoushi APK extensions). Ships in-app so
    /// there is at least one real, working manga source out of the box with no store setup.
    public func installMangaDexExtension() throws {
        let dir = extensionsRoot.appendingPathComponent("MangaDex", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let manifest = ExtensionManifest(
            id: 9_000_002,
            name: "MangaDex",
            lang: "en",
            version: "1.0.0",
            script: "index.js",
            supportsLatest: true
        )
        try JSONEncoder().encode(manifest).write(to: dir.appendingPathComponent("extension.json"))
        try Self.mangaDexScript.write(to: dir.appendingPathComponent("index.js"), atomically: true, encoding: .utf8)
    }

    private static let mangaDexScript = """
    var API = "https://api.mangadex.org";

    function firstValue(obj) {
      if (!obj) return "";
      var keys = Object.keys(obj);
      if (obj.en) return obj.en;
      return keys.length > 0 ? obj[keys[0]] : "";
    }

    function coverUrl(item) {
      var rel = (item.relationships || []).filter(function (r) { return r.type === "cover_art"; })[0];
      if (!rel || !rel.attributes || !rel.attributes.fileName) return null;
      return "https://uploads.mangadex.org/covers/" + item.id + "/" + rel.attributes.fileName + ".256.jpg";
    }

    function statusCode(s) {
      switch (s) {
        case "ongoing": return 1;
        case "completed": return 2;
        case "hiatus": return 4;
        case "cancelled": return 5;
        default: return 0;
      }
    }

    function mapManga(item) {
      var attrs = item.attributes || {};
      var tags = (attrs.tags || []).map(function (t) {
        return firstValue(t.attributes && t.attributes.name);
      }).filter(Boolean).join(", ");
      return {
        url: item.id,
        title: firstValue(attrs.title) || "Untitled",
        description: firstValue(attrs.description),
        genre: tags,
        status: statusCode(attrs.status),
        thumbnailUrl: coverUrl(item),
        initialized: false
      };
    }

    function fetchJSON(url) {
      var res = fetch(url);
      if (res.error) throw new Error(res.error);
      if (res.status < 200 || res.status >= 300) throw new Error("HTTP " + res.status);
      return JSON.parse(res.body);
    }

    function listMangas(order, page) {
      var limit = 20;
      var offset = (page - 1) * limit;
      var url = API + "/manga?limit=" + limit + "&offset=" + offset + "&order[" + order + "]=desc"
        + "&availableTranslatedLanguage[]=en&contentRating[]=safe&contentRating[]=suggestive&includes[]=cover_art";
      var data = fetchJSON(url);
      return {
        mangas: (data.data || []).map(mapManga),
        hasNextPage: offset + limit < (data.total || 0)
      };
    }

    function getPopularManga(page) { return listMangas("followedCount", page); }
    function getLatestUpdates(page) { return listMangas("latestUploadedChapter", page); }

    function getSearchManga(page, query) {
      var limit = 20;
      var offset = (page - 1) * limit;
      var url = API + "/manga?limit=" + limit + "&offset=" + offset
        + "&title=" + encodeURIComponent(query || "")
        + "&includes[]=cover_art";
      var data = fetchJSON(url);
      return {
        mangas: (data.data || []).map(mapManga),
        hasNextPage: offset + limit < (data.total || 0)
      };
    }

    function getMangaUpdate(manga, fetchDetails, fetchChapters) {
      var id = manga.url;
      var updated = manga;

      if (fetchDetails) {
        var detail = fetchJSON(API + "/manga/" + id + "?includes[]=cover_art");
        var item = detail.data;
        var mapped = mapManga(item);
        updated = {
          url: manga.url,
          title: mapped.title,
          description: mapped.description,
          genre: mapped.genre,
          status: mapped.status,
          thumbnailUrl: mapped.thumbnailUrl || manga.thumbnailUrl,
          initialized: true
        };
      }

      var chapters = [];
      if (fetchChapters) {
        var offset = 0;
        var limit = 100;
        var guard_ = 0;
        while (guard_ < 10) {
          var feedUrl = API + "/manga/" + id + "/feed?translatedLanguage[]=en&order[chapter]=desc"
            + "&limit=" + limit + "&offset=" + offset;
          var feed = fetchJSON(feedUrl);
          var rows = feed.data || [];
          for (var i = 0; i < rows.length; i++) {
            var attrs = rows[i].attributes || {};
            var group = (rows[i].relationships || []).filter(function (r) { return r.type === "scanlation_group"; })[0];
            var num = parseFloat(attrs.chapter);
            chapters.push({
              url: rows[i].id,
              name: "Chapter " + (attrs.chapter || "?") + (attrs.title ? " - " + attrs.title : ""),
              dateUpload: attrs.publishAt ? Date.parse(attrs.publishAt) : 0,
              chapterNumber: isNaN(num) ? -1 : num,
              scanlator: group && group.attributes ? group.attributes.name : null
            });
          }
          offset += limit;
          guard_ += 1;
          if (rows.length < limit || offset >= (feed.total || 0)) break;
        }
      }

      return { manga: updated, chapters: chapters };
    }

    function getPageList(chapter) {
      var data = fetchJSON(API + "/at-home/server/" + chapter.url);
      var base = data.baseUrl;
      var hash = data.chapter.hash;
      var files = data.chapter.data || [];
      return files.map(function (f, i) {
        var url = base + "/data/" + hash + "/" + f;
        return { index: i, url: url, imageUrl: url };
      });
    }
    """

    /// Install sample built-in demo extension for testing.
    public func installDemoExtension() throws {
        let dir = extensionsRoot.appendingPathComponent("DemoSource", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let manifest = ExtensionManifest(
            id: 9_000_001,
            name: "Demo Source",
            lang: "en",
            version: "1.0.0",
            script: "index.js",
            supportsLatest: true
        )
        let manifestData = try JSONEncoder().encode(manifest)
        try manifestData.write(to: dir.appendingPathComponent("extension.json"))

        let script = """
        function getPopularManga(page) {
          return {
            mangas: [
              { url: "/demo-1", title: "Demo Manga One", status: 1, thumbnailUrl: null, initialized: false },
              { url: "/demo-2", title: "Demo Manga Two", status: 1, thumbnailUrl: null, initialized: false }
            ],
            hasNextPage: false
          };
        }
        function getLatestUpdates(page) { return getPopularManga(page); }
        function getSearchManga(page, query) {
          var all = getPopularManga(page).mangas;
          var q = (query || "").toLowerCase();
          return {
            mangas: all.filter(function(m) { return m.title.toLowerCase().indexOf(q) >= 0; }),
            hasNextPage: false
          };
        }
        function getMangaUpdate(manga, fetchDetails, fetchChapters) {
          var chapters = [];
          if (fetchChapters) {
            chapters = [
              { url: manga.url + "/ch1", name: "Chapter 1", dateUpload: 0, chapterNumber: 1 },
              { url: manga.url + "/ch2", name: "Chapter 2", dateUpload: 0, chapterNumber: 2 }
            ];
          }
          manga.initialized = true;
          manga.description = "Installed demo JS extension (no real content).";
          return { manga: manga, chapters: chapters };
        }
        function getPageList(chapter) {
          // No real images — empty list (reader shows empty chapter)
          return [];
        }
        """
        try script.write(to: dir.appendingPathComponent("index.js"), atomically: true, encoding: .utf8)
    }
}

private extension String {
    var safeFileName: String {
        replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }
}
