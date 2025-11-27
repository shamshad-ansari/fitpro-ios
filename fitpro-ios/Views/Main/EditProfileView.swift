import SwiftUI

struct EditProfileView: View {
    let initial: User
    let onSave: (
        String?,                          // name
        String?,                          // fitnessLevel
        Int?,                             // age
        Double?,                          // heightCm
        Double?,                          // weightKg
        UsersService.UpdateMePayload.GoalsPayload? // goals
    ) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var fitnessLevel: String
    @State private var ageText: String             // ← NEW
    @State private var heightText: String
    @State private var weightText: String
    @State private var enableGoals: Bool           // ← toggle to show/hide goals editor

    // goals fields
    @State private var goalType: String
    @State private var targetWeightText: String
    @State private var weeklyWorkoutsText: String

    init(initial: User, onSave: @escaping (
        String?, String?, Int?, Double?, Double?, UsersService.UpdateMePayload.GoalsPayload?
    ) -> Void) {
        self.initial = initial
        self.onSave = onSave
        _name = State(initialValue: initial.name)
        _fitnessLevel = State(initialValue: initial.fitnessLevel ?? "beginner")
        _ageText = State(initialValue: initial.age.map(String.init) ?? "")
        _heightText = State(initialValue: initial.heightCm.map { String($0) } ?? "")
        _weightText = State(initialValue: initial.weightKg.map { String($0) } ?? "")
        _enableGoals = State(initialValue: initial.goals != nil)

        _goalType = State(initialValue: initial.goals?.goalType ?? "maintenance")
        _targetWeightText = State(initialValue: initial.goals?.targetWeightKg.map { String($0) } ?? "")
        _weeklyWorkoutsText = State(initialValue: initial.goals?.weeklyWorkouts.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Name", text: $name)
                }
                Section("Fitness") {
                    Picker("Level", selection: $fitnessLevel) {
                        Text("Beginner").tag("beginner")
                        Text("Intermediate").tag("intermediate")
                        Text("Advanced").tag("advanced")
                    }
                    TextField("Age", text: $ageText)
                        .keyboardType(.numberPad)
                    TextField("Height (cm)", text: $heightText)
                        .keyboardType(.decimalPad)
                    TextField("Weight (kg)", text: $weightText)
                        .keyboardType(.decimalPad)
                }
                Section {
                    Toggle("Set Goals", isOn: $enableGoals)
                }
                if enableGoals {
                    Section("Goals") {
                        Picker("Goal Type", selection: $goalType) {
                            Text("Weight Loss").tag("weight_loss")
                            Text("Muscle Gain").tag("muscle_gain")
                            Text("Maintenance").tag("maintenance")
                        }
                        TextField("Target Weight (kg)", text: $targetWeightText)
                            .keyboardType(.decimalPad)
                        TextField("Weekly Workouts", text: $weeklyWorkoutsText)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        // Parse numeric fields safely
                        let age = Int(ageText)
                        let height = Double(heightText)
                        let weight = Double(weightText)

                        let goalsPayload: UsersService.UpdateMePayload.GoalsPayload? = enableGoals
                        ? .init(
                            goalType: goalType.nilIfEmpty,
                            targetWeightKg: Double(targetWeightText),
                            weeklyWorkouts: Int(weeklyWorkoutsText)
                          )
                        : nil

                        onSave(
                            name.nilIfEmpty,
                            fitnessLevel.nilIfEmpty,
                            age,
                            height,
                            weight,
                            goalsPayload
                        )
                    }
                    .bold()
                }
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
