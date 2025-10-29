import SwiftUI

struct AuthFlowView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Log In") { LoginView() }
                // SignupView can be added next, similar to Login
            }
            .navigationTitle("Welcome to FitPro")
        }
    }
}
