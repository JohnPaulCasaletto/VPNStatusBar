// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "VPNStatusBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "VPNStatusBar", targets: ["VPNStatusBar"])
    ],
    targets: [
        .executableTarget(name: "VPNStatusBar")
    ]
)
