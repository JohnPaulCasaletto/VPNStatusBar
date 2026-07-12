import Foundation

struct VPNStatusService {
    func currentStatus(serviceID: String?) -> VPNState {
        guard let serviceID else { return .notConfigured }

        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        process.arguments = ["--nc", "status", serviceID]
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let status = output.split(whereSeparator: \Character.isNewline).first.map(String.init) ?? ""

            switch status {
            case "Connected": return .up(address: vpnAddress(in: output))
            case "Disconnected": return .down
            case "Connecting", "Disconnecting": return .checking
            case "No service": return .unavailable(message: "The selected managed VPN no longer exists.")
            default:
                return .unavailable(message: status.isEmpty ? "Couldn’t read VPN status." : status)
            }
        } catch {
            return .unavailable(message: error.localizedDescription)
        }
    }

    private func vpnAddress(in output: String) -> String? {
        let pattern = #"Addresses\s*:\s*<array>\s*\{\s*\d+\s*:\s*([0-9A-Fa-f:.%]+)"#
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(
                in: output,
                range: NSRange(output.startIndex..., in: output)
              ),
              let addressRange = Range(match.range(at: 1), in: output) else { return nil }
        return String(output[addressRange])
    }
}
