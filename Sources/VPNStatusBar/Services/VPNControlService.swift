import Foundation

struct VPNControlService: Sendable {
    enum Error: LocalizedError {
        case commandFailed(String)

        var errorDescription: String? {
            switch self {
            case let .commandFailed(message): message
            }
        }
    }

    func setEnabled(_ enabled: Bool, serviceID: String) async throws {
        try await Task.detached(priority: .userInitiated) {
            try runCommand(enabled ? "start" : "stop", serviceID: serviceID)
        }.value
    }

    private func runCommand(_ action: String, serviceID: String) throws {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        process.arguments = ["--nc", action, serviceID]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let data = errorData.isEmpty ? outputData : errorData
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw Error.commandFailed(message?.isEmpty == false ? message! : "The VPN command failed.")
        }
    }
}
