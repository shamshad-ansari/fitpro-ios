import SwiftUI

struct LoginView: View {
    var onNavigateToSignup: () -> Void
    
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        let factory = ServiceFactory(env: env)
        
        ScrollView {
            VStack(spacing: Theme.Spacing.l.rawValue) {
                
                // Header
                VStack(spacing: Theme.Spacing.xs.rawValue) {
                    Text("Hey there,")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.subtle)
                    Text("Welcome Back")
                        .font(Theme.Font.h1)
                        .foregroundStyle(Theme.Color.text)
                }
                .padding(.top, Theme.Spacing.xl.rawValue)
                
                // Form
                VStack(spacing: Theme.Spacing.m.rawValue) {
                    AuthInput(icon: "envelope", placeholder: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    AuthSecureInput(icon: "lock", placeholder: "Password", text: $password)
                }
                .padding(.top, Theme.Spacing.l.rawValue)
                
                // Forgot Password
                Button("Forgot your password?") {
                    // TODO: Handle forgot password
                }
                .font(Theme.Font.label)
                .foregroundStyle(Theme.Color.subtle)
                .frame(maxWidth: .infinity, alignment: .center) // Centered as per visual
                
                // Error
                if let err = errorMessage {
                    Text(err)
                        .font(Theme.Font.label)
                        .foregroundStyle(Theme.Color.danger)
                }
                
                // Login Button
                PrimaryButton(title: "Login", isLoading: isLoading) {
                    Task { await login(auth: factory.authService()) }
                }
                .padding(.top, Theme.Spacing.xl.rawValue)
                
                Spacer()
                
                // Register Link
                HStack {
                    Text("Don’t have an account yet?")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.text)
                    Button("Register") {
                        onNavigateToSignup()
                    }
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.primaryAccent) // Purple/Blue accent
                }
                .padding(.bottom, Theme.Spacing.l.rawValue)
            }
            .padding(.horizontal, Theme.Spacing.l.rawValue)
        }
        .background(Theme.Color.bg.ignoresSafeArea())
    }
    
    private func login(auth: AuthService) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let resp = try await auth.login(email: email, password: password)
            session.setLoggedIn(email: resp.user.email, token: resp.token)
        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            errorMessage = "Something went wrong."
        }
    }
}

// MARK: - Reusable Auth Inputs (Internal to Auth views)

struct AuthInput: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.s.rawValue) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Color.subtle)
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .font(Theme.Font.body)
        }
        .padding(Theme.Spacing.m.rawValue)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
    }
}

struct AuthSecureInput: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var show = false
    
    var body: some View {
        HStack(spacing: Theme.Spacing.s.rawValue) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Color.subtle)
                .frame(width: 20)
            
            if show {
                TextField(placeholder, text: $text)
                    .font(Theme.Font.body)
            } else {
                SecureField(placeholder, text: $text)
                    .font(Theme.Font.body)
            }
            
            Button { show.toggle() } label: {
                Image(systemName: show ? "eye.slash" : "eye")
                    .foregroundStyle(Theme.Color.subtle)
            }
        }
        .padding(Theme.Spacing.m.rawValue)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
    }
}
