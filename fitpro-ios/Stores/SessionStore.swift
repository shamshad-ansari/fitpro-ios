import Observation
import Foundation

@Observable
final class SessionStore {
    private(set) var isLoggedIn: Bool = false
    private(set) var userEmail: String? = nil
    private(set) var token: String? = nil

    private let svc = "fitpro.auth"
    private let acct = "access.token"

    init() {
        if let data = KeychainHelper.read(service: svc, account: acct),
           let saved = String(data: data, encoding: .utf8) {
            self.token = saved
            self.isLoggedIn = !saved.isEmpty
        }
    }

    func setLoggedIn(email: String, token: String) {
        self.userEmail = email
        self.token = token
        self.isLoggedIn = true
        KeychainHelper.save(Data(token.utf8), service: svc, account: acct)
    }

    func logout() {
        self.userEmail = nil
        self.token = nil
        self.isLoggedIn = false
        KeychainHelper.delete(service: svc, account: acct)
    }
}

