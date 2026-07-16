import Foundation

/// Typed preference store mirroring Android `PreferenceStore`.
public protocol PreferenceStore: AnyObject, Sendable {
    func getBool(_ key: String, default defaultValue: Bool) -> Preference<Bool>
    func getInt(_ key: String, default defaultValue: Int) -> Preference<Int>
    func getLong(_ key: String, default defaultValue: Int64) -> Preference<Int64>
    func getFloat(_ key: String, default defaultValue: Float) -> Preference<Float>
    func getDouble(_ key: String, default defaultValue: Double) -> Preference<Double>
    func getString(_ key: String, default defaultValue: String) -> Preference<String>
    func getStringSet(_ key: String, default defaultValue: Set<String>) -> Preference<Set<String>>
    func getObject<T: Codable & Sendable>(_ key: String, default defaultValue: T) -> Preference<T>
}

/// Observable single preference key.
public final class Preference<T: Sendable>: @unchecked Sendable {
    public let key: String
    private let getter: () -> T
    private let setter: (T) -> Void
    private let defaultValue: T

    public init(key: String, default defaultValue: T, getter: @escaping () -> T, setter: @escaping (T) -> Void) {
        self.key = key
        self.defaultValue = defaultValue
        self.getter = getter
        self.setter = setter
    }

    public var value: T {
        get { getter() }
        set { setter(newValue) }
    }

    public func get() -> T { getter() }

    public func set(_ newValue: T) { setter(newValue) }

    public func delete() { setter(defaultValue) }

    public var isSet: Bool {
        // Concrete stores override via custom check; default assumes always "set" if non-default.
        true
    }
}

// MARK: - UserDefaults implementation

public final class UserDefaultsPreferenceStore: PreferenceStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func getBool(_ key: String, default defaultValue: Bool) -> Preference<Bool> {
        Preference(
            key: key,
            default: defaultValue,
            getter: { [defaults] in
                if defaults.object(forKey: key) == nil { return defaultValue }
                return defaults.bool(forKey: key)
            },
            setter: { [defaults] in defaults.set($0, forKey: key) }
        )
    }

    public func getInt(_ key: String, default defaultValue: Int) -> Preference<Int> {
        Preference(
            key: key,
            default: defaultValue,
            getter: { [defaults] in
                if defaults.object(forKey: key) == nil { return defaultValue }
                return defaults.integer(forKey: key)
            },
            setter: { [defaults] in defaults.set($0, forKey: key) }
        )
    }

    public func getLong(_ key: String, default defaultValue: Int64) -> Preference<Int64> {
        Preference(
            key: key,
            default: defaultValue,
            getter: { [defaults] in
                if defaults.object(forKey: key) == nil { return defaultValue }
                return Int64(defaults.integer(forKey: key))
            },
            setter: { [defaults] in defaults.set(Int($0), forKey: key) }
        )
    }

    public func getFloat(_ key: String, default defaultValue: Float) -> Preference<Float> {
        Preference(
            key: key,
            default: defaultValue,
            getter: { [defaults] in
                if defaults.object(forKey: key) == nil { return defaultValue }
                return defaults.float(forKey: key)
            },
            setter: { [defaults] in defaults.set($0, forKey: key) }
        )
    }

    public func getDouble(_ key: String, default defaultValue: Double) -> Preference<Double> {
        Preference(
            key: key,
            default: defaultValue,
            getter: { [defaults] in
                if defaults.object(forKey: key) == nil { return defaultValue }
                return defaults.double(forKey: key)
            },
            setter: { [defaults] in defaults.set($0, forKey: key) }
        )
    }

    public func getString(_ key: String, default defaultValue: String) -> Preference<String> {
        Preference(
            key: key,
            default: defaultValue,
            getter: { [defaults] in defaults.string(forKey: key) ?? defaultValue },
            setter: { [defaults] in defaults.set($0, forKey: key) }
        )
    }

    public func getStringSet(_ key: String, default defaultValue: Set<String>) -> Preference<Set<String>> {
        Preference(
            key: key,
            default: defaultValue,
            getter: { [defaults] in
                guard let array = defaults.array(forKey: key) as? [String] else { return defaultValue }
                return Set(array)
            },
            setter: { [defaults] in defaults.set(Array($0), forKey: key) }
        )
    }

    public func getObject<T: Codable & Sendable>(_ key: String, default defaultValue: T) -> Preference<T> {
        let enc = encoder
        let dec = decoder
        return Preference(
            key: key,
            default: defaultValue,
            getter: { [defaults] in
                guard let data = defaults.data(forKey: key) else { return defaultValue }
                return (try? dec.decode(T.self, from: data)) ?? defaultValue
            },
            setter: { [defaults] value in
                if let data = try? enc.encode(value) {
                    defaults.set(data, forKey: key)
                }
            }
        )
    }
}
