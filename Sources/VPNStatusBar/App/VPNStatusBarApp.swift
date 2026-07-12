import AppKit
import SwiftUI

@main
struct VPNStatusBarApp: App {
    @StateObject private var statusStore = VPNStatusStore()

    var body: some Scene {
        MenuBarExtra {
            VPNStatusMenu(store: statusStore)
        } label: {
            Label(statusStore.state.accessibilityLabel, systemImage: statusStore.state.systemImage)
        }
    }
}
