import Observation
import Foundation

/// App-wide auth/session state using Swift’s Observation framework (iOS 17+)
@Observable
final class SessionStore {
    private(set) var isLoggedIn: Bool = false
    private(set) var userEmail: String? = nil
    private var token: String? = nil   // later: Keychain-backed

    func setLoggedIn(email: String, token: String) {
        self.userEmail = email
        self.token = token
        self.isLoggedIn = true
    }

    func logout() {
        self.userEmail = nil
        self.token = nil
        self.isLoggedIn = false
    }
}
