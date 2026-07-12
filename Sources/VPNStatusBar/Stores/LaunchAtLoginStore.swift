import Combine
import ServiceManagement

@MainActor
final class LaunchAtLoginStore: ObservableObject {
    @Published private(set) var isEnabled = false

    private let service: LaunchAtLoginService
    private let ui: LaunchAtLoginUI

    init(service: LaunchAtLoginService = LaunchAtLoginService()) {
        self.service = service
        self.ui = LaunchAtLoginUI()
        refresh()
    }

    func refresh() {
        isEnabled = service.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            try service.setEnabled(enabled)
        } catch {
            refresh()
            if enabled, service.status == .requiresApproval {
                showApprovalRequired()
            } else {
                ui.showError(error.localizedDescription)
            }
            return
        }

        refresh()
        if enabled, service.status == .requiresApproval {
            showApprovalRequired()
        }
    }

    private func showApprovalRequired() {
        if ui.showApprovalRequired() {
            service.openSystemSettings()
        }
    }
}
