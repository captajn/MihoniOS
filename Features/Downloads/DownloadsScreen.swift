import SwiftUI
import Combine
import Core
import Download
import DesignSystem

@MainActor
final class DownloadsViewModel: ObservableObject {
    @Published var items: [DownloadItem] = []
    private var task: Task<Void, Never>?

    func start() {
        task?.cancel()
        task = Task {
            let stream = await DownloadManager.shared.observe()
            for await list in stream {
                items = list
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    func pause() {
        Task { await DownloadManager.shared.pauseAll() }
    }

    func resume() {
        Task { await DownloadManager.shared.resumeAll() }
    }

    func clear() {
        Task { await DownloadManager.shared.clearFinished() }
    }

    func cancel(_ id: String) {
        Task { await DownloadManager.shared.cancel(id: id) }
    }
}

struct DownloadsScreen: View {
    @StateObject private var model = DownloadsViewModel()

    var body: some View {
        Group {
            if model.items.isEmpty {
                EmptyStateView(
                    title: String(localized: "label_download_queue"),
                    message: String(localized: "downloads_empty_description"),
                    systemImage: "arrow.down.circle"
                )
            } else {
                List {
                    ForEach(model.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.mangaTitle)
                                .font(.headline)
                            Text(item.chapterName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack {
                                Text(item.status.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(statusColor(item.status))
                                Spacer()
                                if item.status == .downloading {
                                    Text("\(Int(item.progress * 100))%")
                                        .font(.caption.monospacedDigit())
                                }
                            }
                            if item.status == .downloading || item.status == .queued {
                                ProgressView(value: item.progress)
                            }
                            if let err = item.errorMessage {
                                Text(err)
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                model.cancel(item.id)
                            } label: {
                                Label(String(localized: "action_cancel"), systemImage: "xmark")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "label_download_queue"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(String(localized: "action_pause"), action: model.pause)
                Button(String(localized: "action_resume"), action: model.resume)
                Button(String(localized: "action_remove"), action: model.clear)
            }
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func statusColor(_ s: DownloadStatus) -> Color {
        switch s {
        case .downloaded: .green
        case .error: .red
        case .downloading: .blue
        case .paused: .orange
        case .queued: .secondary
        }
    }
}
