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

        installBuiltInExtensionsIfNeeded()

        let sourceManager = DefaultSourceManager(localRoot: localRoot)
        ExtensionStoreManager.shared.loadAll(into: sourceManager)
        AppContainer.shared.register(sourceManager as SourceManager)
        AppContainer.shared.register(sourceManager)

        Task {
            await DownloadManager.shared.setSourceManager(sourceManager)
        }

        AppLog.info("Bootstrap complete", category: "app")
    }

    /// Ships one real, working manga source (MangaDex, JSON API — actually runs in the JS
    /// sandbox) so there's usable content out of the box without the user hunting for a
    /// working extension store. Runs once; if the user later uninstalls it, we don't reinstall.
    private func installBuiltInExtensionsIfNeeded() {
        let key = "mihon.installed_builtin_mangadex_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        do {
            try ExtensionStoreManager.shared.installMangaDexExtension()
            UserDefaults.standard.set(true, forKey: key)
            AppLog.info("Installed built-in MangaDex source", category: "ext")
        } catch {
            AppLog.error("Failed to install built-in MangaDex source", error: error, category: "ext")
        }
    }
}
