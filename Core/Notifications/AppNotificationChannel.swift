import Foundation
import UserNotifications

/// Notification channels — mirror Android's separate NotificationChannel per feature
/// (Update/Library/Backup/Download) so users can mute/tune each independently in Settings.
public enum AppNotificationChannel: String, Sendable {
    case libraryUpdate = "channel.library_update"
    case download = "channel.download"
    case backup = "channel.backup"

    var threadIdentifier: String { rawValue }
}

public enum AppNotifications {
    public static func post(channel: AppNotificationChannel, title: String, body: String) async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.threadIdentifier = channel.threadIdentifier
        content.categoryIdentifier = channel.rawValue

        let request = UNNotificationRequest(
            identifier: "\(channel.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        try? await center.add(request)
    }
}
