import SwiftUI

/// Confirmation dialog for deleting manga from library
struct DeleteLibraryDialog: View {
    let mangaTitle: String
    let hasLocalManga: Bool
    @Binding var deleteManga: Bool
    @Binding var deleteChapters: Bool
    @Binding var isPresented: Bool
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "trash")
                .font(.largeTitle)
                .foregroundStyle(.red)

            Text(String(localized: "action_delete"))
                .font(.headline)

            Text(String(format: String(localized: "action_delete"), mangaTitle))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                Toggle(String(localized: "action_delete"), isOn: $deleteManga)
                    .tint(.red)

                if !hasLocalManga {
                    Toggle(String(localized: "delete_downloaded"), isOn: $deleteChapters)
                        .tint(.red)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            HStack(spacing: 16) {
                Button(String(localized: "action_cancel")) {
                    isPresented = false
                }
                .buttonStyle(.bordered)

                Button(String(localized: "action_delete")) {
                    onConfirm()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(!deleteManga && !deleteChapters)
            }
        }
        .padding(24)
        .interactiveDismissDisabled()
    }
}

/// Sheet wrapper for DeleteLibraryDialog
struct DeleteLibrarySheet: View {
    let mangaTitle: String
    let hasLocalManga: Bool
    @Binding var isPresented: Bool
    let onConfirm: (Bool, Bool) -> Void

    @State private var deleteManga = true
    @State private var deleteChapters = false

    var body: some View {
        DeleteLibraryDialog(
            mangaTitle: mangaTitle,
            hasLocalManga: hasLocalManga,
            deleteManga: $deleteManga,
            deleteChapters: $deleteChapters,
            isPresented: $isPresented,
            onConfirm: {
                onConfirm(deleteManga, deleteChapters)
            }
        )
        .presentationDetents([.medium])
    }
}
