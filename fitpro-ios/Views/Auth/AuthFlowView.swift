import SwiftUI

struct AuthFlowView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("FitPro")
                    .font(.largeTitle).bold()

                Text("Welcome! Please sign in to continue.")
                    .foregroundStyle(.secondary)

                // TEMP: we’ll replace with real Login in Milestone 1
                Button("Quick Login (Simulated)") {
                    session.setLoggedIn(email: "sam@fitpro.app", token: "fake-token")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding()
            .navigationTitle("Sign In")
        }
    }
}
