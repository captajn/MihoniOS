import Foundation

/// Source filter list (subset of Android Filter hierarchy for Phase 1–4).
public struct FilterList: Sendable {
    public var list: [any SourceFilter]

    public init(_ list: [any SourceFilter] = []) {
        self.list = list
    }

    public var isEmpty: Bool { list.isEmpty }
}

public protocol SourceFilter: Sendable {
    var name: String { get }
}

public struct HeaderFilter: SourceFilter {
    public let name: String
    public init(name: String) { self.name = name }
}

public struct SeparatorFilter: SourceFilter {
    public let name: String
    public init(name: String = "") { self.name = name }
}

public struct SelectFilter: SourceFilter {
    public let name: String
    public let options: [String]
    public var state: Int

    public init(name: String, options: [String], state: Int = 0) {
        self.name = name
        self.options = options
        self.state = state
    }
}

public struct TextFilter: SourceFilter {
    public let name: String
    public var state: String

    public init(name: String, state: String = "") {
        self.name = name
        self.state = state
    }
}

public struct CheckBoxFilter: SourceFilter {
    public let name: String
    public var state: Bool

    public init(name: String, state: Bool = false) {
        self.name = name
        self.state = state
    }
}

public struct TriStateFilter: SourceFilter {
    public let name: String
    public var state: Int // 0 ignore, 1 include, 2 exclude

    public init(name: String, state: Int = 0) {
        self.name = name
        self.state = state
    }
}

public struct SortFilter: SourceFilter {
    public let name: String
    public let options: [String]
    public var index: Int
    public var ascending: Bool

    public init(name: String, options: [String], index: Int = 0, ascending: Bool = true) {
        self.name = name
        self.options = options
        self.index = index
        self.ascending = ascending
    }
}
