import SwiftUI
import Core
import Tracking
import DesignSystem

struct TrackingSettingsScreen: View {
    @State private var refresh = UUID()

    var body: some View {
        List {
            Section {
                Text(String(localized: "tracking_description"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section(String(localized: "pref_category_tracking")) {
                ForEach(TrackerManager.shared.trackers, id: \.id) { tracker in
                    NavigationLink {
                        TrackerLoginScreen(trackerId: tracker.id)
                    } label: {
                        HStack {
                            Text(tracker.name)
                            Spacer()
                            Text(tracker.isLoggedIn ? String(localized: "logged_in") : String(localized: "not_logged_in"))
                                .font(.caption)
                                .foregroundStyle(tracker.isLoggedIn ? .green : .secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(String(localized: "pref_category_tracking"))
        .id(refresh)
        .onAppear { refresh = UUID() }
    }
}

struct TrackerLoginScreen: View {
    let trackerId: Int64
    @State private var username = ""
    @State private var password = ""
    @State private var message: String?
    @Environment(\.dismiss) private var dismiss

    private var tracker: (any Tracker)? {
        TrackerManager.shared.get(trackerId)
    }

    var body: some View {
        Form {
            if let tracker {
                Section(tracker.name) {
                    if tracker.isLoggedIn {
                        Text(String(localized: "logged_in"))
                            .foregroundStyle(.green)
                        Button(String(localized: "action_remove"), role: .destructive) {
                            tracker.logout()
                            message = String(localized: "logged_out")
                        }
                    } else {
                        TextField(fieldUserLabel, text: $username)
                            .textInputAutocapitalization(.never)
                        SecureField(fieldPassLabel, text: $password)
                        Button(String(localized: "tracker_login")) {
                            Task { await login() }
                        }
                    }
                }
                if let message {
                    Section { Text(message).font(.footnote) }
                }
            } else {
                Text(String(localized: "tracker_unknown"))
            }
        }
        .navigationTitle(tracker?.name ?? String(localized: "pref_category_tracking"))
    }

    private var fieldUserLabel: String {
        switch trackerId {
        case 6, 8, 9: return String(localized: "tracker_server_url")
        default: return String(localized: "tracker_username")
        }
    }

    private var fieldPassLabel: String {
        switch trackerId {
        case 6, 8, 9: return String(localized: "tracker_api_key")
        default: return String(localized: "tracker_password")
        }
    }

    private func login() async {
        guard let tracker else { return }
        do {
            try await tracker.login(username: username, password: password)
            message = String(localized: "logged_in")
        } catch {
            message = error.localizedDescription
        }
    }
}
