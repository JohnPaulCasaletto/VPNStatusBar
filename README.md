# VPNStatusBar

<img src="Resources/AppIcon.png" alt="VPNStatusBar app icon" width="160">

VPNStatusBar is a small macOS menu-bar app for monitoring and controlling a
macOS-managed VPN. It shows whether your VPN is connected and lets you turn
it on or off without opening System Settings.

## Demo

![VPNStatusBar connecting and disconnecting a managed VPN](Resources/VPNStatusBarDemo.gif)

[View the MP4 version](Resources/VPNStatusBarDemo.mp4)

## Features

- Connected, disconnected, and not-configured menu-bar icons
- Enable or disable a macOS-managed VPN from the menu bar
- Select from the VPNs already registered with macOS
- Remembers the selected VPN between launches
- No administrator password required for normal VPN toggles
- Optional launch at login
- Runs entirely on your Mac

## Requirements

- macOS 13 or later
- A VPN registered with macOS through System Settings or a VPN app

## Download and install

1. Download `VPNStatusBar.zip` from the
   [latest GitHub Release](../../releases/latest).
2. Unzip it and move `VPNStatusBar.app` to your Applications folder.
3. Open VPNStatusBar. It runs in the menu bar and does not show a Dock icon.

### Gatekeeper warning

The current release is not signed or notarized with an Apple Developer ID, so
macOS may prevent it from opening after download. If that happens:

1. Try to open VPNStatusBar once.
2. Open **System Settings → Privacy & Security**.
3. Find the message about VPNStatusBar and click **Open Anyway**.

Only bypass Gatekeeper if you downloaded the app from this repository and are
comfortable running it. Developer ID signing and notarization are planned for
a future release.

## Usage

1. Click the VPNStatusBar icon in the menu bar.
2. Choose **Choose VPN…** and select a managed VPN.
3. Choose **Enable VPN** or **Disable VPN**.

The menu-bar icon reflects the connection state reported by macOS. If you try
to enable it before selecting a VPN, the app will prompt you to choose one.

## Build from source

Building requires Swift 5.9 or later. Clone the repository and run:

```sh
./script/build_and_run.sh
```

This builds the Swift package, creates `dist/VPNStatusBar.app`, and launches
it. The build script uses the active macOS SDK reported by `xcrun`.

## Privacy and security

VPNStatusBar stores the selected managed VPN's system identifier locally in
macOS user defaults. It does not copy or upload VPN configuration or keys.
Connection changes are sent to macOS using the built-in `scutil` command.

## Current limitations

- The downloadable app is not yet Developer ID signed or notarized.
