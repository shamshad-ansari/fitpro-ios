import SwiftUI

enum AuthState {
    case login
    case signup
}

struct AuthFlowView: View {
    @State private var currentView: AuthState = .signup // Default to signup after onboarding

    var body: some View {
        NavigationStack {
            Group {
                switch currentView {
                case .login:
                    LoginView(onNavigateToSignup: {
                        withAnimation { currentView = .signup }
                    })
                case .signup:
                    SignUpView(onNavigateToLogin: {
                        withAnimation { currentView = .login }
                    })
                }
            }
        }
    }
}
