import SwiftUI
import Core
import Data
import DesignSystem
import SourceAPI
import Extensions
import Download

@main
struct MihonApp: App {
    @StateObject private var appState = AppState()

    init() {
        bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .mihonTheme()
        }
    }

    private func bootstrap() {
        AppLog.info("Mihon iOS starting", category: "app")
        do {
            try DataBootstrap.start(container: .shared)
        } catch {
            AppLog.error("Database bootstrap failed", error: error, category: "db")
        }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let localRoot = docs?.appendingPathComponent("local", isDirectory: true)
        if let localRoot {
            try? FileManager.default.createDirectory(at: localRoot, withIntermediateDirectories: true)
        }

        let sourceManager = DefaultSourceManager(localRoot: localRoot)
        ExtensionStoreManager.shared.loadAll(into: sourceManager)
        AppContainer.shared.register(sourceManager as SourceManager)
        AppContainer.shared.register(sourceManager)

        Task {
            await DownloadManager.shared.setSourceManager(sourceManager)
        }

        AppLog.info("Bootstrap complete", category: "app")
    }
}
