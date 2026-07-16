import SwiftUI
import Combine
import Core
import Domain
import DesignSystem

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var items: [HistoryWithRelations] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var errorMessage: String?
    private let getHistory: GetHistory?

    init(getHistory: GetHistory? = AppContainer.shared.resolve()) {
        self.getHistory = getHistory
    }

    func load() async {
        guard let getHistory else {
            errorMessage = String(localized: "Database not ready")
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await getHistory.await(query: searchText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct HistoryScreen: View {
    @StateObject private var model = HistoryViewModel()

    var body: some View {
        Group {
            if model.isLoading && model.items.isEmpty {
                LoadingView()
            } else if model.items.isEmpty {
                EmptyStateView(
                    title: String(localized: "history"),
                    message: String(localized: "history_empty_description"),
                    systemImage: "clock"
                )
            } else {
                List(model.items) { item in
                    NavigationLink(value: item.mangaId) {
                        HStack(spacing: 12) {
                            MangaCoverView(title: item.mangaTitle, url: item.mangaThumbnailUrl)
                                .frame(width: 48)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.mangaTitle)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(item.chapterName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let readAt = item.readAt {
                                    Text(Date(timeIntervalSince1970: TimeInterval(readAt) / 1000.0), style: .relative)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "history"))
        .navigationDestination(for: Int64.self) { mangaId in
            MangaDetailScreen(mangaId: mangaId)
        }
        .searchable(text: $model.searchText, prompt: String(localized: "action_search"))
        .onChange(of: model.searchText) { _ in
            Task { await model.load() }
        }
        .refreshable { await model.load() }
        .task { await model.load() }
    }
}
