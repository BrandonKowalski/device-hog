import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class DeviceStore {
    private static let defaultsKey = "knownDevices"

    var connected: [ConnectedDevice] = []
    var known: [String: KnownDevice] = [:]
    var status: String?

    @ObservationIgnored private var tracker: AdbTracker?

    init() {
        load()
        let tracker = AdbTracker(
            onUpdate: { [weak self] devices in
                MainActor.assumeIsolated { self?.update(devices) }
            },
            onStatus: { [weak self] status in
                MainActor.assumeIsolated { self?.status = status }
            }
        )
        self.tracker = tracker
        tracker.start()
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.tracker?.stop() }
        }
    }

    var knownSorted: [KnownDevice] {
        known.values.sorted { $0.lastSeen > $1.lastSeen }
    }

    func name(for device: ConnectedDevice) -> String {
        if let alias = known[device.serial]?.alias, !alias.isEmpty { return alias }
        return device.displayModel ?? known[device.serial]?.model ?? device.serial
    }

    func isConnected(_ serial: String) -> Bool {
        connected.contains { $0.serial == serial }
    }

    func setAlias(_ alias: String, for serial: String) {
        guard var entry = known[serial] else { return }
        entry.alias = alias
        known[serial] = entry
        save()
    }

    func forget(_ serial: String) {
        known.removeValue(forKey: serial)
        save()
    }

    private func update(_ devices: [ConnectedDevice]) {
        connected = devices
        let now = Date()
        for device in devices {
            if var entry = known[device.serial] {
                entry.lastSeen = now
                if let model = device.displayModel { entry.model = model }
                known[device.serial] = entry
            } else {
                known[device.serial] = KnownDevice(
                    serial: device.serial,
                    model: device.displayModel,
                    alias: "",
                    firstSeen: now,
                    lastSeen: now
                )
            }
        }
        if !devices.isEmpty { save() }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let list = try? JSONDecoder().decode([KnownDevice].self, from: data) else { return }
        known = Dictionary(uniqueKeysWithValues: list.map { ($0.serial, $0) })
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(Array(known.values)) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
