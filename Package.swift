// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "DeviceHog",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "DeviceHog", path: "Sources/DeviceHog")
    ]
)
