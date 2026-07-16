import Foundation

public struct GetCategories {
    private let repository: CategoryRepository

    public init(repository: CategoryRepository) {
        self.repository = repository
    }

    public func await() async throws -> [Category] {
        try await repository.getAll()
    }

    public func await(mangaId: Int64) async throws -> [Category] {
        try await repository.getCategories(mangaId: mangaId)
    }
}

public struct CreateCategoryWithName {
    private let repository: CategoryRepository

    public init(repository: CategoryRepository) {
        self.repository = repository
    }

    public func await(name: String) async throws -> Int64 {
        let existing = try await repository.getAll()
        let nextOrder = (existing.map(\.order).max() ?? -1) + 1
        let category = Category(name: name, order: nextOrder, flags: 0)
        return try await repository.insert(category)
    }
}

public struct RenameCategory {
    private let repository: CategoryRepository

    public init(repository: CategoryRepository) {
        self.repository = repository
    }

    public func await(category: Category, name: String) async throws {
        var updated = category
        updated.name = name
        try await repository.update(updated)
    }
}

public struct DeleteCategory {
    private let repository: CategoryRepository

    public init(repository: CategoryRepository) {
        self.repository = repository
    }

    public func await(id: Int64) async throws {
        guard id > 0 else { return } // protect system category
        try await repository.delete(id: id)
    }
}
