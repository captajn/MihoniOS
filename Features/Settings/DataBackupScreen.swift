import SwiftUI
import Core
import Backup
import Domain
import DesignSystem
import UniformTypeIdentifiers

struct DataBackupScreen: View {
    @State private var message: String?
    @State private var isBusy = false
    @State private var exportURL: URL?
    @State private var showImporter = false
    @State private var validationText: String?

    var body: some View {
        Form {
            Section {
                LabeledContent(String(localized: "label_backup")) {
                    Text(AppContainer.shared.databaseReady ? String(localized: "on") : String(localized: "off"))
                        .foregroundStyle(AppContainer.shared.databaseReady ? .green : .red)
                }
            }

            Section(String(localized: "label_backup")) {
                Button {
                    Task { await createBackup() }
                } label: {
                    Label(String(localized: "backup_create"), systemImage: "arrow.up.doc")
                }
                .disabled(isBusy)

                Button {
                    showImporter = true
                } label: {
                    Label(String(localized: "backup_restore"), systemImage: "arrow.down.doc")
                }
                .disabled(isBusy)

                if let validationText {
                    Text(validationText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section(String(localized: "label_data_storage")) {
                Text(String(localized: "backup_downloads_path"))
                    .font(.footnote)
                Text(String(localized: "backup_local_source_path"))
                    .font(.footnote)
                Text(String(localized: "backup_extensions_path"))
                    .font(.footnote)
            }

            if let message {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(String(localized: "label_data_storage"))
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.data, .item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task { await restore(url: url) }
                }
            case .failure(let error):
                message = error.localizedDescription
            }
        }
        .sheet(isPresented: Binding(
            get: { exportURL != nil },
            set: { if !$0 { exportURL = nil } }
        )) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
    }

    private func service() throws -> BackupService {
        guard let manga = AppContainer.shared.resolve(MangaRepository.self),
              let chapter = AppContainer.shared.resolve(ChapterRepository.self),
              let category = AppContainer.shared.resolve(CategoryRepository.self),
              let history = AppContainer.shared.resolve(HistoryRepository.self),
              let track = AppContainer.shared.resolve(TrackRepository.self),
              let source = AppContainer.shared.resolve(SourceRepository.self)
        else {
            throw BackupError.io("Repositories not ready")
        }
        return BackupService(
            mangaRepo: manga,
            chapterRepo: chapter,
            categoryRepo: category,
            historyRepo: history,
            trackRepo: track,
            sourceRepo: source
        )
    }

    private func createBackup() async {
        isBusy = true
        defer { isBusy = false }
        do {
            let svc = try service()
            let data = try await svc.createBackup()
            let dir = FileManager.default.temporaryDirectory
            let url = dir.appendingPathComponent("mihon-\(Int(Date().timeIntervalSince1970)).tachibk")
            try data.write(to: url)
            exportURL = url
            message = String(format: String(localized: "backup_created_format"), data.count)
        } catch {
            message = error.localizedDescription
        }
    }

    private func restore(url: URL) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let svc = try service()
            let validation = try svc.validate(data: data)
            validationText = "\(validation.mangaCount) manga, \(validation.categoryCount) categories, \(validation.missingSources.count) sources"
            try await svc.restore(data: data)
            message = String(localized: "backup_restore_complete")
        } catch {
            message = error.localizedDescription
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
