import AppKit

@MainActor
struct LaunchAtLoginUI {
    func showApprovalRequired() -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Allow VPNStatusBar at login"
        alert.informativeText = "Enable VPNStatusBar in System Settings under General → Login Items."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")
        return alert.runModal() == .alertFirstButtonReturn
    }

    func showError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Couldn’t change login setting"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
