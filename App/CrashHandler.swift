import Foundation
import UIKit

/// Global crash handler that captures uncaught exceptions and signals
final class CrashHandler {
    static let shared = CrashHandler()

    // Internal so global C callbacks can access
    var crashLog: String?
    var previousExceptionHandler: (@convention(c) (NSException) -> Void)?

    func install() {
        previousExceptionHandler = NSGetUncaughtExceptionHandler()
        NSSetUncaughtExceptionHandler(exceptionHandler)

        let signals: [Int32] = [SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGSEGV, SIGTRAP]
        for sig in signals {
            signal(sig, signalHandler)
        }
    }

    func uninstall() {
        NSSetUncaughtExceptionHandler(previousExceptionHandler)
        let signals: [Int32] = [SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGSEGV, SIGTRAP]
        for sig in signals {
            signal(sig, SIG_DFL)
        }
    }

    func getCrashLog() -> String? {
        return crashLog ?? loadCrashLog()
    }

    func clearCrashLog() {
        crashLog = nil
        try? FileManager.default.removeItem(at: crashLogURL())
    }

    func saveCrashLog(_ message: String) {
        try? message.write(to: crashLogURL(), atomically: true, encoding: .utf8)
    }

    func loadCrashLog() -> String? {
        try? String(contentsOf: crashLogURL(), encoding: .utf8)
    }

    func crashLogURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("crash.log")
    }
}

// MARK: - C function pointers (no capture)

private func exceptionHandler(_ exception: NSException) {
    let message = """
    Uncaught Exception: \(exception.name.rawValue)
    Reason: \(exception.reason ?? "Unknown")
    User Info: \(exception.userInfo)
    Stack Trace:
    \(exception.callStackSymbols.joined(separator: "\n"))
    """
    CrashHandler.shared.crashLog = message
    CrashHandler.shared.saveCrashLog(message)
    CrashHandler.shared.previousExceptionHandler?(exception)
}

private func signalHandler(_ receivedSig: Int32) {
    let message = "Signal \(receivedSig) received\nStack trace unavailable"
    CrashHandler.shared.crashLog = message
    CrashHandler.shared.saveCrashLog(message)
    signal(receivedSig, SIG_DFL)
    raise(receivedSig)
}
