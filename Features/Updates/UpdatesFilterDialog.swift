import SwiftUI

/// Filter dialog for Updates screen
struct UpdatesFilterDialog: View {
    @Binding var filterUnread: Bool
    @Binding var filterCompleted: Bool
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text(String(localized: "action_filter"))
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                Toggle(String(localized: "action_filter_unread"), isOn: $filterUnread)
                Toggle(String(localized: "action_read"), isOn: $filterCompleted)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            Button(String(localized: "action_done")) {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .presentationDetents([.medium])
    }
}
