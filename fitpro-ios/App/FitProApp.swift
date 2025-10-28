import SwiftUI

@main
struct FitProApp: App {
    // New Observation framework (iOS 17+)
    @State private var session = SessionStore()
    private let env = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)                 // inject SessionStore
                .environment(\.appEnvironment, env)  // inject AppEnvironment via custom key
        }
    }
}
