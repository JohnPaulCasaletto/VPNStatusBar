import Combine
import Foundation

enum VPNState: Equatable {
    case notConfigured
    case checking
    case up(address: String)
    case down
    case unavailable(message: String)

    var systemImage: String {
        switch self {
        case .notConfigured: "questionmark.folder"
        case .checking: "ellipsis.circle"
        case .up: "lock.shield.fill"
        case .down: "lock.slash"
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
    @Published private(set) var configURL: URL?

    private let service: VPNStatusService
    private let controlService: VPNControlService
    private let configurationUI: VPNConfigurationUI
    private let defaults: UserDefaults
    private var timer: Timer?
    private let configPathKey = "wireGuardConfigPath"

    var configFileName: String? {
        configURL?.lastPathComponent
    }

    init(
        service: VPNStatusService = VPNStatusService(),
        controlService: VPNControlService = VPNControlService(),
        defaults: UserDefaults = .standard
    ) {
        self.service = service
        self.controlService = controlService
        self.configurationUI = VPNConfigurationUI()
        self.defaults = defaults
        if let path = defaults.string(forKey: configPathKey) {
            configURL = URL(fileURLWithPath: path)
        }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        state = service.currentStatus(configURL: configURL)
    }

    func chooseConfiguration() {
        guard let selectedURL = configurationUI.chooseConfig(startingAt: configURL) else { return }

        do {
            let contents = try String(contentsOf: selectedURL, encoding: .utf8)
            _ = try WireGuardConfig.interfaceAddresses(in: contents)
            configURL = selectedURL
            defaults.set(selectedURL.path, forKey: configPathKey)
            actionError = nil
            refresh()
        } catch {
            configurationUI.showInvalidConfiguration(error.localizedDescription)
        }
    }

    func setVPNEnabled(_ enabled: Bool) {
        guard !actionInProgress else { return }
        guard let configURL else {
            configurationUI.showConfigurationRequired()
            return
        }
        actionInProgress = true
        actionError = nil

        Task { [weak self, controlService] in
            do {
                try await controlService.setEnabled(enabled, configURL: configURL)
                self?.refresh()
            } catch {
                self?.actionError = error.localizedDescription
            }
            self?.actionInProgress = false
        }
    }
}
