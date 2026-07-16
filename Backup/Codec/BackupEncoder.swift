import Foundation

public enum BackupEncoder {
    public static func encode(_ backup: BackupDocument) -> Data {
        var w = ProtoWriter()
        for m in backup.manga {
            w.writeMessage(1, encodeManga(m))
        }
        for c in backup.categories {
            w.writeMessage(2, encodeCategory(c))
        }
        for s in backup.sources {
            w.writeMessage(101, encodeSource(s))
        }
        for p in backup.preferences {
            w.writeMessage(104, encodePreference(p))
        }
        for sp in backup.sourcePreferences {
            w.writeMessage(105, encodeSourcePrefs(sp))
        }
        for e in backup.extensionStores {
            w.writeMessage(106, encodeExtStore(e))
        }
        return w.data
    }

    public static func encodeGzip(_ backup: BackupDocument) throws -> Data {
        let raw = encode(backup)
        return try (raw as NSData).compressed(using: .zlib) as Data
    }

    private static func encodeManga(_ m: BackupManga) -> Data {
        var w = ProtoWriter()
        w.writeInt64(1, m.source)
        w.writeString(2, m.url)
        if !m.title.isEmpty { w.writeString(3, m.title) }
        if let v = m.artist { w.writeString(4, v) }
        if let v = m.author { w.writeString(5, v) }
        if let v = m.description { w.writeString(6, v) }
        for g in m.genre { w.writeString(7, g) }
        if m.status != 0 { w.writeInt32(8, m.status) }
        if let v = m.thumbnailUrl { w.writeString(9, v) }
        if m.dateAdded != 0 { w.writeInt64(13, m.dateAdded) }
        if m.viewer != 0 { w.writeInt32(14, m.viewer) }
        for ch in m.chapters { w.writeMessage(16, encodeChapter(ch)) }
        for c in m.categories { w.writeInt64(17, c) }
        for t in m.tracking { w.writeMessage(18, encodeTracking(t)) }
        w.writeBool(100, m.favorite)
        if m.chapterFlags != 0 { w.writeInt32(101, m.chapterFlags) }
        if let vf = m.viewerFlags { w.writeInt32(103, vf) }
        for h in m.history { w.writeMessage(104, encodeHistory(h)) }
        if m.updateStrategy != 0 { w.writeInt32(105, m.updateStrategy) }
        if m.lastModifiedAt != 0 { w.writeInt64(106, m.lastModifiedAt) }
        if let f = m.favoriteModifiedAt { w.writeInt64(107, f) }
        for s in m.excludedScanlators { w.writeString(108, s) }
        if m.version != 0 { w.writeInt64(109, m.version) }
        if !m.notes.isEmpty { w.writeString(110, m.notes) }
        if m.initialized { w.writeBool(111, m.initialized) }
        if !m.memo.isEmpty { w.writeBytes(112, m.memo) }
        return w.data
    }

    private static func encodeChapter(_ c: BackupChapter) -> Data {
        var w = ProtoWriter()
        w.writeString(1, c.url)
        w.writeString(2, c.name)
        if let s = c.scanlator { w.writeString(3, s) }
        if c.read { w.writeBool(4, true) }
        if c.bookmark { w.writeBool(5, true) }
        if c.lastPageRead != 0 { w.writeInt64(6, c.lastPageRead) }
        if c.dateFetch != 0 { w.writeInt64(7, c.dateFetch) }
        if c.dateUpload != 0 { w.writeInt64(8, c.dateUpload) }
        if c.chapterNumber != 0 { w.writeFloat(9, c.chapterNumber) }
        if c.sourceOrder != 0 { w.writeInt64(10, c.sourceOrder) }
        if c.lastModifiedAt != 0 { w.writeInt64(11, c.lastModifiedAt) }
        if c.version != 0 { w.writeInt64(12, c.version) }
        if !c.memo.isEmpty { w.writeBytes(13, c.memo) }
        return w.data
    }

    private static func encodeCategory(_ c: BackupCategory) -> Data {
        var w = ProtoWriter()
        w.writeString(1, c.name)
        if c.order != 0 { w.writeInt64(2, c.order) }
        if c.id != 0 { w.writeInt64(3, c.id) }
        if c.flags != 0 { w.writeInt64(100, c.flags) }
        return w.data
    }

    private static func encodeHistory(_ h: BackupHistory) -> Data {
        var w = ProtoWriter()
        w.writeString(1, h.url)
        w.writeInt64(2, h.lastRead)
        if h.readDuration != 0 { w.writeInt64(3, h.readDuration) }
        return w.data
    }

    private static func encodeTracking(_ t: BackupTracking) -> Data {
        var w = ProtoWriter()
        w.writeInt32(1, t.syncId)
        w.writeInt64(2, t.libraryId)
        if t.mediaIdInt != 0 { w.writeInt32(3, t.mediaIdInt) }
        if !t.trackingUrl.isEmpty { w.writeString(4, t.trackingUrl) }
        if !t.title.isEmpty { w.writeString(5, t.title) }
        if t.lastChapterRead != 0 { w.writeFloat(6, t.lastChapterRead) }
        if t.totalChapters != 0 { w.writeInt32(7, t.totalChapters) }
        if t.score != 0 { w.writeFloat(8, t.score) }
        if t.status != 0 { w.writeInt32(9, t.status) }
        if t.startedReadingDate != 0 { w.writeInt64(10, t.startedReadingDate) }
        if t.finishedReadingDate != 0 { w.writeInt64(11, t.finishedReadingDate) }
        if t.privateTrack { w.writeBool(12, true) }
        if t.mediaId != 0 { w.writeInt64(100, t.mediaId) }
        return w.data
    }

    private static func encodeSource(_ s: BackupSource) -> Data {
        var w = ProtoWriter()
        if !s.name.isEmpty { w.writeString(1, s.name) }
        w.writeInt64(2, s.sourceId)
        return w.data
    }

    /// Simplified preference: store as string key + string value (type in key prefix).
    /// Full sealed PreferenceValue parity is lossy for exotic types; restore maps string/int/bool.
    private static func encodePreference(_ p: BackupPreference) -> Data {
        var w = ProtoWriter()
        w.writeString(1, p.key)
        // Nested PreferenceValue as length-delimited field 2 is complex with sealed classes.
        // Encode as string payload "type:value" for iOS ↔ iOS reliability; Android cross-restore
        // for preferences may need refinement.
        let payload: String
        switch p.type {
        case .bool: payload = "b:\(p.boolValue)"
        case .int: payload = "i:\(p.intValue)"
        case .long: payload = "l:\(p.longValue)"
        case .float: payload = "f:\(p.floatValue)"
        case .stringSet: payload = "ss:\(p.stringSet.joined(separator: "\u{1e}"))"
        case .string: payload = "s:\(p.stringValue)"
        }
        w.writeString(2, payload)
        return w.data
    }

    private static func encodeSourcePrefs(_ sp: BackupSourcePreferences) -> Data {
        var w = ProtoWriter()
        w.writeString(1, sp.sourceKey)
        for p in sp.prefs { w.writeMessage(2, encodePreference(p)) }
        return w.data
    }

    private static func encodeExtStore(_ e: BackupExtensionStore) -> Data {
        var w = ProtoWriter()
        w.writeString(1, e.indexUrl)
        w.writeString(2, e.name)
        if let b = e.badgeLabel { w.writeString(3, b) }
        w.writeString(4, e.contactWebsite)
        w.writeString(5, e.signingKey)
        if let d = e.contactDiscord { w.writeString(6, d) }
        if let l = e.isLegacy { w.writeBool(7, l) }
        if let u = e.extensionListUrl { w.writeString(8, u) }
        return w.data
    }
}
