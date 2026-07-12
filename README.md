# VPNStatusBar

VPNStatusBar is a small macOS menu-bar app for monitoring and controlling a
WireGuard tunnel. It shows whether your tunnel is connected and lets you turn
it on or off without opening Terminal.

## Features

- Connected, disconnected, and not-configured menu-bar icons
- Enable or disable WireGuard from the menu bar
- Select any WireGuard `.conf` file
- Remembers the selected configuration between launches
- Runs entirely on your Mac

## Requirements

- macOS 13 or later
- A WireGuard configuration file
- The WireGuard command-line tools installed with Homebrew:

  ```sh
  brew install wireguard-tools
  ```

VPNStatusBar currently detects Homebrew installations of `wg-quick` in
`/opt/homebrew/bin` and `/usr/local/bin`.

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
2. Choose **Choose Config…** and select your WireGuard `.conf` file.
3. Choose **Enable VPN** or **Disable VPN**.
4. Approve the macOS administrator prompt.

The menu-bar icon indicates whether the configured WireGuard interface is up
or down. If you try to enable it before selecting a configuration, the app
will prompt you to choose one.

## Build from source

Building requires Swift 5.9 or later. Clone the repository and run:

```sh
./script/build_and_run.sh
```

This builds the Swift package, creates `dist/VPNStatusBar.app`, and launches
it. The build script uses the active macOS SDK reported by `xcrun`.

## Privacy and security

VPNStatusBar does not copy or upload your WireGuard configuration. The path to
the selected file is stored locally in macOS user defaults. Tunnel commands
run locally using `wg-quick`, and macOS displays its standard administrator
authorization prompt when the tunnel is changed.

## Current limitations

- `wg-quick` must be installed through Homebrew in one of the detected paths.
- The downloadable app is not yet Developer ID signed or notarized.
