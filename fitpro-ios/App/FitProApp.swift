import SwiftUI

@main
struct FitProApp: App {
    @State private var session = SessionStore()

    // Pass a token provider that reads from Session (Keychain later)
    private var env: AppEnvironment {
        .init(apiBaseURL: API.baseURL, tokenProvider: { session.token })
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(\.appEnvironment, env)
        }
    }
}
