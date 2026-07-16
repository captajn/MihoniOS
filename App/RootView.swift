import SwiftUI
import Core
import DesignSystem

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var unlocked = false

    private var needsLock: Bool {
        AppContainer.shared.appPreferences.useAuthenticator.get()
    }

    var body: some View {
        Group {
            if appState.showOnboarding {
                OnboardingView()
            } else if needsLock && !unlocked {
                AppLockView { unlocked = true }
            } else {
                HomeTabView()
            }
        }
    }
}

struct HomeTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    tabRoot(tab)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
        }
    }

    @ViewBuilder
    private func tabRoot(_ tab: AppTab) -> some View {
        switch tab {
        case .library:
            LibraryScreen()
        case .updates:
            UpdatesScreen()
        case .history:
            HistoryScreen()
        case .browse:
            BrowseScreen()
        case .more:
            MoreScreen()
        }
    }
}
