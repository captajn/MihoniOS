import Foundation
import CoreGraphics

/// Navigation mode for reader tap zones (mirrors Android ViewerNavigation)
public enum NavigationMode: Int, CaseIterable, Sendable {
    case lShaped = 0        // Default L-shaped navigation
    case kindlish = 1       // Kindle-style
    case edge = 2           // Edge navigation
    case rightAndLeft = 3   // Bidirectional (doujinshi-style)
    case disabled = 4       // Entire screen is menu

    public var displayName: String {
        switch self {
        case .lShaped: return "L-shape"
        case .kindlish: return "Kindlish"
        case .edge: return "Edge"
        case .rightAndLeft: return "Right & Left"
        case .disabled: return "Disabled"
        }
    }

    /// Returns navigation regions for a given reader size.
    /// Regions are normalized (0..1) and overlap is resolved by priority: PREV/NEXT > MENU.
    public func regions(for size: CGSize) -> [NavigationRegion] {
        switch self {
        case .disabled:
            return [NavigationRegion(rect: CGRect(x: 0, y: 0, width: 1, height: 1), type: .menu)]

        case .lShaped:
            // L-shaped: top-left = prev, center = menu, bottom-right = next
            return [
                // Previous: top third + middle-left
                NavigationRegion(rect: CGRect(x: 0, y: 0, width: 1, height: 0.33), type: .prev),
                NavigationRegion(rect: CGRect(x: 0, y: 0.33, width: 0.33, height: 0.33), type: .prev),
                // Next: bottom third + middle-right
                NavigationRegion(rect: CGRect(x: 0, y: 0.67, width: 1, height: 0.33), type: .next),
                NavigationRegion(rect: CGRect(x: 0.67, y: 0.33, width: 0.33, height: 0.33), type: .next),
                // Menu: center
                NavigationRegion(rect: CGRect(x: 0.33, y: 0.33, width: 0.34, height: 0.34), type: .menu),
            ]

        case .kindlish:
            // Kindle-style: top = menu, left = prev, right = next
            return [
                NavigationRegion(rect: CGRect(x: 0, y: 0, width: 1, height: 0.33), type: .menu),
                NavigationRegion(rect: CGRect(x: 0, y: 0.33, width: 0.33, height: 0.67), type: .prev),
                NavigationRegion(rect: CGRect(x: 0.33, y: 0.33, width: 0.67, height: 0.67), type: .next),
            ]

        case .edge:
            // Edge: left = next, right = next, bottom-center = prev
            return [
                NavigationRegion(rect: CGRect(x: 0, y: 0, width: 0.33, height: 1), type: .next),
                NavigationRegion(rect: CGRect(x: 0.67, y: 0, width: 0.33, height: 1), type: .next),
                NavigationRegion(rect: CGRect(x: 0.33, y: 0.67, width: 0.34, height: 0.33), type: .prev),
                NavigationRegion(rect: CGRect(x: 0.33, y: 0, width: 0.34, height: 0.67), type: .menu),
            ]

        case .rightAndLeft:
            // Bidirectional: left = prev, right = next, center = menu
            return [
                NavigationRegion(rect: CGRect(x: 0, y: 0, width: 0.33, height: 1), type: .prev),
                NavigationRegion(rect: CGRect(x: 0.67, y: 0, width: 0.33, height: 1), type: .next),
                NavigationRegion(rect: CGRect(x: 0.33, y: 0, width: 0.34, height: 1), type: .menu),
            ]
        }
    }

    /// Determine which action a tap point triggers (in normalized 0..1 coordinates)
    public func action(for point: CGPoint, size: CGSize) -> NavigationAction {
        let regions = regions(for: size)
        // Check in reverse order so later-defined regions take priority
        for region in regions.reversed() {
            if region.rect.contains(point) {
                return region.type.action
            }
        }
        return .menu
    }
}

/// A rectangular navigation region with a type
public struct NavigationRegion: Sendable {
    public let rect: CGRect  // normalized 0..1
    public let type: RegionType

    public init(rect: CGRect, type: RegionType) {
        self.rect = rect
        self.type = type
    }
}

/// Type of navigation region
public enum RegionType: Sendable {
    case menu
    case prev
    case next
    case left
    case right

    var action: NavigationAction {
        switch self {
        case .menu: return .menu
        case .prev: return .previousPage
        case .next: return .nextPage
        case .left: return .previousPage
        case .right: return .nextPage
        }
    }

    public var displayName: String {
        switch self {
        case .menu: return "Menu"
        case .prev: return "Previous"
        case .next: return "Next"
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}

/// Navigation action triggered by a tap
public enum NavigationAction: Sendable {
    case menu
    case previousPage
    case nextPage
}
