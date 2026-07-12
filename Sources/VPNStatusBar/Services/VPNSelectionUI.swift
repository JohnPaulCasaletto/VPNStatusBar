import AppKit

@MainActor
struct VPNSelectionUI {
    func chooseService(
        from services: [ManagedVPNService],
        selectedID: String?
    ) -> ManagedVPNService? {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Choose a managed VPN"
        alert.informativeText = "Select the VPN that this app should monitor and control."

        let picker = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 340, height: 26))
        picker.addItems(withTitles: services.map { "\($0.name) — \($0.provider)" })
        if let selectedID, let index = services.firstIndex(where: { $0.id == selectedID }) {
            picker.selectItem(at: index)
        }
        alert.accessoryView = picker
        alert.addButton(withTitle: "Choose")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return services[picker.indexOfSelectedItem]
    }

    func showSelectionRequired() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Managed VPN required"
        alert.informativeText = "Choose a macOS-managed VPN before enabling it."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func showNoServices() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "No managed VPNs found"
        alert.informativeText = "Add a VPN in System Settings or a VPN app, then try again."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func showSelectionFailed(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn’t load managed VPNs"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    func showVPNCommandFailed(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn’t change the VPN"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Copy Error")

        if alert.runModal() == .alertSecondButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(message, forType: .string)
        }
    }
}
