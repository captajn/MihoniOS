import Foundation
import Compression

/// Reads CBZ/ZIP chapter archives (store + deflate).
public struct ArchivePageLoader: PageLoader, Sendable {
    public let archiveURL: URL

    public init(archiveURL: URL) {
        self.archiveURL = archiveURL
    }

    public func loadPages() async throws -> [ReaderPageItem] {
        let pairs = try ZipReader.extractImageData(at: archiveURL)
        guard !pairs.isEmpty else { throw PageLoaderError.emptyChapter }
        return pairs.enumerated().map { index, pair in
            ReaderPageItem(index: index, source: .data(pair.data))
        }
    }
}

// MARK: - Minimal ZIP reader (central directory)

enum ZipReader {
    struct CentralEntry {
        let name: String
        let compressionMethod: UInt16
        let compressedSize: UInt32
        let uncompressedSize: UInt32
        let localHeaderOffset: UInt32
    }

    static func extractImageData(at url: URL) throws -> [(name: String, data: Data)] {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let entries = try listEntries(data)
            .filter { !$0.name.hasSuffix("/") && ImageFileTypes.isImage(URL(fileURLWithPath: $0.name)) }
            .sorted {
                let a = ($0.name as NSString).lastPathComponent
                let b = ($1.name as NSString).lastPathComponent
                return a.localizedStandardCompare(b) == .orderedAscending
            }

        return try entries.map { entry in
            let bytes = try extract(entry: entry, from: data)
            return (entry.name, bytes)
        }
    }

    private static func listEntries(_ data: Data) throws -> [CentralEntry] {
        guard data.count >= 22, let eocd = findEOCD(in: data) else {
            throw PageLoaderError.unsupportedFormat("Invalid ZIP")
        }
        let count = Int(readUInt16(data, eocd + 10))
        var offset = Int(readUInt32(data, eocd + 16))
        var result: [CentralEntry] = []

        for _ in 0..<count {
            guard offset + 46 <= data.count, readUInt32(data, offset) == 0x0201_4b50 else { break }
            let method = readUInt16(data, offset + 10)
            let compSize = readUInt32(data, offset + 20)
            let uncompSize = readUInt32(data, offset + 24)
            let nameLen = Int(readUInt16(data, offset + 28))
            let extraLen = Int(readUInt16(data, offset + 30))
            let commentLen = Int(readUInt16(data, offset + 32))
            let localOffset = readUInt32(data, offset + 42)
            let nameStart = offset + 46
            guard nameStart + nameLen <= data.count else { break }
            let nameBytes = data.subdata(in: nameStart..<(nameStart + nameLen))
            let name = String(data: nameBytes, encoding: .utf8)
                ?? String(decoding: nameBytes, as: UTF8.self)
            result.append(
                CentralEntry(
                    name: name,
                    compressionMethod: method,
                    compressedSize: compSize,
                    uncompressedSize: uncompSize,
                    localHeaderOffset: localOffset
                )
            )
            offset = nameStart + nameLen + extraLen + commentLen
        }
        return result
    }

    private static func extract(entry: CentralEntry, from data: Data) throws -> Data {
        let o = Int(entry.localHeaderOffset)
        guard o + 30 <= data.count, readUInt32(data, o) == 0x0403_4b50 else {
            throw PageLoaderError.decodeFailed
        }
        let nameLen = Int(readUInt16(data, o + 26))
        let extraLen = Int(readUInt16(data, o + 28))
        let start = o + 30 + nameLen + extraLen
        let end = start + Int(entry.compressedSize)
        guard end <= data.count else { throw PageLoaderError.decodeFailed }
        let compressed = data.subdata(in: start..<end)

        switch entry.compressionMethod {
        case 0:
            return compressed
        case 8:
            return try inflateRaw(compressed, uncompressedSize: Int(entry.uncompressedSize))
        default:
            throw PageLoaderError.unsupportedFormat("ZIP method \(entry.compressionMethod)")
        }
    }

    /// Inflate raw DEFLATE (ZIP method 8) via zlib-wrapped Compression stream.
    private static func inflateRaw(_ raw: Data, uncompressedSize: Int) throws -> Data {
        // ZIP uses raw deflate; wrap with a minimal zlib header for COMPRESSION_ZLIB.
        var wrapped = Data([0x78, 0x9C])
        wrapped.append(raw)

        let dstCapacity = max(uncompressedSize > 0 ? uncompressedSize : raw.count * 8, 64 * 1024)
        var output = Data()
        output.reserveCapacity(dstCapacity)

        // Swift imports compression_stream as a struct requiring explicit fields.
        let dummyDst = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        let dummySrc = UnsafePointer<UInt8>(dummyDst)
        defer {
            dummyDst.deallocate()
        }
        var stream = compression_stream(
            dst_ptr: dummyDst,
            dst_size: 0,
            src_ptr: dummySrc,
            src_size: 0,
            state: nil
        )
        let initStatus = compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
        guard initStatus != COMPRESSION_STATUS_ERROR else { throw PageLoaderError.decodeFailed }
        defer { compression_stream_destroy(&stream) }

        var failed = false
        wrapped.withUnsafeBytes { (srcBuffer: UnsafeRawBufferPointer) in
            guard let srcBase = srcBuffer.bindMemory(to: UInt8.self).baseAddress else {
                failed = true
                return
            }
            stream.src_ptr = srcBase
            stream.src_size = wrapped.count

            let chunk = 64 * 1024
            var buffer = [UInt8](repeating: 0, count: chunk)

            while true {
                let flags: Int32 = stream.src_size == 0 ? Int32(COMPRESSION_STREAM_FINALIZE.rawValue) : 0
                let status = buffer.withUnsafeMutableBufferPointer { dst -> compression_status in
                    guard let base = dst.baseAddress else {
                        return COMPRESSION_STATUS_ERROR
                    }
                    stream.dst_ptr = base
                    stream.dst_size = chunk
                    return compression_stream_process(&stream, flags)
                }
                let produced = chunk - stream.dst_size
                if produced > 0 {
                    output.append(contentsOf: buffer.prefix(produced))
                }
                if status == COMPRESSION_STATUS_END {
                    break
                }
                if status == COMPRESSION_STATUS_ERROR {
                    failed = true
                    break
                }
            }
        }

        if failed || output.isEmpty { throw PageLoaderError.decodeFailed }
        if uncompressedSize > 0, output.count > uncompressedSize {
            return Data(output.prefix(uncompressedSize))
        }
        return output
    }

    private static func findEOCD(in data: Data) -> Int? {
        let maxScan = min(data.count, 22 + 65_535)
        var i = data.count - 22
        let lower = max(0, data.count - maxScan)
        while i >= lower {
            if readUInt32(data, i) == 0x0605_4b50 { return i }
            i -= 1
        }
        return nil
    }

    private static func readUInt16(_ data: Data, _ offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }

    private static func readUInt32(_ data: Data, _ offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
}
