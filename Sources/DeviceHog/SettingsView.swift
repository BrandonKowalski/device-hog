import SwiftUI

struct SettingsView: View {
    let store: DeviceStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if store.known.isEmpty {
                ContentUnavailableView(
                    "No devices seen yet",
                    systemImage: "iphone.gen3",
                    description: Text("Connect a device over adb and it will appear here.")
                )
            } else {
                Table(store.knownSorted) {
                    TableColumn("") { device in
                        Circle()
                            .fill(store.isConnected(device.serial) ? Color.green : Color.secondary.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .help(store.isConnected(device.serial) ? "Connected" : "Not connected")
                    }
                    .width(16)

                    TableColumn("Alias") { device in
                        AliasField(store: store, device: device)
                    }
                    .width(min: 140, ideal: 180)

                    TableColumn("Model") { device in
                        Text(device.model ?? "Unknown")
                            .foregroundStyle(device.model == nil ? .secondary : .primary)
                    }
                    .width(min: 100, ideal: 140)

                    TableColumn("Serial") { device in
                        Text(device.serial)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .width(min: 120, ideal: 160)

                    TableColumn("Last Seen") { device in
                        if store.isConnected(device.serial) {
                            Text("Now")
                        } else {
                            Text(device.lastSeen, format: .relative(presentation: .named))
                        }
                    }
                    .width(min: 80, ideal: 100)

                    TableColumn("") { device in
                        Button {
                            store.forget(device.serial)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Forget this device")
                    }
                    .width(24)
                }
            }
        }
    }
}

private struct AliasField: View {
    let store: DeviceStore
    let device: KnownDevice
    @State private var text = ""
    @State private var cancelled = false
    @FocusState private var focused: Bool

    var body: some View {
        TextField(device.model ?? "Alias", text: $text)
            .textFieldStyle(.plain)
            .focused($focused)
            .onAppear { text = device.alias }
            .onChange(of: device.alias) { _, newValue in
                if !focused { text = newValue }
            }
            .onSubmit { focused = false }
            .onExitCommand {
                cancelled = true
                text = device.alias
                focused = false
            }
            .onChange(of: focused) { _, isFocused in
                if isFocused {
                    cancelled = false
                } else if !cancelled {
                    commit()
                }
            }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        text = trimmed
        if trimmed != device.alias {
            store.setAlias(trimmed, for: device.serial)
        }
    }
}
