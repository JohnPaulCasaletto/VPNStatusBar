import Foundation

struct WireGuardConfig {
    enum Error: LocalizedError {
        case noInterfaceAddress

        var errorDescription: String? {
            "No Address entry was found in the WireGuard config."
        }
    }

    static func interfaceAddresses(in contents: String) throws -> Set<String> {
        var isInterfaceSection = false
        var addresses = Set<String>()

        for rawLine in contents.split(whereSeparator: \Character.isNewline) {
            let line = rawLine
                .split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)[0]
                .trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("[") && line.hasSuffix("]") {
                isInterfaceSection = line.caseInsensitiveCompare("[Interface]") == .orderedSame
                continue
            }

            guard isInterfaceSection,
                  let separator = line.firstIndex(of: "=") else { continue }

            let key = line[..<separator].trimmingCharacters(in: .whitespaces)
            guard key.caseInsensitiveCompare("Address") == .orderedSame else { continue }

            let value = line[line.index(after: separator)...]
            for addressWithPrefix in value.split(separator: ",") {
                let address = addressWithPrefix
                    .split(separator: "/", maxSplits: 1)[0]
                    .trimmingCharacters(in: .whitespaces)
                if !address.isEmpty {
                    addresses.insert(address)
                }
            }
        }

        guard !addresses.isEmpty else { throw Error.noInterfaceAddress }
        return addresses
    }
}
