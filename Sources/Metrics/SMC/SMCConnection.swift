import IOKit

/// Read-only connection to the System Management Controller (fans, sensors).
final class SMCConnection {
    private static let structMethodSelector: UInt32 = 2
    private static let readKeyInfoCommand: UInt8 = 9
    private static let readBytesCommand: UInt8 = 5
    private static let writeBytesCommand: UInt8 = 6
    private static let floatType = fourCharCode("flt ")

    private var connection: io_connect_t = 0

    init?() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        guard IOServiceOpen(service, mach_task_self_, 0, &connection) == kIOReturnSuccess else { return nil }
    }

    deinit {
        IOServiceClose(connection)
    }

    /// Reads a numeric key; supports the `flt ` type (Apple Silicon) and unsigned integers.
    func readNumber(_ key: String) -> Double? {
        guard let info = keyInfo(key) else { return nil }

        var readRequest = SMCKeyData()
        readRequest.key = Self.fourCharCode(key)
        readRequest.keyInfo.dataSize = info.dataSize
        readRequest.command = Self.readBytesCommand
        guard var output = call(&readRequest) else { return nil }

        let bytes = withUnsafeBytes(of: &output.bytes) { Array($0.prefix(Int(info.dataSize))) }
        return Self.decode(bytes, type: info.dataType)
    }

    /// Writes a numeric key respecting its type. Requires root; returns false if the SMC rejects it.
    func writeNumber(_ key: String, _ value: Double) -> Bool {
        guard let info = keyInfo(key), let encoded = Self.encode(value, type: info.dataType, size: Int(info.dataSize))
        else { return false }

        var request = SMCKeyData()
        request.key = Self.fourCharCode(key)
        request.keyInfo.dataSize = info.dataSize
        request.command = Self.writeBytesCommand
        withUnsafeMutableBytes(of: &request.bytes) { buffer in
            for (index, byte) in encoded.enumerated() { buffer[index] = byte }
        }
        return call(&request) != nil
    }

    private func keyInfo(_ key: String) -> SMCKeyData.KeyInfo? {
        var request = SMCKeyData()
        request.key = Self.fourCharCode(key)
        request.command = Self.readKeyInfoCommand
        guard let info = call(&request)?.keyInfo, info.dataSize > 0, info.dataSize <= 32 else { return nil }
        return info
    }

    private func call(_ input: inout SMCKeyData) -> SMCKeyData? {
        var output = SMCKeyData()
        var outputSize = MemoryLayout<SMCKeyData>.stride
        let result = IOConnectCallStructMethod(connection, Self.structMethodSelector,
                                               &input, MemoryLayout<SMCKeyData>.stride, &output, &outputSize)
        return result == kIOReturnSuccess && output.result == 0 ? output : nil
    }

    private static func decode(_ bytes: [UInt8], type: UInt32) -> Double? {
        if type == floatType, bytes.count == 4 {
            return Double(bytes.withUnsafeBytes { $0.loadUnaligned(as: Float.self) })
        }
        guard bytes.count <= 4 else { return nil }
        return Double(bytes.reduce(UInt32(0)) { $0 << 8 | UInt32($1) })
    }

    private static func encode(_ value: Double, type: UInt32, size: Int) -> [UInt8]? {
        if type == floatType, size == 4 {
            return withUnsafeBytes(of: Float(value)) { Array($0) }
        }
        guard size <= 4, value >= 0 else { return nil }
        let integer = UInt32(value.rounded())
        return (0..<size).reversed().map { UInt8(truncatingIfNeeded: integer >> (8 * UInt32($0))) }
    }

    private static func fourCharCode(_ text: String) -> UInt32 {
        text.utf8.reduce(0) { $0 << 8 | UInt32($1) }
    }
}
