import Foundation

struct ConnectedDevice: Identifiable, Equatable {
    let serial: String
    let state: String
    let model: String?
    let product: String?
    let transport: String?

    var id: String { serial }

    var isWireless: Bool {
        serial.contains(":") || serial.contains("._adb-tls-connect.")
    }

    var displayModel: String? {
        model?.replacingOccurrences(of: "_", with: " ")
    }

    static func parse(line: String) -> ConnectedDevice? {
        let tokens = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
        guard tokens.count >= 2 else { return nil }
        var fields: [String: String] = [:]
        for token in tokens.dropFirst(2) {
            guard let sep = token.firstIndex(of: ":") else { continue }
            fields[String(token[..<sep])] = String(token[token.index(after: sep)...])
        }
        return ConnectedDevice(
            serial: tokens[0],
            state: tokens[1],
            model: fields["model"],
            product: fields["product"],
            transport: fields["usb"].map { "usb:\($0)" }
        )
    }
}

struct KnownDevice: Codable, Identifiable, Equatable {
    let serial: String
    var model: String?
    var alias: String
    var firstSeen: Date
    var lastSeen: Date

    var id: String { serial }
}
