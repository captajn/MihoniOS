import SwiftUI
import DesignSystem

/// Displays crash log information and allows sharing
struct CrashScreen: View {
    @State private var crashLog: String?
    @State private var showShareSheet = false

    var body: some View {
        List {
            if let crashLog {
                Section(String(localized: "crash_screen_title")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(crashLog)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }

                Section {
                    Button(String(localized: "action_share")) {
                        showShareSheet = true
                    }
                    Button(String(localized: "action_delete"), role: .destructive) {
                        CrashHandler.shared.clearCrashLog()
                        self.crashLog = nil
                    }
                }
            } else {
                Section {
                    EmptyStateView(
                        title: String(localized: "crash_screen_title"),
                        message: String(localized: "crash_screen_description"),
                        systemImage: "checkmark.shield"
                    )
                }
            }
        }
        .navigationTitle(String(localized: "crash_screen_title"))
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
