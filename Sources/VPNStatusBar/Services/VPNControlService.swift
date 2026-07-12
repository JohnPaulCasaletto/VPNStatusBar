import Foundation

struct VPNControlService: Sendable {
    enum Error: LocalizedError {
        case commandFailed(String)
        case wgQuickNotFound

        var errorDescription: String? {
            switch self {
            case let .commandFailed(message): message
            case .wgQuickNotFound:
                "wg-quick was not found. Install WireGuard with Homebrew first."
            }
        }
    }

    func setEnabled(_ enabled: Bool, configURL: URL) async throws {
        guard let wgQuickPath else { throw Error.wgQuickNotFound }

        try await Task.detached(priority: .userInitiated) {
            let command = enabled
                ? enableCommand(configURL: configURL, wgQuickPath: wgQuickPath)
                : disableCommand(configURL: configURL, wgQuickPath: wgQuickPath)
            try runPrivilegedCommand(command)
        }.value
    }

    private var wgQuickPath: String? {
        ["/opt/homebrew/bin/wg-quick", "/usr/local/bin/wg-quick"]
            .first(where: FileManager.default.isExecutableFile(atPath:))
    }

    private func enableCommand(configURL: URL, wgQuickPath: String) -> String {
        command(action: "up", configURL: configURL, wgQuickPath: wgQuickPath)
    }

    private func disableCommand(configURL: URL, wgQuickPath: String) -> String {
        command(action: "down", configURL: configURL, wgQuickPath: wgQuickPath)
    }

    private func command(action: String, configURL: URL, wgQuickPath: String) -> String {
        let executableDirectory = URL(fileURLWithPath: wgQuickPath)
            .deletingLastPathComponent()
            .path
        let path = [
            executableDirectory,
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ].joined(separator: ":")

        return "export PATH=\(shellQuote(path)); "
            + "\(shellQuote(wgQuickPath)) \(action) \(shellQuote(configURL.path))"
    }

    private func runPrivilegedCommand(_ command: String) throws {
        let process = Process()
        let errorPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = [
            "-e",
            "do shell script \(appleScriptLiteral(command)) with administrator privileges"
        ]
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw Error.commandFailed(cleanAppleScriptError(message))
        }
    }

    private func cleanAppleScriptError(_ message: String?) -> String {
        guard var message, !message.isEmpty else { return "The VPN command failed." }

        if let range = message.range(
            of: #"^\d+:\d+: execution error: "#,
            options: .regularExpression
        ) {
            message.removeSubrange(range)
        }

        return message
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func appleScriptLiteral(_ value: String) -> String {
        "\"" + value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }
}
