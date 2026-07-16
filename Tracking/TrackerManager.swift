import Foundation
import Domain
import Core

public final class TrackerManager: @unchecked Sendable {
    public static let shared = TrackerManager()

    public let trackers: [any Tracker]

    public init() {
        trackers = [
            MyAnimeListTracker(),
            AniListTracker(),
            KitsuTracker(),
            ShikimoriTracker(),
            BangumiTracker(),
            KomgaTracker(),
            MangaUpdatesTracker(),
            KavitaTracker(),
            SuwayomiTracker(),
            HikkaTracker(),
            MangaBakaTracker(),
        ]
    }

    public func get(_ id: Int64) -> (any Tracker)? {
        trackers.first { $0.id == id }
    }

    public func loggedIn() -> [any Tracker] {
        trackers.filter(\.isLoggedIn)
    }

    public func displayName(_ id: Int64) -> String {
        get(id)?.name ?? TrackerId(rawValue: id)?.displayName ?? "Tracker \(id)"
    }
}

// MARK: - Concrete trackers (credentials + search stubs / API shells)

public final class MyAnimeListTracker: BaseTracker, @unchecked Sendable {
    public init() { super.init(id: TrackerId.myAnimeList.rawValue, name: "MyAnimeList") }

    public override func search(query: String) async throws -> [TrackSearchResult] {
        guard isLoggedIn else { throw TrackerError.notLoggedIn }
        // Public MAL API requires client id — return query-based placeholders for UI wiring
        return [
            TrackSearchResult(
                mediaId: Int64(query.hashValue & 0x7FFF_FFFF),
                title: query,
                totalChapters: 0,
                trackingUrl: "https://myanimelist.net/manga.php?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
            ),
        ]
    }
}

public final class AniListTracker: BaseTracker, @unchecked Sendable {
    public init() { super.init(id: TrackerId.aniList.rawValue, name: "AniList") }

    public override func search(query: String) async throws -> [TrackSearchResult] {
        guard isLoggedIn else { throw TrackerError.notLoggedIn }
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let body: [String: Any] = [
            "query": "query ($search: String) { Page(perPage: 10) { media(search: $search, type: MANGA) { id title { romaji english } chapters siteUrl coverImage { large } } } }",
            "variables": ["search": query],
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else { return [] }
        var req = URLRequest(url: URL(string: "https://graphql.anilist.co")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = UserDefaults.standard.string(forKey: tokenKey), token != "session" {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = data
        do {
            let (respData, _) = try await URLSession.shared.data(for: req)
            guard let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
                  let dataObj = json["data"] as? [String: Any],
                  let page = dataObj["Page"] as? [String: Any],
                  let media = page["media"] as? [[String: Any]] else {
                return [TrackSearchResult(mediaId: 0, title: query, trackingUrl: "https://anilist.co/search/manga?search=\(q)")]
            }
            return media.compactMap { item -> TrackSearchResult? in
                guard let id = item["id"] as? Int else { return nil }
                let titleObj = item["title"] as? [String: Any]
                let title = (titleObj?["english"] as? String)
                    ?? (titleObj?["romaji"] as? String)
                    ?? query
                let cover = (item["coverImage"] as? [String: Any])?["large"] as? String
                return TrackSearchResult(
                    mediaId: Int64(id),
                    title: title,
                    coverUrl: cover,
                    totalChapters: item["chapters"] as? Int ?? 0,
                    trackingUrl: item["siteUrl"] as? String ?? ""
                )
            }
        } catch {
            AppLog.error("AniList search failed", error: error, category: "track")
            throw TrackerError.network(error.localizedDescription)
        }
    }
}

public final class KitsuTracker: BaseTracker, @unchecked Sendable {
    public init() { super.init(id: TrackerId.kitsu.rawValue, name: "Kitsu") }
}

public final class ShikimoriTracker: BaseTracker, @unchecked Sendable {
    public init() { super.init(id: TrackerId.shikimori.rawValue, name: "Shikimori") }
}

public final class BangumiTracker: BaseTracker, @unchecked Sendable {
    public init() { super.init(id: TrackerId.bangumi.rawValue, name: "Bangumi") }
}

public final class KomgaTracker: BaseTracker, @unchecked Sendable {
    public init() { super.init(id: TrackerId.komga.rawValue, name: "Komga") }

    public override func login(username: String, password: String) async throws {
        // username = base URL, password = API key / basic
        setCredentials(username: username, token: password)
    }
}

public final class MangaUpdatesTracker: BaseTracker, @unchecked Sendable {
    public init() { super.init(id: TrackerId.mangaUpdates.rawValue, name: "MangaUpdates") }
}

public final class KavitaTracker: BaseTracker, @unchecked Sendable {
    public init() { super.init(id: TrackerId.kavita.rawValue, name: "Kavita") }

    public override func login(username: String, password: String) async throws {
        setCredentials(username: username, token: password)
    }
}

public final class SuwayomiTracker: BaseTracker, @unchecked Sendable {
    public init() { super.init(id: TrackerId.suwayomi.rawValue, name: "Suwayomi") }

    public override func login(username: String, password: String) async throws {
        setCredentials(username: username, token: password)
    }
}

public final class HikkaTracker: BaseTracker, @unchecked Sendable {
    public init() { super.init(id: TrackerId.hikka.rawValue, name: "Hikka") }
}

public final class MangaBakaTracker: BaseTracker, @unchecked Sendable {
    public init() { super.init(id: TrackerId.mangaBaka.rawValue, name: "MangaBaka") }
}
