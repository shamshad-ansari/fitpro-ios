import SwiftUI

struct SignUpView: View {
    var onNavigateToLogin: () -> Void
    
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    
    // State
    @State private var step = 1
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Form Data
    @State private var firstName = ""
    @State private var lastName = "" // Combined for backend 'name'
    @State private var email = ""
    @State private var password = ""
    @State private var acceptedTerms = false
    
    // Profile Data
    @State private var birthDate = Date()
    @State private var weightString = ""
    @State private var heightString = ""
    @State private var selectedGenderValue = ""
    let genderOptions = [
        ("male", "Male"),
        ("female", "Female"),
        ("non_binary", "Non-Binary"),
        ("prefer_not_to_say", "Prefer not to say")
    ]
    
    // Goal Data
    @State private var selectedGoal = "maintenance" // Default backend enum
    
    var body: some View {
        let factory = ServiceFactory(env: env)
        
        VStack {
            // Step content
            if step == 1 {
                credentialsStep
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else if step == 2 {
                profileStep
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else if step == 3 {
                goalsStep(factory: factory)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .animation(.spring, value: step)
        .background(Theme.Color.bg.ignoresSafeArea())
    }
    
    // MARK: - Step 1: Credentials
    
    private var credentialsStep: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l.rawValue) {
                header(subtitle: "Hey there,", title: "Create an Account")
                
                VStack(spacing: Theme.Spacing.m.rawValue) {
                    AuthInput(icon: "person", placeholder: "First Name", text: $firstName)
                    AuthInput(icon: "person", placeholder: "Last Name", text: $lastName)
                    AuthInput(icon: "envelope", placeholder: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    AuthSecureInput(icon: "lock", placeholder: "Password", text: $password)
                }
                
                Toggle(isOn: $acceptedTerms) {
                    Text("By continuing you accept our Privacy Policy and Terms of Use")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.subtle)
                }
                .toggleStyle(CheckboxToggleStyle()) // Custom toggle below
                
                if let msg = errorMessage {
                    Text(msg).font(Theme.Font.label).foregroundStyle(Theme.Color.danger)
                }
                
                PrimaryButton(title: "Register") {
                    validateStep1()
                }
                
                // Login Link
                HStack {
                    Text("Already have an account?")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.text)
                    Button("Login") { onNavigateToLogin() }
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.primaryAccent)
                }
                .padding(.bottom, Theme.Spacing.l.rawValue)
            }
            .padding(Theme.Spacing.l.rawValue)
        }
    }
    
    // MARK: - Step 2: Profile (Age/Weight/Height)
    
    private var profileStep: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l.rawValue) {
                
                // Illustration
                Image("Signup-Image")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 250)
                
                header(subtitle: "Let’s complete your profile", title: "It will help us to know more about you!")
                
                VStack(spacing: Theme.Spacing.m.rawValue) {
                    
                    // --- GENDER DROPDOWN (Updated) ---
                    Menu {
                        // Loop through our simple list
                        ForEach(genderOptions, id: \.0) { option in
                            Button(option.1) { // Display the Label
                                selectedGenderValue = option.0 // Save the Backend Value
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "person.2")
                                .foregroundStyle(Theme.Color.subtle)
                            
                            // Find the label for the selected value, or show "Choose Gender"
                            Text(genderOptions.first(where: { $0.0 == selectedGenderValue })?.1 ?? "Choose Gender")
                                .foregroundStyle(selectedGenderValue.isEmpty ? Theme.Color.subtle : Theme.Color.text)
                            
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundStyle(Theme.Color.subtle)
                        }
                        .padding(Theme.Spacing.m.rawValue)
                        .background(Theme.Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
                    }
                    
                    // --- DATE OF BIRTH ---
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(Theme.Color.subtle)
                        Text("Date of Birth")
                            .foregroundStyle(Theme.Color.subtle)
                        Spacer()
                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                            .labelsHidden()
                    }
                    .padding(Theme.Spacing.m.rawValue)
                    .background(Theme.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
                    
                    // --- WEIGHT ---
                    HStack(spacing: Theme.Spacing.m.rawValue) {
                        HStack {
                            Image(systemName: "scalemass")
                                .foregroundStyle(Theme.Color.subtle)
                            TextField("Your Weight", text: $weightString)
                                .keyboardType(.decimalPad)
                        }
                        .padding(Theme.Spacing.m.rawValue)
                        .background(Theme.Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
                        
                        unitBox(text: "KG")
                    }
                    
                    // --- HEIGHT ---
                    HStack(spacing: Theme.Spacing.m.rawValue) {
                        HStack {
                            Image(systemName: "ruler")
                                .foregroundStyle(Theme.Color.subtle)
                            TextField("Your Height", text: $heightString)
                                .keyboardType(.decimalPad)
                        }
                        .padding(Theme.Spacing.m.rawValue)
                        .background(Theme.Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
                        
                        unitBox(text: "CM")
                    }
                }
                
                // --- NEXT BUTTON ---
                Button(action: {
                    withAnimation { step = 3 }
                }) {
                    HStack {
                        Text("Next")
                            .font(Theme.Font.button)
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Color.primaryAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .shadow(color: Theme.Color.primaryAccent.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.top, Theme.Spacing.m.rawValue)
            }
            .padding(Theme.Spacing.l.rawValue)
        }
    }
    
    // MARK: - Step 3: Goals
    
    private func goalsStep(factory: ServiceFactory) -> some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.l.rawValue) {
                header(subtitle: "What is your goal?", title: "It will help us to choose a best program for you")
                
                // Goal Cards
                VStack(spacing: Theme.Spacing.m.rawValue) {
                    GoalCard(
                        title: "Improve Shape",
                        subtitle: "I have a low amount of body fat and need / want to build more muscle",
                        image: "figure.strengthtraining.traditional",
                        isSelected: selectedGoal == "muscle_gain"
                    ) { selectedGoal = "muscle_gain" }
                    
                    GoalCard(
                        title: "Lean & Tone",
                        subtitle: "I'm 'skinny fat'. look thin but have no shape. I want to add lean muscle",
                        image: "figure.jumprope",
                        isSelected: selectedGoal == "maintenance"
                    ) { selectedGoal = "maintenance" }
                    
                    GoalCard(
                        title: "Lose a Fat",
                        subtitle: "I have over 20 lbs to lose. I want to drop all this fat and gain muscle mass",
                        image: "figure.run",
                        isSelected: selectedGoal == "weight_loss"
                    ) { selectedGoal = "weight_loss" }
                }
                
                if let msg = errorMessage {
                    Text(msg).font(Theme.Font.label).foregroundStyle(Theme.Color.danger)
                }
                
                PrimaryButton(title: isLoading ? "Creating Account..." : "Confirm", isLoading: isLoading) {
                    Task { await registerAndLogin(factory: factory) }
                }
            }
            .padding(Theme.Spacing.l.rawValue)
        }
    }
    
    private func header(subtitle: String, title: String) -> some View {
        VStack(spacing: 4) {
            Text(subtitle)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.subtle)
            Text(title)
                .font(Theme.Font.h2)
                .foregroundStyle(Theme.Color.text)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Theme.Spacing.l.rawValue)
    }
    
    // MARK: - Logic
    
    private func validateStep1() {
        errorMessage = nil
        guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        guard acceptedTerms else {
            errorMessage = "You must accept the terms"
            return
        }
        withAnimation { step = 2 }
    }
    
    private func registerAndLogin(factory: ServiceFactory) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // 1. Calc Age
        let ageComponents = Calendar.current.dateComponents([.year], from: birthDate, to: Date())
        let age = ageComponents.year ?? 0
        guard age > 0 else {
            errorMessage = "Invalid date of birth"
            return
        }
        
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        
        do {
            // 2. Signup (Requires Name, Email, Age, Password)
            _ = try await factory.authService().signup(
                email: email,
                name: fullName,
                age: age,
                password: password
            )
            
            // 3. Login immediately to get token
            let loginResp = try await factory.authService().login(email: email, password: password)
            let token = loginResp.token
            
            // 4. Update Profile (Height, Weight, Goals)
            // We need to manually set the token in the session briefly or create a client with the token
            // Since we are inside the view, let's just use the session store to persist it, which AppEnvironment reads
            session.setLoggedIn(email: loginResp.user.email, token: token)
            
            // Now we can use the UserService from the factory (which reads from session/keychain if needed,
            // but since we just set it in SessionStore, the tokenProvider in AppEnvironment needs to see it.
            // Note: `session` is Observable, so `AppEnvironment`'s tokenProvider closure `{ session.token }` will see it.
            
            let weight = Double(weightString)
            let height = Double(heightString)
            
            let updatePayload = UsersService.UpdateMePayload(
                name: nil,
                fitnessLevel: nil, // Could map this later
                age: nil,
                heightCm: height,
                weightKg: weight,
                goals: .init(goalType: selectedGoal, targetWeightKg: nil, weeklyWorkouts: nil)
            )
            
            _ = try await factory.usersService().updateMe(updatePayload)
            
            // Done! RootView will see `session.isLoggedIn` and switch to MainFlowView
            
        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            errorMessage = "Registration failed. Please try again."
        }
    }
}

// MARK: - Supporting Views

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top) {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundStyle(configuration.isOn ? Theme.Color.primaryAccent : Theme.Color.subtle)
                .onTapGesture { configuration.isOn.toggle() }
            configuration.label
        }
    }
}

struct GoalCard: View {
    let title: String
    let subtitle: String
    let image: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.m.rawValue) {
                // Image or Illustration placeholder
                Image(systemName: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 60) // Tall aspect
                    .foregroundStyle(Theme.Color.primaryAccent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.Font.h4)
                        .foregroundStyle(Theme.Color.text)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.Color.subtle)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(Theme.Spacing.m.rawValue)
            .background(isSelected ? Theme.Color.primaryAccent.opacity(0.1) : Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue)
                    .stroke(isSelected ? Theme.Color.primaryAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Helper Views

private func unitBox(text: String) -> some View {
    RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue)
        .fill(Theme.Color.secondary) // This uses your Theme's purple color
        .frame(width: 48, height: 48) // Fixed square size to match the text field height
        .overlay(
            Text(text)
                .font(Theme.Font.label)
                .foregroundStyle(.white)
        )
}
