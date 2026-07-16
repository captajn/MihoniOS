import WidgetKit
import SwiftUI

let widgetAppGroupID = "group.app.mihon.ios"
let widgetTitlesKey = "widget.recent.titles"

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
        UserDefaults(suiteName: widgetAppGroupID)?.stringArray(forKey: widgetTitlesKey)
            ?? ["Open Mihon for updates"]
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
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct UpdatesGridWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "UpdatesGrid", provider: UpdatesWidgetProvider()) { entry in
            UpdatesWidgetView(entry: entry)
        }
        .configurationDisplayName("Updates")
        .description("Recent library updates")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct MihonWidgets: WidgetBundle {
    var body: some Widget {
        UpdatesGridWidget()
    }
}
