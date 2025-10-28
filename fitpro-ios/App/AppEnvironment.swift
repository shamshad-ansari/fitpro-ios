import SwiftUI
import Foundation

/// Central dependency container (expand later with APIClient, Services, etc.)
struct AppEnvironment {
    var apiBaseURL: URL = API.baseURL
}

// MARK: - EnvironmentKey for AppEnvironment
private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppEnvironment = .init()
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
