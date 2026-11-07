import AppKit
import Foundation

enum DeviceActions {
    static var scrcpyPath: String? {
        ["/opt/homebrew/bin/scrcpy", "/usr/local/bin/scrcpy"]
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func copySerial(_ serial: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(serial, forType: .string)
    }

    @MainActor
    static func rename(serial: String, store: DeviceStore) {
        let alert = NSAlert()
        alert.messageText = "Rename Device"
        alert.informativeText = serial
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        field.stringValue = store.known[serial]?.alias ?? ""
        field.placeholderString = store.known[serial]?.model ?? "Alias"
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        NSApp.activate()
        if alert.runModal() == .alertFirstButtonReturn {
            store.setAlias(field.stringValue.trimmingCharacters(in: .whitespaces), for: serial)
        }
    }

    static func screenshot(serial: String, name: String) {
        guard let adb = AdbTracker.locateAdb() else { return }
        let stamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: ".")
        let safeName = name.replacingOccurrences(of: "/", with: "-")
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
        let url = desktop.appendingPathComponent("\(safeName) \(stamp).png")

        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.executableURL = adb
            proc.arguments = ["-s", serial, "exec-out", "screencap", "-p"]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = FileHandle.nullDevice
            do {
                try proc.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                proc.waitUntilExit()
                guard proc.terminationStatus == 0, !data.isEmpty else {
                    throw CocoaError(.fileWriteUnknown)
                }
                try data.write(to: url)
                DispatchQueue.main.async {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            } catch {
                DispatchQueue.main.async {
                    showError("Could not take a screenshot of \(name).")
                }
            }
        }
    }

    static func openShell(serial: String) {
        guard let adb = AdbTracker.locateAdb() else { return }
        let script = "#!/bin/zsh\nclear\nexec \(quote(adb.path)) -s \(quote(serial)) shell\n"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("devicehog-shell-\(UUID().uuidString).command")
        do {
            try script.write(to: url, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
            NSWorkspace.shared.open(url)
        } catch {
            showError("Could not open a shell for \(serial).")
        }
    }

    static func mirror(serial: String, name: String) {
        guard let scrcpy = scrcpyPath else { return }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: scrcpy)
        proc.arguments = ["-s", serial, "--window-title", name]
        var env = ProcessInfo.processInfo.environment
        if let adb = AdbTracker.locateAdb() { env["ADB"] = adb.path }
        proc.environment = env
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
        } catch {
            showError("Could not start scrcpy.")
        }
    }

    static func reboot(serial: String) {
        runAdb(["-s", serial, "reboot"])
    }

    static func disconnect(serial: String) {
        runAdb(["disconnect", serial])
    }

    private static func runAdb(_ arguments: [String]) {
        guard let adb = AdbTracker.locateAdb() else { return }
        let proc = Process()
        proc.executableURL = adb
        proc.arguments = arguments
        proc.standardOutput = FileHandle.nullDevice
        proc.standardError = FileHandle.nullDevice
        try? proc.run()
    }

    private static func quote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .warning
        NSApp.activate()
        alert.runModal()
    }
}
