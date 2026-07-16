import Foundation
import Core
import Domain
import Reader
import SourceAPI

enum ReaderPresentation {
    /// Build open request for a local (or stored) chapter.
    static func request(
        manga: Manga,
        chapter: Chapter,
        chapters: [Chapter],
        readingMode: ReadingMode? = nil
    ) -> ReaderOpenRequest {
        let mode = readingMode
            ?? ReadingMode.fromPreference(Int(manga.viewerFlags & Int64(ReadingMode.mask)))
            .nonDefault
            ?? ReadingMode.fromPreference(AppContainer.shared.readerPreferences.defaultReadingMode.get())
            .nonDefault
            ?? .rightToLeft

        let refs = chapters.map { ReaderChapterRef(chapter: $0, sourceId: manga.source) }
        let current = ReaderChapterRef(chapter: chapter, sourceId: manga.source)

        var localPath: URL?
        if manga.source == LocalSource.idValue {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let root = docs?.appendingPathComponent("local", isDirectory: true)
            if let root {
                localPath = root.appendingPathComponent(chapter.url)
            }
        }

        return ReaderOpenRequest(
            mangaTitle: manga.title,
            chapter: current,
            chapters: refs,
            readingMode: mode,
            localPath: localPath
        )
    }
}

private extension ReadingMode {
    var nonDefault: ReadingMode? {
        self == .default ? nil : self
    }
}
