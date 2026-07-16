import SwiftUI
import DesignSystem

/// Displays crash log information and allows sharing
struct CrashScreen: View {
    @State private var crashLog: String?
    @State private var showShareSheet = false

    var body: some View {
        List {
            if let crashLog {
                Section(String(localized: "crash_log")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(crashLog)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }

                Section {
                    Button(String(localized: "crash_share_log")) {
                        showShareSheet = true
                    }
                    Button(String(localized: "crash_clear_log"), role: .destructive) {
                        CrashHandler.shared.clearCrashLog()
                        self.crashLog = nil
                    }
                }
            } else {
                Section {
                    EmptyStateView(
                        title: String(localized: "crash_no_log"),
                        message: String(localized: "crash_no_log_description"),
                        systemImage: "checkmark.shield"
                    )
                }
            }
        }
        .navigationTitle(String(localized: "crash_log"))
        .onAppear {
            crashLog = CrashHandler.shared.getCrashLog()
        }
        .sheet(isPresented: $showShareSheet) {
            if let crashLog {
                ShareSheet(items: [crashLog])
            }
        }
    }
}
