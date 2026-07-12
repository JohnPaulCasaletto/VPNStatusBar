import Foundation

struct ManagedVPNService: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let provider: String
}

struct ManagedVPNServiceDiscovery {
    enum Error: LocalizedError {
        case listingFailed(String)

        var errorDescription: String? {
            switch self {
            case let .listingFailed(message): message
            }
        }
    }

    func availableServices() throws -> [ManagedVPNService] {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        process.arguments = ["--nc", "list"]
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw Error.listingFailed(message?.isEmpty == false ? message! : "Couldn’t list managed VPNs.")
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.split(whereSeparator: \Character.isNewline).compactMap(parseService)
    }

    private func parseService(_ line: Substring) -> ManagedVPNService? {
        let pattern = #"^\*?\s+\([^)]+\)\s+([0-9A-Fa-f-]+)\s+VPN\s+\(([^)]+)\)\s+\"(.*)\"\s+\[VPN:"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return nil }
        let value = String(line)
        let range = NSRange(value.startIndex..., in: value)
        guard let match = expression.firstMatch(in: value, range: range), match.numberOfRanges == 4,
              let idRange = Range(match.range(at: 1), in: value),
              let providerRange = Range(match.range(at: 2), in: value),
              let nameRange = Range(match.range(at: 3), in: value) else { return nil }

        return ManagedVPNService(
            id: String(value[idRange]),
            name: String(value[nameRange]),
            provider: String(value[providerRange])
        )
    }
}
