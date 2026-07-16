import Foundation

public struct GetHistory {
    private let repository: HistoryRepository

    public init(repository: HistoryRepository) {
        self.repository = repository
    }

    public func await(query: String = "") async throws -> [HistoryWithRelations] {
        try await repository.getHistory(query: query)
    }
}

public struct RemoveHistory {
    private let repository: HistoryRepository

    public init(repository: HistoryRepository) {
        self.repository = repository
    }

    public func await(ids: [Int64]) async throws {
        try await repository.removeHistory(ids: ids)
    }

    public func awaitAll() async throws {
        try await repository.removeAll()
    }
}

public struct GetUpdates {
    private let repository: UpdatesRepository

    public init(repository: UpdatesRepository) {
        self.repository = repository
    }

    /// `after` is epoch millis lower bound for date_fetch.
    public func await(after: Int64 = 0, limit: Int = 500) async throws -> [UpdatesWithRelations] {
        try await repository.awaitUpdates(after: after, limit: limit)
    }
}

public struct GetTotalReadDuration {
    private let repository: HistoryRepository

    public init(repository: HistoryRepository) {
        self.repository = repository
    }

    public func await() async throws -> Int64 {
        try await repository.getTotalReadDuration()
    }
}
