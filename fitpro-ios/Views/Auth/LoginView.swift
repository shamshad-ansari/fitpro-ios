import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    // Non-optional VM; we replace placeholder onAppear when env is available
    @State private var viewModel: LoginViewModel

    init() {
        // Placeholder dependencies; real ones injected onAppear
        _viewModel = State(initialValue: LoginViewModel(
            auth: AuthService(api: APIClient(baseURL: API.baseURL)),
            session: SessionStore()
        ))
    }

    var body: some View {
        let factory = ServiceFactory(env: env)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l.rawValue) {
                    Text("Sign in")
                        .font(Theme.Font.title)

                    // ⬇️ Use primitives so future redesign is easy
                    FormTextField(
                        label: "Email",
                        text: $viewModel.email,
                        keyboard: .emailAddress,
                        autocap: .never
                    )

                    FormSecureField(
                        label: "Password",
                        text: $viewModel.password
                    )

                    if let msg = viewModel.errorMessage, !msg.isEmpty {
                        Text(msg)
                            .font(Theme.Font.label)
                            .foregroundStyle(Theme.Color.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    PrimaryButton(title: viewModel.isLoading ? "Signing in…" : "Log In",
                                  isLoading: viewModel.isLoading) {
                        Task { await viewModel.login() }
                    }

                    // (Optional) secondary actions area
                    // Button("Forgot password?") { /* later */ }
                    //     .font(Theme.Font.label)
                    //     .foregroundStyle(Theme.Color.subtle)
                }
                .padding(.horizontal, Theme.Spacing.l.rawValue)
                .padding(.top, Theme.Spacing.xl.rawValue)
            }
            .background(Theme.Color.bg.ignoresSafeArea())
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // ✅ Safe: inject real dependencies once environment values are available
            viewModel = LoginViewModel(auth: factory.authService(), session: session)
        }
    }
}
