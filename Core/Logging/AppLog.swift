import Foundation
import OSLog

/// Lightweight logging facade (replaces Android logcat helpers).
public enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app.mihon"

    public static func debug(_ message: String, category: String = "app") {
        Logger(subsystem: subsystem, category: category).debug("\(message, privacy: .public)")
    }

    public static func info(_ message: String, category: String = "app") {
        Logger(subsystem: subsystem, category: category).info("\(message, privacy: .public)")
    }

    public static func warning(_ message: String, category: String = "app") {
        Logger(subsystem: subsystem, category: category).warning("\(message, privacy: .public)")
    }

    public static func error(_ message: String, error: Error? = nil, category: String = "app") {
        if let error {
            Logger(subsystem: subsystem, category: category)
                .error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            Logger(subsystem: subsystem, category: category).error("\(message, privacy: .public)")
        }
    }
}
