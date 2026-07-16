import Foundation

public struct GetLibraryManga {
    private let repository: MangaRepository

    public init(repository: MangaRepository) {
        self.repository = repository
    }

    public func await() async throws -> [LibraryManga] {
        try await repository.getLibraryManga()
    }
}

public struct GetFavorites {
    private let repository: MangaRepository

    public init(repository: MangaRepository) {
        self.repository = repository
    }

    public func await() async throws -> [Manga] {
        try await repository.getFavorites()
    }
}

public struct GetManga {
    private let repository: MangaRepository

    public init(repository: MangaRepository) {
        self.repository = repository
    }

    public func await(id: Int64) async throws -> Manga? {
        try await repository.getManga(id: id)
    }

    public func await(url: String, sourceId: Int64) async throws -> Manga? {
        try await repository.getManga(url: url, sourceId: sourceId)
    }
}

public struct SetMangaCategories {
    private let repository: CategoryRepository

    public init(repository: CategoryRepository) {
        self.repository = repository
    }

    public func await(mangaId: Int64, categoryIds: [Int64]) async throws {
        try await repository.setMangaCategories(mangaId: mangaId, categoryIds: categoryIds)
    }
}

public struct ToggleMangaFavorite {
    private let repository: MangaRepository

    public init(repository: MangaRepository) {
        self.repository = repository
    }

    public func await(manga: Manga, favorite: Bool) async throws {
        var updated = manga
        updated.favorite = favorite
        if favorite && updated.dateAdded == 0 {
            updated.dateAdded = Int64(Date().timeIntervalSince1970 * 1000)
        }
        try await repository.update(updated)
    }
}
