import Foundation

public enum BackupDecoder {
    public static func decode(data: Data) throws -> BackupDocument {
        let raw: Data
        if isGzip(data) {
            raw = try (data as NSData).decompressed(using: .zlib) as Data
        } else {
            raw = data
        }
        return try decodeRaw(raw)
    }

    public static func decodeRaw(_ data: Data) throws -> BackupDocument {
        var reader = ProtoReader(data)
        var doc = BackupDocument()
        while let field = try reader.nextField() {
            switch field.field {
            case 1:
                let msg = try reader.readLengthDelimited()
                doc.manga.append(try decodeManga(msg))
            case 2:
                let msg = try reader.readLengthDelimited()
                doc.categories.append(try decodeCategory(msg))
            case 101:
                let msg = try reader.readLengthDelimited()
                doc.sources.append(try decodeSource(msg))
            case 104:
                let msg = try reader.readLengthDelimited()
                doc.preferences.append(try decodePreference(msg))
            case 105:
                let msg = try reader.readLengthDelimited()
                doc.sourcePreferences.append(try decodeSourcePrefs(msg))
            case 106:
                let msg = try reader.readLengthDelimited()
                doc.extensionStores.append(try decodeExtStore(msg))
            default:
                try reader.skipField(type: field.type)
            }
        }
        return doc
    }

    private static func isGzip(_ data: Data) -> Bool {
        data.count >= 2 && data[0] == 0x1f && data[1] == 0x8b
    }

    private static func decodeManga(_ data: Data) throws -> BackupManga {
        var r = ProtoReader(data)
        var m = BackupManga()
        while let f = try r.nextField() {
            switch f.field {
            case 1: m.source = try r.readInt64()
            case 2: m.url = try r.readString()
            case 3: m.title = try r.readString()
            case 4: m.artist = try r.readString()
            case 5: m.author = try r.readString()
            case 6: m.description = try r.readString()
            case 7: m.genre.append(try r.readString())
            case 8: m.status = try r.readInt32()
            case 9: m.thumbnailUrl = try r.readString()
            case 13: m.dateAdded = try r.readInt64()
            case 14: m.viewer = try r.readInt32()
            case 16: m.chapters.append(try decodeChapter(try r.readLengthDelimited()))
            case 17: m.categories.append(try r.readInt64())
            case 18: m.tracking.append(try decodeTracking(try r.readLengthDelimited()))
            case 100: m.favorite = try r.readBool()
            case 101: m.chapterFlags = try r.readInt32()
            case 103: m.viewerFlags = try r.readInt32()
            case 104: m.history.append(try decodeHistory(try r.readLengthDelimited()))
            case 105: m.updateStrategy = try r.readInt32()
            case 106: m.lastModifiedAt = try r.readInt64()
            case 107: m.favoriteModifiedAt = try r.readInt64()
            case 108: m.excludedScanlators.append(try r.readString())
            case 109: m.version = try r.readInt64()
            case 110: m.notes = try r.readString()
            case 111: m.initialized = try r.readBool()
            case 112: m.memo = try r.readLengthDelimited()
            default: try r.skipField(type: f.type)
            }
        }
        return m
    }

    private static func decodeChapter(_ data: Data) throws -> BackupChapter {
        var r = ProtoReader(data)
        var c = BackupChapter()
        while let f = try r.nextField() {
            switch f.field {
            case 1: c.url = try r.readString()
            case 2: c.name = try r.readString()
            case 3: c.scanlator = try r.readString()
            case 4: c.read = try r.readBool()
            case 5: c.bookmark = try r.readBool()
            case 6: c.lastPageRead = try r.readInt64()
            case 7: c.dateFetch = try r.readInt64()
            case 8: c.dateUpload = try r.readInt64()
            case 9: c.chapterNumber = try r.readFloat()
            case 10: c.sourceOrder = try r.readInt64()
            case 11: c.lastModifiedAt = try r.readInt64()
            case 12: c.version = try r.readInt64()
            case 13: c.memo = try r.readLengthDelimited()
            default: try r.skipField(type: f.type)
            }
        }
        return c
    }

    private static func decodeCategory(_ data: Data) throws -> BackupCategory {
        var r = ProtoReader(data)
        var c = BackupCategory()
        while let f = try r.nextField() {
            switch f.field {
            case 1: c.name = try r.readString()
            case 2: c.order = try r.readInt64()
            case 3: c.id = try r.readInt64()
            case 100: c.flags = try r.readInt64()
            default: try r.skipField(type: f.type)
            }
        }
        return c
    }

    private static func decodeHistory(_ data: Data) throws -> BackupHistory {
        var r = ProtoReader(data)
        var h = BackupHistory()
        while let f = try r.nextField() {
            switch f.field {
            case 1: h.url = try r.readString()
            case 2: h.lastRead = try r.readInt64()
            case 3: h.readDuration = try r.readInt64()
            default: try r.skipField(type: f.type)
            }
        }
        return h
    }

    private static func decodeTracking(_ data: Data) throws -> BackupTracking {
        var r = ProtoReader(data)
        var t = BackupTracking()
        while let f = try r.nextField() {
            switch f.field {
            case 1: t.syncId = try r.readInt32()
            case 2: t.libraryId = try r.readInt64()
            case 3: t.mediaIdInt = try r.readInt32()
            case 4: t.trackingUrl = try r.readString()
            case 5: t.title = try r.readString()
            case 6: t.lastChapterRead = try r.readFloat()
            case 7: t.totalChapters = try r.readInt32()
            case 8: t.score = try r.readFloat()
            case 9: t.status = try r.readInt32()
            case 10: t.startedReadingDate = try r.readInt64()
            case 11: t.finishedReadingDate = try r.readInt64()
            case 12: t.privateTrack = try r.readBool()
            case 100: t.mediaId = try r.readInt64()
            default: try r.skipField(type: f.type)
            }
        }
        return t
    }

    private static func decodeSource(_ data: Data) throws -> BackupSource {
        var r = ProtoReader(data)
        var s = BackupSource()
        while let f = try r.nextField() {
            switch f.field {
            case 1: s.name = try r.readString()
            case 2: s.sourceId = try r.readInt64()
            default: try r.skipField(type: f.type)
            }
        }
        return s
    }

    private static func decodePreference(_ data: Data) throws -> BackupPreference {
        var r = ProtoReader(data)
        var p = BackupPreference()
        while let f = try r.nextField() {
            switch f.field {
            case 1: p.key = try r.readString()
            case 2:
                // May be string (our format) or nested message from Android — try string first
                if f.type == .lengthDelimited {
                    let bytes = try r.readLengthDelimited()
                    if let s = String(data: bytes, encoding: .utf8), s.contains(":") {
                        applyPreferencePayload(s, to: &p)
                    }
                    // else skip nested Android PreferenceValue for now
                } else {
                    try r.skipField(type: f.type)
                }
            default: try r.skipField(type: f.type)
            }
        }
        return p
    }

    private static func applyPreferencePayload(_ payload: String, to p: inout BackupPreference) {
        guard let idx = payload.firstIndex(of: ":") else {
            p.type = .string
            p.stringValue = payload
            return
        }
        let type = String(payload[..<idx])
        let value = String(payload[payload.index(after: idx)...])
        switch type {
        case "b":
            p.type = .bool
            p.boolValue = value == "true"
        case "i":
            p.type = .int
            p.intValue = Int32(value) ?? 0
        case "l":
            p.type = .long
            p.longValue = Int64(value) ?? 0
        case "f":
            p.type = .float
            p.floatValue = Float(value) ?? 0
        case "ss":
            p.type = .stringSet
            p.stringSet = value.split(separator: "\u{1e}").map(String.init)
        default:
            p.type = .string
            p.stringValue = value
        }
    }

    private static func decodeSourcePrefs(_ data: Data) throws -> BackupSourcePreferences {
        var r = ProtoReader(data)
        var sp = BackupSourcePreferences()
        while let f = try r.nextField() {
            switch f.field {
            case 1: sp.sourceKey = try r.readString()
            case 2: sp.prefs.append(try decodePreference(try r.readLengthDelimited()))
            default: try r.skipField(type: f.type)
            }
        }
        return sp
    }

    private static func decodeExtStore(_ data: Data) throws -> BackupExtensionStore {
        var r = ProtoReader(data)
        var e = BackupExtensionStore()
        while let f = try r.nextField() {
            switch f.field {
            case 1: e.indexUrl = try r.readString()
            case 2: e.name = try r.readString()
            case 3: e.badgeLabel = try r.readString()
            case 4: e.contactWebsite = try r.readString()
            case 5: e.signingKey = try r.readString()
            case 6: e.contactDiscord = try r.readString()
            case 7: e.isLegacy = try r.readBool()
            case 8: e.extensionListUrl = try r.readString()
            default: try r.skipField(type: f.type)
            }
        }
        return e
    }
}
