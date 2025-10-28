import Foundation

enum API {
    /// For Simulator + local backend on the same Mac, this is fine.
    /// For a real device, use your Mac’s LAN IP (e.g. http://192.168.1.23:4000)
    static let baseURL = URL(string: "http://localhost:4000")!
}
