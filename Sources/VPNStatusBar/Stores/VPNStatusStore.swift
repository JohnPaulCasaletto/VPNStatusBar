import Combine
import Foundation

enum VPNState: Equatable {
    case notConfigured
    case checking
    case up(address: String?)
    case down
    case unavailable(message: String)

    var systemImage: String {
        switch self {
        case .notConfigured: "questionmark.folder"
        case .checking: "bolt.horizontal"
        case .up: "bolt.horizontal.fill"
        case .down: "bolt.horizontal"
        case .unavailable: "exclamationmark.triangle"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .notConfigured: "VPN configuration required"
        case .checking: "Checking VPN status"
        case .up: "VPN up"
        case .down: "VPN down"
        case .unavailable: "VPN status unavailable"
        }
    }
}

@MainActor
final class VPNStatusStore: ObservableObject {
    @Published private(set) var state: VPNState = .checking
    @Published private(set) var actionInProgress = false
    @Published private(set) var actionError: String?
    @Published private(set) var selectedService: ManagedVPNService?

    private let service: VPNStatusService
    private let controlService: VPNControlService
    private let discovery: ManagedVPNServiceDiscovery
    private let selectionUI: VPNSelectionUI
    private let defaults: UserDefaults
    private var timer: Timer?
    private let serviceIDKey = "managedVPNServiceID"
    private let legacyConfigPathKey = "wireGuardConfigPath"

    var selectedServiceName: String? {
        selectedService?.name
    }

    init(
        service: VPNStatusService = VPNStatusService(),
        controlService: VPNControlService = VPNControlService(),
        defaults: UserDefaults = .standard
    ) {
        self.service = service
        self.controlService = controlService
        self.discovery = ManagedVPNServiceDiscovery()
        self.selectionUI = VPNSelectionUI()
        self.defaults = defaults
        loadSelection()
        refresh()
        let refreshTimer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
        RunLoop.main.add(refreshTimer, forMode: .common)
        timer = refreshTimer
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        state = service.currentStatus(serviceID: selectedService?.id)
    }

    func chooseService() {
        do {
            let services = try discovery.availableServices()
            guard !services.isEmpty else {
                selectionUI.showNoServices()
                return
            }
            guard let selected = selectionUI.chooseService(
                from: services,
                selectedID: selectedService?.id
            ) else { return }

            selectedService = selected
            defaults.set(selected.id, forKey: serviceIDKey)
            defaults.removeObject(forKey: legacyConfigPathKey)
            actionError = nil
            refresh()
        } catch {
            selectionUI.showSelectionFailed(error.localizedDescription)
        }
    }

    func setVPNEnabled(_ enabled: Bool) {
        guard !actionInProgress else { return }
        guard let selectedService else {
            selectionUI.showSelectionRequired()
            return
        }
        actionInProgress = true
        actionError = nil

        Task { [weak self, controlService] in
            do {
                try await controlService.setEnabled(enabled, serviceID: selectedService.id)
                await self?.refreshUntilSettled(enabled: enabled)
            } catch {
                let message = error.localizedDescription
                self?.actionError = message
                self?.selectionUI.showVPNCommandFailed(message)
            }
            self?.actionInProgress = false
        }
    }

    func showLastActionError() {
        guard let actionError else { return }
        selectionUI.showVPNCommandFailed(actionError)
    }

    private func loadSelection() {
        guard let services = try? discovery.availableServices() else { return }

        if let savedID = defaults.string(forKey: serviceIDKey),
           let savedService = services.first(where: { $0.id == savedID }) {
            selectedService = savedService
            return
        }

        guard let legacyPath = defaults.string(forKey: legacyConfigPathKey) else { return }
        let legacyName = URL(fileURLWithPath: legacyPath)
            .deletingPathExtension()
            .lastPathComponent
        guard let matchingService = services.first(where: { $0.name == legacyName }) else { return }

        selectedService = matchingService
        defaults.set(matchingService.id, forKey: serviceIDKey)
        defaults.removeObject(forKey: legacyConfigPathKey)
    }

    private func refreshUntilSettled(enabled: Bool) async {
        for _ in 0..<40 {
            refresh()
            if enabled, case .up = state { return }
            if !enabled, state == .down { return }
            try? await Task.sleep(for: .milliseconds(250))
        }
    }
}
