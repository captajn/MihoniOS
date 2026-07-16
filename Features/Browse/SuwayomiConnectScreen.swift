import SwiftUI
import Core
import SourceAPI
import Extensions

struct SuwayomiConnectScreen: View {
    @State private var serverURL: String = ""
    @State private var connections: [SuwayomiConnection] = []
    @State private var available: [SuwayomiUpstreamSource] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Suwayomi-Server") {
                Text("Nhập URL server Suwayomi tự host của bạn (vd: http://192.168.1.10:4567), sau đó chọn nguồn có sẵn trên server để dùng trên iOS.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                TextField("http://192.168.1.10:4567", text: $serverURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                Button {
                    Task { await connect() }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Kết nối")
                    }
                }
                .disabled(serverURL.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            if !available.isEmpty {
                Section("Nguồn trên server") {
                    ForEach(available) { source in
                        Button {
                            add(source)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(source.name)
                                    Text(source.lang.uppercased())
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if connections.contains(where: { $0.upstreamSourceId == source.id && $0.serverURL == normalized(serverURL) }) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
            }

            if !connections.isEmpty {
                Section("Đã thêm") {
                    ForEach(connections) { conn in
                        VStack(alignment: .leading) {
                            Text(conn.name)
                            Text(conn.serverURL).font(.caption2).foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                SuwayomiManager.shared.removeConnection(id: conn.id)
                                reloadConnections()
                            } label: {
                                Label("Xoá", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Suwayomi")
        .onAppear { reloadConnections() }
    }

    private func normalized(_ url: String) -> String {
        var u = url.trimmingCharacters(in: .whitespaces)
        if u.hasSuffix("/") { u.removeLast() }
        return u
    }

    private func reloadConnections() {
        connections = SuwayomiManager.shared.getConnections()
    }

    private func connect() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            available = try await SuwayomiManager.shared.fetchAvailableSources(serverURL: normalized(serverURL))
            if available.isEmpty {
                errorMessage = "Server phản hồi nhưng chưa cài nguồn nào. Cài extension trên chính Suwayomi-Server trước."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func add(_ source: SuwayomiUpstreamSource) {
        let connection = SuwayomiConnection(
            serverURL: normalized(serverURL),
            upstreamSourceId: source.id,
            name: source.name,
            lang: source.lang,
            supportsLatest: source.supportsLatest
        )
        SuwayomiManager.shared.addConnection(connection)
        reloadConnections()
        if let manager = AppContainer.shared.resolve(DefaultSourceManager.self) {
            manager.register(connection.makeSource())
        }
    }
}
