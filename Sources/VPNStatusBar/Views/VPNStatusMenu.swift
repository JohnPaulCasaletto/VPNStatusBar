import AppKit
import SwiftUI

struct VPNStatusMenu: View {
    @ObservedObject var store: VPNStatusStore

    var body: some View {
        switch store.state {
        case .notConfigured:
            Label("Configuration required", systemImage: "questionmark.folder")
        case .checking:
            Text("Checking VPN…")
        case let .up(address):
            Label("VPN is up", systemImage: "checkmark.circle.fill")
            Text(address)
        case .down:
            Label("VPN is down", systemImage: "xmark.circle")
        case let .unavailable(message):
            Label("Status unavailable", systemImage: "exclamationmark.triangle")
            Text(message)
        }

        Divider()

        if let configFileName = store.configFileName {
            Label(shortMessage(configFileName), systemImage: "doc")
        } else {
            Label("No config selected", systemImage: "doc.badge.plus")
        }

        Button("Choose Config…") {
            store.chooseConfiguration()
        }

        Divider()

        if store.actionInProgress {
            Label("Changing VPN…", systemImage: "hourglass")
        } else {
            switch store.state {
            case .up:
                Button("Disable VPN") {
                    store.setVPNEnabled(false)
                }
            case .down, .notConfigured:
                Button("Enable VPN") {
                    store.setVPNEnabled(true)
                }
            case .checking, .unavailable:
                Button("Enable VPN") {}
                    .disabled(true)
            }
        }

        if let actionError = store.actionError {
            Label(shortMessage(actionError), systemImage: "exclamationmark.triangle")
        }

        Divider()

        Button("Refresh") {
            store.refresh()
        }
        .keyboardShortcut("r")

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func shortMessage(_ message: String) -> String {
        let singleLine = message.replacingOccurrences(of: "\n", with: " ")
        guard singleLine.count > 30 else { return singleLine }
        return String(singleLine.prefix(27)) + "..."
    }
}
