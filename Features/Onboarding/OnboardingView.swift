import SwiftUI
import Core
import DesignSystem

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @AppStorage("pref_theme_mode_key") private var themeModeRaw: String = ThemeMode.system.rawValue
    @State private var step = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $step) {
                welcomePage.tag(0)
                themePage.tag(1)
                storagePage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .navigationTitle(String(localized: "onboarding_description"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if step < 2 {
                        Button(String(localized: "onboarding_action_next")) { withAnimation { step += 1 } }
                    } else {
                        Button(String(localized: "onboarding_action_finish")) {
                            appState.completeOnboarding()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            Text("Mihon")
                .font(.largeTitle.weight(.bold))
            Text(String(localized: "onboarding_description"))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
        }
        .padding(.top, 60)
    }

    private var themePage: some View {
        Form {
            Section(String(localized: "pref_category_general")) {
                Picker(String(localized: "pref_theme_mode"), selection: $themeModeRaw) {
                    ForEach(ThemeMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.inline)
            }
            Section {
                Text(String(localized: "onboarding_description"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var storagePage: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text(String(localized: "onboarding_description"))
                .font(.title2.weight(.semibold))
            Text(String(localized: "onboarding_description"))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            Spacer()
        }
        .padding(.top, 60)
    }
}
