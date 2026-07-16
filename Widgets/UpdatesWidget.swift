import WidgetKit
import SwiftUI

/// WidgetKit extension source (include in Widgets target when packaging).
/// For monorepo simplicity this file is compiled into the app as a stub preview provider.
/// Create a real Widget Extension target on Mac with XcodeGen later.

struct UpdatesWidgetEntry: TimelineEntry {
    let date: Date
    let titles: [String]
}

struct UpdatesWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> UpdatesWidgetEntry {
        UpdatesWidgetEntry(date: Date(), titles: ["Sample title"])
    }

    func getSnapshot(in context: Context, completion: @escaping (UpdatesWidgetEntry) -> Void) {
        completion(UpdatesWidgetEntry(date: Date(), titles: loadTitles()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpdatesWidgetEntry>) -> Void) {
        let entry = UpdatesWidgetEntry(date: Date(), titles: loadTitles())
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadTitles() -> [String] {
        // Shared App Group can be wired later; placeholder titles
        UserDefaults.standard.stringArray(forKey: "widget.recent.titles") ?? ["Open Mihon for updates"]
    }
}

struct UpdatesWidgetView: View {
    var entry: UpdatesWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Mihon Updates")
                .font(.headline)
            ForEach(entry.titles.prefix(4), id: \.self) { title in
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding()
    }
}

// Note: @main WidgetBundle lives in a separate Widget Extension target.
// Uncomment when creating MihonWidgets.appex:
//
// @main
// struct MihonWidgets: WidgetBundle {
//     var body: some Widget {
//         UpdatesGridWidget()
//     }
// }
//
// struct UpdatesGridWidget: Widget {
//     var body: some WidgetConfiguration {
//         StaticConfiguration(kind: "UpdatesGrid", provider: UpdatesWidgetProvider()) { entry in
//             UpdatesWidgetView(entry: entry)
//         }
//         .configurationDisplayName("Updates")
//         .description("Recent library updates")
//         .supportedFamilies([.systemSmall, .systemMedium])
//     }
// }
