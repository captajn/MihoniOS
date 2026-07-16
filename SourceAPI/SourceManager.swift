import Foundation

/// Registry of available sources (installed extensions + local + stubs).
public protocol SourceManager: Sendable {
    func get(_ id: Int64) -> (any Source)?
    func getCatalogueSources() -> [any CatalogueSource]
    func isStub(_ id: Int64) -> Bool
}

public final class DefaultSourceManager: SourceManager, @unchecked Sendable {
    private let lock = NSLock()
    private var sources: [Int64: any Source] = [:]

    public init(localRoot: URL? = nil) {
        let local = LocalSource(rootDirectory: localRoot)
        sources[local.id] = local
    }

    public func register(_ source: any Source) {
        lock.lock()
        defer { lock.unlock() }
        sources[source.id] = source
    }

    public func unregister(id: Int64) {
        lock.lock()
        defer { lock.unlock() }
        // Keep local source
        if id == LocalSource.idValue { return }
        sources.removeValue(forKey: id)
    }

    public func get(_ id: Int64) -> (any Source)? {
        lock.lock()
        defer { lock.unlock() }
        return sources[id]
    }

    public func getCatalogueSources() -> [any CatalogueSource] {
        lock.lock()
        defer { lock.unlock() }
        return sources.values.compactMap { $0 as? any CatalogueSource }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func isStub(_ id: Int64) -> Bool {
        get(id) == nil
    }
}
