import Darwin
import Foundation

struct VPNStatusService {
    func currentStatus(configURL: URL?) -> VPNState {
        guard let configURL else { return .notConfigured }

        do {
            let contents = try String(contentsOf: configURL, encoding: .utf8)
            let tunnelAddresses = try WireGuardConfig.interfaceAddresses(in: contents)
            let activeAddresses = try activeInterfaceAddresses()
            let matches = tunnelAddresses.intersection(activeAddresses)

            if let address = matches.sorted().first {
                return .up(address: address)
            }

            return .down
        } catch {
            return .unavailable(message: error.localizedDescription)
        }
    }

    private func activeInterfaceAddresses() throws -> Set<String> {
        var firstAddress: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&firstAddress) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
        defer { freeifaddrs(firstAddress) }

        var addresses = Set<String>()
        var current = firstAddress

        while let interface = current?.pointee {
            defer { current = interface.ifa_next }
            guard let socketAddress = interface.ifa_addr else { continue }

            let family = Int32(socketAddress.pointee.sa_family)
            guard family == AF_INET || family == AF_INET6 else { continue }

            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let length: socklen_t = family == AF_INET
                ? socklen_t(MemoryLayout<sockaddr_in>.size)
                : socklen_t(MemoryLayout<sockaddr_in6>.size)

            if getnameinfo(socketAddress, length, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                addresses.insert(String(cString: host).split(separator: "%", maxSplits: 1).first.map(String.init) ?? "")
            }
        }

        return addresses
    }
}
