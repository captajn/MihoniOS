import Foundation

/// Library category. System default has `id == 0`.
public struct Category: Identifiable, Hashable, Sendable, Codable {
    public var id: Int64
    public var name: String
    public var order: Int64
    public var flags: Int64

    public init(id: Int64 = -1, name: String = "", order: Int64 = 0, flags: Int64 = 0) {
        self.id = id
        self.name = name
        self.order = order
        self.flags = flags
    }

    public var isSystemCategory: Bool { id == 0 }

    public static let defaultCategory = Category(id: 0, name: "", order: -1, flags: 0)
}
