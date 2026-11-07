# DeviceHog

<img src="Resources/devicehog.png" alt="DeviceHog" width="160" align="right">

I was tired of figuring out if my retro doodads were still connected over adb.

Device Hog is a macOS menu bar app that shows the adb devices connected to your Mac.

## Features

- Live list of connected devices in the menu bar, updated as devices connect and disconnect
- Give devices a friendly alias that is remembered across launches
- Per-device actions: copy serial, rename, take a screenshot, open a shell, mirror the screen with scrcpy, reboot, and disconnect wireless devices
- Settings window listing every device you have connected, with connection status and when it was last seen

## Requirements

- macOS 14 or later
- adb, from the Android SDK platform-tools or `brew install android-platform-tools`
- Optional: [scrcpy](https://github.com/Genymobile/scrcpy) for screen mirroring

DeviceHog looks for adb in `$ANDROID_HOME`, `$ANDROID_SDK_ROOT`, `~/Library/Android/sdk/platform-tools`, `/opt/homebrew/bin` and `/usr/local/bin`.

## Install

Download `DeviceHog.zip` from the [latest release](https://github.com/BrandonKowalski/device-hog/releases/latest), unzip it and move `DeviceHog.app` to `/Applications`.

The app is not signed with a Developer ID or notarized, so macOS will block it the first time. Either right-click the app and choose Open, or run:

```sh
xattr -dr com.apple.quarantine /Applications/DeviceHog.app
```

## Build from source

```sh
./build-app.sh
open build/DeviceHog.app
```

This builds a universal binary and writes the app to `build/DeviceHog.app`.

## License

[MIT](LICENSE)
