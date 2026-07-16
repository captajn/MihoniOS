import Foundation

/// Simple service locator for Phase 0–1 (can be replaced by swift-dependencies later).
public final class AppContainer: @unchecked Sendable {
    public static let shared = AppContainer()

    public let preferenceStore: PreferenceStore
    public let appPreferences: AppPreferences
    public let libraryPreferences: LibraryPreferences
    public let readerPreferences: ReaderPreferences
    public let downloadPreferences: DownloadPreferences
    public let sourcePreferences: SourcePreferences

    /// Injected after Data layer boots (database, repositories).
    public private(set) var databaseReady: Bool = false

    private var extras: [String: Any] = [:]
    private let lock = NSLock()

    public init(preferenceStore: PreferenceStore = UserDefaultsPreferenceStore()) {
        self.preferenceStore = preferenceStore
        self.appPreferences = AppPreferences(store: preferenceStore)
        self.libraryPreferences = LibraryPreferences(store: preferenceStore)
        self.readerPreferences = ReaderPreferences(store: preferenceStore)
        self.downloadPreferences = DownloadPreferences(store: preferenceStore)
        self.sourcePreferences = SourcePreferences(store: preferenceStore)
    }

    /// Registers a concrete value under its static type (or protocol existential type).
    public func register<T>(_ value: T) {
        lock.lock()
        defer { lock.unlock() }
        extras[key(for: T.self)] = value
    }

    public func resolve<T>(_ type: T.Type = T.self) -> T? {
        lock.lock()
        defer { lock.unlock() }
        return extras[key(for: type)] as? T
    }

    public func require<T>(_ type: T.Type = T.self) -> T {
        guard let value = resolve(type) else {
            fatalError("Dependency not registered: \(type)")
        }
        return value
    }

    public func markDatabaseReady() {
        databaseReady = true
    }

    private func key<T>(for type: T.Type) -> String {
        String(reflecting: type)
    }
}
