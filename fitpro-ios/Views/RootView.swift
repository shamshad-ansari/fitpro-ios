import SwiftUI

struct RootView: View {
    @Environment(SessionStore.self) private var session
    
    // State to track if onboarding has been completed for this session
    // This state would be persisted in a real application using AppStorage.
    @State private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                // Show Onboarding first
                OnboardingFlowView {
                    hasCompletedOnboarding = true
                }
            } else if session.isLoggedIn {
                MainFlowView()
            } else {
                AuthFlowView()
            }
        }
    }
}
