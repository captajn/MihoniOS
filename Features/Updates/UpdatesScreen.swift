import SwiftUI
import Combine
import Core
import Domain
import DesignSystem

@MainActor
final class UpdatesViewModel: ObservableObject {
    @Published var items: [UpdatesWithRelations] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showFilter = false
    @Published var filterUnread: Bool = false
    @Published var filterCompleted: Bool = false
    private let getUpdates: GetUpdates?

    init(getUpdates: GetUpdates? = AppContainer.shared.resolve()) {
        self.getUpdates = getUpdates
    }

    var filtered: [UpdatesWithRelations] {
        var result = items
        if filterUnread {
            result = result.filter { !$0.read }
        }
        if filterCompleted {
            result = result.filter { $0.read }
        }
        return result
    }

    func load() async {
        guard let getUpdates else {
            errorMessage = String(localized: "error")
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let after = Int64(Date().addingTimeInterval(-90 * 24 * 3600).timeIntervalSince1970 * 1000)
            items = try await getUpdates.await(after: after, limit: 200)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct UpdatesScreen: View {
    @StateObject private var model = UpdatesViewModel()

    var body: some View {
        Group {
            if model.isLoading && model.items.isEmpty {
                LoadingView()
            } else if model.filtered.isEmpty {
                EmptyStateView(
                    title: String(localized: "label_recent_updates"),
                    message: String(localized: "label_recent_updates"),
                    systemImage: "bell"
                )
            } else {
                List(model.filtered) { item in
                    NavigationLink(value: item.mangaId) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.mangaTitle)
                                .font(.headline)
                            Text(item.chapterName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let scanlator = item.scanlator, !scanlator.isEmpty {
                                Text(scanlator)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .opacity(item.read ? 0.55 : 1)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "label_recent_updates"))
        .navigationDestination(for: Int64.self) { mangaId in
            MangaDetailScreen(mangaId: mangaId)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle(String(localized: "action_filter_unread"), isOn: $model.filterUnread)
                    Toggle(String(localized: "action_mark_as_read"), isOn: $model.filterCompleted)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .refreshable { await model.load() }
        .task { await model.load() }
    }
}
