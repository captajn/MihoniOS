import Foundation
import Combine
import Core

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: AppTab = .library
    @Published var showOnboarding: Bool

    init(container: AppContainer = .shared) {
        self.showOnboarding = !container.appPreferences.shownOnboarding.get()
    }

    func completeOnboarding() {
        AppContainer.shared.appPreferences.shownOnboarding.set(true)
        showOnboarding = false
    }
}

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case library
    case updates
    case history
    case browse
    case more

    var id: String { rawValue }

    var title: String {
        switch self {
        case .library: "Library"
        case .updates: "Updates"
        case .history: "History"
        case .browse: "Browse"
        case .more: "More"
        }
    }

    var systemImage: String {
        switch self {
        case .library: "books.vertical"
        case .updates: "bell"
        case .history: "clock"
        case .browse: "globe"
        case .more: "ellipsis.circle"
        }
    }
}
