import AppKit
import SwiftUI

@main
struct DeviceHogApp: App {
    @State private var store = DeviceStore()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(store: store)
        } label: {
            MenuBarLabel(count: store.connected.count)
        }
        .menuBarExtraStyle(.menu)

        Window("DeviceHog Settings", id: "settings") {
            SettingsView(store: store)
                .frame(minWidth: 640, minHeight: 320)
        }
        .windowResizability(.contentMinSize)
    }
}

struct MenuBarLabel: View {
    let count: Int

    var body: some View {
        Image(nsImage: count > 0 ? HogIcon.connected : HogIcon.idle)
        if count > 0 {
            Text("\(count)")
        }
    }
}

struct MenuContent: View {
    let store: DeviceStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if let status = store.status {
            Text(status)
            Divider()
        }

        if store.connected.isEmpty {
            Text("No devices connected")
        } else {
            Section("Connected Devices") {
                ForEach(store.connected) { device in
                    Menu {
                        actions(for: device)
                    } label: {
                        Image(systemName: icon(for: device))
                        Text(store.name(for: device))
                        Text(subtitle(for: device))
                    }
                }
            }
        }

        Divider()

        Button("Settings...") {
            openWindow(id: "settings")
            NSApp.activate()
        }
        .keyboardShortcut(",")

        Button("Quit DeviceHog") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    @ViewBuilder
    private func actions(for device: ConnectedDevice) -> some View {
        let name = store.name(for: device)
        let ready = device.state == "device"

        Button("Copy Serial") { DeviceActions.copySerial(device.serial) }
        Button("Rename...") { DeviceActions.rename(serial: device.serial, store: store) }

        if ready {
            Divider()
            Button("Take Screenshot") { DeviceActions.screenshot(serial: device.serial, name: name) }
            Button("Open Shell") { DeviceActions.openShell(serial: device.serial) }
            if DeviceActions.scrcpyPath != nil {
                Button("Mirror Screen") { DeviceActions.mirror(serial: device.serial, name: name) }
            }
            Divider()
            Button("Reboot") { DeviceActions.reboot(serial: device.serial) }
        }

        if device.isWireless {
            Button("Disconnect") { DeviceActions.disconnect(serial: device.serial) }
        }
    }

    private func icon(for device: ConnectedDevice) -> String {
        if device.state != "device" { return "exclamationmark.triangle" }
        return device.isWireless ? "wifi" : "cable.connector"
    }

    private func subtitle(for device: ConnectedDevice) -> String {
        var parts = [device.serial]
        if device.state != "device" { parts.append(device.state) }
        return parts.joined(separator: "  ")
    }
}
