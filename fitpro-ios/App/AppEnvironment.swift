import SwiftUI
import Foundation

struct AppEnvironment {
    var apiBaseURL: URL = API.baseURL
    // NEW: concrete API client (tokenProvider filled later from Session/Keychain)
    var apiClient: APIClient

    init(apiBaseURL: URL = API.baseURL, tokenProvider: @escaping () -> String? = { nil }) {
        self.apiBaseURL = apiBaseURL
        self.apiClient = APIClient(baseURL: apiBaseURL, tokenProvider: tokenProvider)
    }
}

// EnvironmentKey remains the same as before
private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment = .init()
}
extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
