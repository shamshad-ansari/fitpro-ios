import SwiftUI

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    // Make the view model non-optional
    @State private var viewModel: LoginViewModel

    // Custom initializer so we can inject dependencies
    init() {
        // Assigning a dummy placeholder first; actual injection happens later using onAppear
        _viewModel = State(initialValue: LoginViewModel(
            auth: AuthService(api: APIClient(baseURL: API.baseURL)),
            session: SessionStore()
        ))
    }

    var body: some View {
        // Create the real instance using the environment
        let factory = ServiceFactory(env: env)

        // Replace placeholder with correct one when view appears
        Form {
            Section(header: Text("Sign in")) {
                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $viewModel.password)
            }

            if let msg = viewModel.errorMessage {
                Text(msg).foregroundStyle(.red)
            }

            Button {
                Task { await viewModel.login() }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Log In")
                }
            }
            .disabled(viewModel.isLoading)
        }
        .navigationTitle("Login")
        .onAppear {
            // inject real dependencies once environment values are available
            viewModel = LoginViewModel(auth: factory.authService(), session: session)
        }
    }
}
