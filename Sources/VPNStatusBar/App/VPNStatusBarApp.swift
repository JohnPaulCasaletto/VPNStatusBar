import AppKit
import SwiftUI

@main
struct VPNStatusBarApp: App {
    @StateObject private var statusStore = VPNStatusStore()
    @StateObject private var launchAtLoginStore = LaunchAtLoginStore()

    var body: some Scene {
        MenuBarExtra {
            VPNStatusMenu(
                store: statusStore,
                launchAtLoginStore: launchAtLoginStore
            )
        } label: {
            Image(systemName: statusStore.state.systemImage)
                .font(.system(size: 16, weight: .medium))
                .accessibilityLabel(statusStore.state.accessibilityLabel)
        }
    }
}
