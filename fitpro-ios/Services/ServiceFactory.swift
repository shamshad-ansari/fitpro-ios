import Foundation

@MainActor
struct ServiceFactory {
    let env: AppEnvironment
    func authService() -> AuthService { AuthService(api: env.apiClient) }
}
