import Foundation

final class AdbTracker {
    private let onUpdate: ([ConnectedDevice]) -> Void
    private let onStatus: (String?) -> Void
    private var process: Process?
    private var buffer = Data()
    private var stopped = false

    init(onUpdate: @escaping ([ConnectedDevice]) -> Void, onStatus: @escaping (String?) -> Void) {
        self.onUpdate = onUpdate
        self.onStatus = onStatus
    }

    static func locateAdb() -> URL? {
        let env = ProcessInfo.processInfo.environment
        var candidates: [String] = []
        for key in ["ANDROID_HOME", "ANDROID_SDK_ROOT"] {
            if let root = env[key] { candidates.append("\(root)/platform-tools/adb") }
        }
        candidates.append(NSHomeDirectory() + "/Library/Android/sdk/platform-tools/adb")
        candidates.append("/opt/homebrew/bin/adb")
        candidates.append("/usr/local/bin/adb")
        if let path = env["PATH"] {
            candidates.append(contentsOf: path.split(separator: ":").map { "\($0)/adb" })
        }
        return candidates
            .first { FileManager.default.isExecutableFile(atPath: $0) }
            .map { URL(fileURLWithPath: $0) }
    }

    func start() {
        stopped = false
        launch()
    }

    func stop() {
        stopped = true
        process?.terminationHandler = nil
        process?.terminate()
        process = nil
    }

    private func launch() {
        guard !stopped else { return }
        guard let adb = Self.locateAdb() else {
            onStatus("adb not found")
            onUpdate([])
            scheduleRestart()
            return
        }

        let proc = Process()
        proc.executableURL = adb
        proc.arguments = ["track-devices", "-l"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        buffer = Data()

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            DispatchQueue.main.async {
                guard let self else { return }
                if chunk.isEmpty {
                    handle.readabilityHandler = nil
                } else {
                    self.consume(chunk)
                }
            }
        }

        proc.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, !self.stopped else { return }
                self.onStatus("adb server disconnected, retrying")
                self.onUpdate([])
                self.scheduleRestart()
            }
        }

        do {
            try proc.run()
            process = proc
            onStatus(nil)
        } catch {
            onStatus("Failed to start adb: \(error.localizedDescription)")
            scheduleRestart()
        }
    }

    private func scheduleRestart() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.launch()
        }
    }

    private func consume(_ chunk: Data) {
        buffer.append(chunk)
        while buffer.count >= 4 {
            guard let header = String(data: buffer.prefix(4), encoding: .ascii),
                  let length = Int(header, radix: 16) else {
                buffer.removeAll()
                return
            }
            guard buffer.count >= 4 + length else { return }
            let payload = buffer.subdata(in: buffer.startIndex + 4 ..< buffer.startIndex + 4 + length)
            buffer.removeSubrange(buffer.startIndex ..< buffer.startIndex + 4 + length)
            let text = String(decoding: payload, as: UTF8.self)
            let devices = text
                .split(separator: "\n")
                .compactMap { ConnectedDevice.parse(line: String($0)) }
            onUpdate(devices)
        }
    }
}
