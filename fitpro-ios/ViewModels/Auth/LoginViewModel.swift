import Foundation

@MainActor
@Observable
final class LoginViewModel {
    var email: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private let auth: AuthService
    private let session: SessionStore

    init(auth: AuthService, session: SessionStore) {
        self.auth = auth
        self.session = session
    }

    func login() async {
        errorMessage = nil
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required."
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let resp = try await auth.login(email: email, password: password)
            session.setLoggedIn(email: resp.user.email, token: resp.token)
        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
    }
}
