import Foundation
import Domain

public struct TrackSearchResult: Identifiable, Sendable, Hashable {
    public var id: String { "\(mediaId)-\(title)" }
    public var mediaId: Int64
    public var title: String
    public var coverUrl: String?
    public var summary: String?
    public var totalChapters: Int
    public var trackingUrl: String
    public var publishingStatus: String?
    public var score: Double?

    public init(
        mediaId: Int64,
        title: String,
        coverUrl: String? = nil,
        summary: String? = nil,
        totalChapters: Int = 0,
        trackingUrl: String = "",
        publishingStatus: String? = nil,
        score: Double? = nil
    ) {
        self.mediaId = mediaId
        self.title = title
        self.coverUrl = coverUrl
        self.summary = summary
        self.totalChapters = totalChapters
        self.trackingUrl = trackingUrl
        self.publishingStatus = publishingStatus
        self.score = score
    }
}

public protocol Tracker: Sendable {
    var id: Int64 { get }
    var name: String { get }
    var isLoggedIn: Bool { get }
    var supportsReadingDates: Bool { get }

    func login(username: String, password: String) async throws
    func logout()
    func search(query: String) async throws -> [TrackSearchResult]
    func bind(track: Track, result: TrackSearchResult) async throws -> Track
    func update(track: Track, didReadChapter: Bool) async throws -> Track
    func refresh(track: Track) async throws -> Track
}

public extension Tracker {
    var supportsReadingDates: Bool { false }
}

public enum TrackerError: Error, LocalizedError {
    case notLoggedIn
    case notImplemented
    case network(String)
    case auth(String)

    public var errorDescription: String? {
        switch self {
        case .notLoggedIn: "Not logged in"
        case .notImplemented: "Not implemented yet"
        case .network(let s): s
        case .auth(let s): s
        }
    }
}

/// Base tracker with UserDefaults token storage.
open class BaseTracker: Tracker, @unchecked Sendable {
    public let id: Int64
    public let name: String

    public init(id: Int64, name: String) {
        self.id = id
        self.name = name
    }

    public var isLoggedIn: Bool {
        UserDefaults.standard.string(forKey: tokenKey) != nil
            || UserDefaults.standard.string(forKey: usernameKey) != nil
    }

    public var tokenKey: String { "tracker.\(id).token" }
    public var usernameKey: String { "tracker.\(id).username" }

    public func setCredentials(username: String?, token: String?) {
        let d = UserDefaults.standard
        if let username { d.set(username, forKey: usernameKey) } else { d.removeObject(forKey: usernameKey) }
        if let token { d.set(token, forKey: tokenKey) } else { d.removeObject(forKey: tokenKey) }
    }

    public func login(username: String, password: String) async throws {
        // Default: store credentials as "logged in" placeholder (real OAuth in service subclasses)
        setCredentials(username: username, token: password.isEmpty ? "session" : password)
    }

    public func logout() {
        setCredentials(username: nil, token: nil)
    }

    public func search(query: String) async throws -> [TrackSearchResult] {
        throw TrackerError.notImplemented
    }

    public func bind(track: Track, result: TrackSearchResult) async throws -> Track {
        var t = track
        t.mediaId = result.mediaId
        t.title = result.title
        t.totalChapters = result.totalChapters
        t.trackingUrl = result.trackingUrl
        t.syncId = id
        return t
    }

    public func update(track: Track, didReadChapter: Bool) async throws -> Track {
        track
    }

    public func refresh(track: Track) async throws -> Track {
        track
    }
}
