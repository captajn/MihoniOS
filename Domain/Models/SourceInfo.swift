import Foundation

/// Lightweight source descriptor stored in DB / UI (not the full Source protocol).
public struct SourceInfo: Identifiable, Hashable, Sendable, Codable {
    public var id: Int64
    public var lang: String
    public var name: String
    public var supportsLatest: Bool
    public var isStub: Bool
    public var isPin: Bool
    public var isUsedLast: Bool

    public init(
        id: Int64,
        lang: String = "",
        name: String,
        supportsLatest: Bool = false,
        isStub: Bool = false,
        isPin: Bool = false,
        isUsedLast: Bool = false
    ) {
        self.id = id
        self.lang = lang
        self.name = name
        self.supportsLatest = supportsLatest
        self.isStub = isStub
        self.isPin = isPin
        self.isUsedLast = isUsedLast
    }

    /// Local source ID matches Android convention.
    public static let localSourceId: Int64 = 0
}
