import Foundation
import SwiftUI

/// Handles deep links for the app
@MainActor
final class DeepLinkHandler {
    static let shared = DeepLinkHandler()

    /// Process a deep link URL
    func handle(url: URL, appState: AppState) -> Bool {
        // Handle manga URLs: https://mihon.app/manga/{id}
        if url.host == "mihon.app" || url.host == "mihon" {
            let pathComponents = url.pathComponents

            // /manga/{id}
            if pathComponents.count >= 3, pathComponents[1] == "manga" {
                if let mangaId = Int64(pathComponents[2]) {
                    appState.navigate(to: .mangaDetail(mangaId))
                    return true
                }
            }
        }

        // Handle custom URL scheme: mihon://manga/{id}
        if url.scheme == "mihon" {
            let pathComponents = url.pathComponents

            if pathComponents.count >= 2, pathComponents[1] == "manga" {
                if pathComponents.count >= 3, let mangaId = Int64(pathComponents[2]) {
                    appState.navigate(to: .mangaDetail(mangaId))
                    return true
                }
            }
        }

        return false
    }
}

/// Navigation destinations for deep links
enum DeepLinkDestination: Hashable {
    case mangaDetail(Int64)
}

/// Extension to AppState for navigation
extension AppState {
    func navigate(to destination: DeepLinkDestination) {
        switch destination {
        case .mangaDetail(let mangaId):
            selectedTab = .browse
            // The MangaDetailScreen will be pushed via navigation
        }
    }
}
