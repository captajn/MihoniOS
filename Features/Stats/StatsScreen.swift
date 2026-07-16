import SwiftUI
import Core
import Domain
import DesignSystem

struct StatsScreen: View {
    @State private var stats = LibraryStats()
    @State private var error: String?

    var body: some View {
        List {
            if let error {
                Text(error).foregroundStyle(.red)
            }
            Section(String(localized: "label_library")) {
                LabeledContent(String(localized: "label_stats"), value: "\(stats.totalLibrary)")
                LabeledContent(String(localized: "label_stats"), value: "\(stats.completedTitles)")
                LabeledContent(String(localized: "label_stats"), value: "\(stats.trackedTitles)")
            }
            Section(String(localized: "chapters")) {
                LabeledContent(String(localized: "chapters"), value: "\(stats.totalChapters)")
                LabeledContent(String(localized: "action_mark_as_read"), value: "\(stats.readChapters)")
            }
            Section(String(localized: "label_stats")) {
                LabeledContent(String(localized: "label_stats"), value: String(format: "%.1f", stats.readDurationHours))
            }
        }
        .navigationTitle(String(localized: "label_stats"))
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        guard let manga = AppContainer.shared.resolve(MangaRepository.self),
              let chapter = AppContainer.shared.resolve(ChapterRepository.self),
              let track = AppContainer.shared.resolve(TrackRepository.self),
              let history = AppContainer.shared.resolve(HistoryRepository.self)
        else {
            error = String(localized: "action_show_errors")
            return
        }
        do {
            stats = try await GetLibraryStats(
                mangaRepo: manga,
                chapterRepo: chapter,
                trackRepo: track,
                historyRepo: history
            ).await()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
