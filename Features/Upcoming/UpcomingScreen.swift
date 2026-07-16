import SwiftUI
import Core
import Domain
import DesignSystem

@MainActor
final class UpcomingViewModel: ObservableObject {
    @Published var items: [(date: Date, manga: [Manga])] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }

        guard let mangaRepo = AppContainer.shared.resolve(MangaRepository.self) else {
            errorMessage = String(localized: "action_show_errors")
            return
        }

        do {
            let favorites = try await mangaRepo.getFavorites()
            let now = Date()

            // Filter manga with nextUpdate in the future
            let upcoming = favorites.filter { manga in
                manga.nextUpdate > Int64(now.timeIntervalSince1970 * 1000)
            }

            // Group by date
            let grouped = Dictionary(grouping: upcoming) { manga -> Date in
                let timestamp = TimeInterval(manga.nextUpdate) / 1000.0
                return Calendar.current.startOfDay(for: Date(timeIntervalSince1970: timestamp))
            }

            // Sort by date
            items = grouped.sorted { $0.key < $1.key }.map { (date: $0.key, manga: $0.value) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct UpcomingScreen: View {
    @StateObject private var model = UpcomingViewModel()

    var body: some View {
        Group {
            if model.isLoading && model.items.isEmpty {
                LoadingView()
            } else if model.items.isEmpty {
                EmptyStateView(
                    title: String(localized: "label_upcoming"),
                    message: String(localized: "label_upcoming"),
                    systemImage: "calendar"
                )
            } else {
                List {
                    ForEach(model.items, id: \.date) { section in
                        Section(header: Text(section.date, style: .relative)) {
                            ForEach(section.manga) { manga in
                                NavigationLink(value: manga.id) {
                                    HStack(spacing: 12) {
                                        MangaCoverView(title: manga.title, url: manga.thumbnailUrl)
                                            .frame(width: 48, height: 64)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(manga.title)
                                                .font(.headline)
                                                .lineLimit(1)
                                            if let author = manga.author, !author.isEmpty {
                                                Text(author)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "label_upcoming"))
        .navigationDestination(for: Int64.self) { mangaId in
            MangaDetailScreen(mangaId: mangaId)
        }
        .refreshable { await model.load() }
        .task { await model.load() }
    }
}
