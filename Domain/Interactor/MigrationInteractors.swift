import Foundation

/// Migrates a library entry from one source to another, copying flags.
public struct MigrateManga {
    public struct Flags: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let chapters = Flags(rawValue: 1 << 0)
        public static let categories = Flags(rawValue: 1 << 1)
        public static let tracking = Flags(rawValue: 1 << 2)
        public static let customCover = Flags(rawValue: 1 << 3)
        public static let extra = Flags(rawValue: 1 << 4)
        public static let deleteOld = Flags(rawValue: 1 << 5)
        public static let all: Flags = [.chapters, .categories, .tracking, .extra]
    }

    private let mangaRepo: MangaRepository
    private let chapterRepo: ChapterRepository
    private let categoryRepo: CategoryRepository
    private let trackRepo: TrackRepository

    public init(
        mangaRepo: MangaRepository,
        chapterRepo: ChapterRepository,
        categoryRepo: CategoryRepository,
        trackRepo: TrackRepository
    ) {
        self.mangaRepo = mangaRepo
        self.chapterRepo = chapterRepo
        self.categoryRepo = categoryRepo
        self.trackRepo = trackRepo
    }

    public func await(
        oldManga: Manga,
        newManga: Manga,
        flags: Flags = .all
    ) async throws -> Manga {
        var target = newManga
        target.favorite = true
        if target.dateAdded == 0 {
            target.dateAdded = Int64(Date().timeIntervalSince1970 * 1000)
        }
        if flags.contains(.extra) {
            target.viewerFlags = oldManga.viewerFlags
            target.chapterFlags = oldManga.chapterFlags
            target.notes = oldManga.notes
        }

        if target.id <= 0 {
            let id = try await mangaRepo.insert(target)
            target.id = id
        } else {
            try await mangaRepo.update(target)
        }

        if flags.contains(.categories) {
            let cats = try await categoryRepo.getCategories(mangaId: oldManga.id)
            try await categoryRepo.setMangaCategories(mangaId: target.id, categoryIds: cats.map(\.id))
        }

        if flags.contains(.chapters) {
            let oldChapters = try await chapterRepo.getChapters(mangaId: oldManga.id)
            let newChapters = try await chapterRepo.getChapters(mangaId: target.id)
            // Match by chapter number when possible
            var updates: [Chapter] = []
            for nc in newChapters {
                if let match = oldChapters.first(where: {
                    ($0.chapterNumber >= 0 && $0.chapterNumber == nc.chapterNumber)
                        || $0.name == nc.name
                }) {
                    var u = nc
                    u.read = match.read
                    u.bookmark = match.bookmark
                    u.lastPageRead = match.lastPageRead
                    updates.append(u)
                }
            }
            if !updates.isEmpty {
                try await chapterRepo.updateAll(updates)
            }
        }

        if flags.contains(.tracking) {
            let tracks = try await trackRepo.getTracks(mangaId: oldManga.id)
            for t in tracks {
                var nt = t
                nt.id = -1
                nt.mangaId = target.id
                _ = try await trackRepo.insert(nt)
            }
        }

        if flags.contains(.deleteOld), oldManga.id != target.id {
            try await mangaRepo.delete(id: oldManga.id)
        }

        return target
    }
}

/// Naive title search scorer for migration smart search.
public enum SmartSearch {
    public static func score(query: String, candidate: String) -> Double {
        let q = normalize(query)
        let c = normalize(candidate)
        if q == c { return 1 }
        if c.contains(q) || q.contains(c) { return 0.85 }
        let qTokens = Set(q.split(separator: " ").map(String.init))
        let cTokens = Set(c.split(separator: " ").map(String.init))
        guard !qTokens.isEmpty else { return 0 }
        let inter = qTokens.intersection(cTokens).count
        return Double(inter) / Double(qTokens.count)
    }

    public static func normalize(_ s: String) -> String {
        s.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}
