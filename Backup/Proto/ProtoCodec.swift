import Foundation

/// Minimal protobuf wire codec (proto3) compatible with kotlinx.serialization protobuf field numbers.
enum ProtoWireType: UInt8 {
    case varint = 0
    case fixed64 = 1
    case lengthDelimited = 2
    case fixed32 = 5
}

struct ProtoWriter {
    private(set) var data = Data()

    mutating func writeTag(field: UInt32, type: ProtoWireType) {
        writeVarint(UInt64((field << 3) | UInt32(type.rawValue)))
    }

    mutating func writeVarint(_ value: UInt64) {
        var v = value
        while v > 0x7F {
            data.append(UInt8((v & 0x7F) | 0x80))
            v >>= 7
        }
        data.append(UInt8(v & 0x7F))
    }

    mutating func writeSignedVarint(_ value: Int64) {
        // protobuf uses zig-zag for sint; kotlinx uses plain varint for Long (two's complement as unsigned)
        writeVarint(UInt64(bitPattern: value))
    }

    mutating func writeBool(_ field: UInt32, _ value: Bool) {
        writeTag(field: field, type: .varint)
        writeVarint(value ? 1 : 0)
    }

    mutating func writeInt32(_ field: UInt32, _ value: Int32) {
        writeTag(field: field, type: .varint)
        writeVarint(UInt64(bitPattern: Int64(value)))
    }

    mutating func writeInt64(_ field: UInt32, _ value: Int64) {
        writeTag(field: field, type: .varint)
        writeVarint(UInt64(bitPattern: value))
    }

    mutating func writeUInt64(_ field: UInt32, _ value: UInt64) {
        writeTag(field: field, type: .varint)
        writeVarint(value)
    }

    mutating func writeFloat(_ field: UInt32, _ value: Float) {
        writeTag(field: field, type: .fixed32)
        var v = value.bitPattern.littleEndian
        withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
    }

    mutating func writeDouble(_ field: UInt32, _ value: Double) {
        writeTag(field: field, type: .fixed64)
        var v = value.bitPattern.littleEndian
        withUnsafeBytes(of: &v) { data.append(contentsOf: $0) }
    }

    mutating func writeString(_ field: UInt32, _ value: String) {
        let bytes = Data(value.utf8)
        writeTag(field: field, type: .lengthDelimited)
        writeVarint(UInt64(bytes.count))
        data.append(bytes)
    }

    mutating func writeBytes(_ field: UInt32, _ value: Data) {
        writeTag(field: field, type: .lengthDelimited)
        writeVarint(UInt64(value.count))
        data.append(value)
    }

    mutating func writeMessage(_ field: UInt32, _ message: Data) {
        writeBytes(field, message)
    }

    mutating func writePackedStringList(_ field: UInt32, _ values: [String]) {
        for v in values { writeString(field, v) }
    }
}

struct ProtoReader {
    let data: Data
    private var offset: Int = 0

    init(_ data: Data) { self.data = data }

    var isAtEnd: Bool { offset >= data.count }

    mutating func nextField() throws -> (field: UInt32, type: ProtoWireType)? {
        guard !isAtEnd else { return nil }
        let key = try readVarint()
        let field = UInt32(key >> 3)
        guard let type = ProtoWireType(rawValue: UInt8(key & 0x7)) else {
            throw BackupError.corrupt("Unknown wire type")
        }
        return (field, type)
    }

    mutating func skipField(type: ProtoWireType) throws {
        switch type {
        case .varint: _ = try readVarint()
        case .fixed64: offset += 8
        case .fixed32: offset += 4
        case .lengthDelimited:
            let len = Int(try readVarint())
            offset += len
        }
        guard offset <= data.count else { throw BackupError.corrupt("Skip overflow") }
    }

    mutating func readVarint() throws -> UInt64 {
        var result: UInt64 = 0
        var shift = 0
        while true {
            guard offset < data.count else { throw BackupError.corrupt("EOF varint") }
            let b = data[offset]
            offset += 1
            result |= UInt64(b & 0x7F) << shift
            if b & 0x80 == 0 { return result }
            shift += 7
            if shift > 63 { throw BackupError.corrupt("Varint too long") }
        }
    }

    mutating func readInt64() throws -> Int64 {
        Int64(bitPattern: try readVarint())
    }

    mutating func readInt32() throws -> Int32 {
        Int32(truncatingIfNeeded: try readVarint())
    }

    mutating func readBool() throws -> Bool {
        try readVarint() != 0
    }

    mutating func readFloat() throws -> Float {
        guard offset + 4 <= data.count else { throw BackupError.corrupt("EOF float") }
        let bits = data.subdata(in: offset..<(offset + 4)).withUnsafeBytes { $0.load(as: UInt32.self) }.littleEndian
        offset += 4
        return Float(bitPattern: bits)
    }

    mutating func readLengthDelimited() throws -> Data {
        let len = Int(try readVarint())
        guard offset + len <= data.count else { throw BackupError.corrupt("EOF bytes") }
        let slice = data.subdata(in: offset..<(offset + len))
        offset += len
        return slice
    }

    mutating func readString() throws -> String {
        let bytes = try readLengthDelimited()
        return String(data: bytes, encoding: .utf8) ?? ""
    }
}

public enum BackupError: Error, LocalizedError, Sendable {
    case corrupt(String)
    case invalidFile
    case io(String)

    public var errorDescription: String? {
        switch self {
        case .corrupt(let m): "Corrupt backup: \(m)"
        case .invalidFile: "Invalid backup file"
        case .io(let m): m
        }
    }
}
