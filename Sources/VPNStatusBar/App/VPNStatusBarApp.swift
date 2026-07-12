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
            Label(statusStore.state.accessibilityLabel, systemImage: statusStore.state.systemImage)
        }
    }
}
