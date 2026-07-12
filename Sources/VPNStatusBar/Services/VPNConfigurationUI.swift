import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
struct VPNConfigurationUI {
    func chooseConfig(startingAt currentURL: URL?) -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose WireGuard Configuration"
        panel.message = "Select the WireGuard .conf file this app should control."
        panel.prompt = "Choose"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType(filenameExtension: "conf") ?? .data]
        panel.directoryURL = currentURL?.deletingLastPathComponent()
        return panel.runModal() == .OK ? panel.url : nil
    }

    func showConfigurationRequired() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "WireGuard configuration required"
        alert.informativeText = "Choose a WireGuard configuration file before enabling the VPN."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func showInvalidConfiguration(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Invalid WireGuard configuration"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
