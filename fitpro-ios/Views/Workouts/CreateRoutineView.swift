import SwiftUI

struct CreateRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let service: WorkoutsService
    private let routineToEdit: WorkoutRoutine? // <-- Retained for Edit Mode
    let onSave: (WorkoutRoutine) -> Void       // Renamed from onCreated for clarity

    // Routine Info
    @State private var name: String = ""
    @State private var notes: String = ""

    // Dynamic List
    @State private var exercises: [ExerciseRow] = [ExerciseRow()]

    @State private var isSaving = false
    @State private var errorMessage: String?

    // MARK: - Local Data Models
    struct ExerciseRow: Identifiable {
        let id = UUID()
        var name: String = ""
        var sets: [SetRow] = [SetRow(index: 1)]
    }

    struct SetRow: Identifiable {
        let id = UUID()
        var index: Int
        var weightText: String = ""
        var repsText: String = ""
    }

    // Updated Init to handle Edit Mode + Pre-filling
    init(service: WorkoutsService, routineToEdit: WorkoutRoutine? = nil, onSave: @escaping (WorkoutRoutine) -> Void) {
        self.service = service
        self.routineToEdit = routineToEdit
        self.onSave = onSave
        
        // Pre-fill logic if editing
        if let r = routineToEdit {
            _name = State(initialValue: r.name)
            _notes = State(initialValue: r.notes ?? "")
            
            let rows = r.exercises.map { ex in
                // Expand "defaultSets" into actual SetRows for the UI
                let count = max(ex.defaultSets ?? 1, 1)
                let weight = ex.defaultWeightKg.map { String(Int($0)) } ?? ""
                let reps = ex.defaultReps.map(String.init) ?? ""
                
                let setRows = (1...count).map { i in
                    SetRow(index: i, weightText: weight, repsText: reps)
                }
                
                return ExerciseRow(name: ex.name, sets: setRows)
            }
            
            _exercises = State(initialValue: rows.isEmpty ? [ExerciseRow()] : rows)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.bg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.l.rawValue) {
                        
                        // 1. Routine Header
                        VStack(spacing: Theme.Spacing.m.rawValue) {
                            TextField("Routine Name", text: $name)
                                .font(Theme.Font.h2)
                                .foregroundStyle(Theme.Color.text)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 8)
                                .background(Theme.Color.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            TextField("Notes (Optional)", text: $notes)
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.Color.subtle)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)

                        // 2. Exercises List
                        VStack(spacing: Theme.Spacing.l.rawValue) {
                            ForEach($exercises) { $exercise in
                                exerciseCard(for: $exercise)
                            }
                        }
                        
                        // 3. Add Exercise Button
                        Button {
                            withAnimation {
                                exercises.append(ExerciseRow())
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Exercise")
                            }
                            .font(Theme.Font.button)
                            .foregroundStyle(Theme.Color.primaryAccent)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.Color.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 60)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle(routineToEdit == nil ? "New Routine" : "Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Theme.Color.subtle)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { Task { await save() } }
                        .bold()
                        .foregroundStyle(Theme.Color.primaryAccent)
                        .disabled(isSaving)
                }
            }
            .overlay(alignment: .top) {
                if let msg = errorMessage {
                    Text(msg)
                        .font(Theme.Font.label)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Theme.Color.danger)
                        .clipShape(Capsule())
                        .padding(.top)
                }
            }
        }
    }
    
    // MARK: - Exercise Card
    
    private func exerciseCard(for exercise: Binding<ExerciseRow>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Header: Name & Trash
            HStack {
                TextField("Exercise Name", text: exercise.name)
                    .font(Theme.Font.h3)
                    .foregroundStyle(Theme.Color.text)
                
                Spacer()
                
                Button {
                    removeExercise(id: exercise.id)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(Theme.Color.subtle)
                }
            }

            // Headers
            HStack {
                Text("SET").frame(width: 40, alignment: .leading)
                Text("KG").frame(maxWidth: .infinity)
                Text("REPS").frame(maxWidth: .infinity)
            }
            .font(.caption)
            .foregroundStyle(Theme.Color.subtle)

            // Rows
            VStack(spacing: 8) {
                ForEach(exercise.sets) { $setRow in
                    HStack(spacing: 8) {
                        Text("\(setRow.index)")
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.subtle)
                            .frame(width: 40, alignment: .leading)

                        TextField("-", text: $setRow.weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                            .background(Theme.Color.bg)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(Theme.Color.text)
                            .frame(maxWidth: .infinity)

                        TextField("-", text: $setRow.repsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                            .background(Theme.Color.bg)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(Theme.Color.text)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Add Set Button
            Button {
                let nextIndex = exercise.sets.count + 1
                let lastWeight = exercise.sets.wrappedValue.last?.weightText ?? ""
                let lastReps = exercise.sets.wrappedValue.last?.repsText ?? ""
                
                withAnimation {
                    exercise.sets.wrappedValue.append(
                        SetRow(index: nextIndex, weightText: lastWeight, repsText: lastReps)
                    )
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Add Set")
                }
                .font(Theme.Font.label)
                .foregroundStyle(Theme.Color.primaryAccent)
            }
            .padding(.top, 4)
        }
        .padding(Theme.Spacing.m.rawValue)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    // MARK: - Logic
    
    private func removeExercise(id: UUID) {
        if let idx = exercises.firstIndex(where: { $0.id == id }) {
            withAnimation { exercises.remove(at: idx) }
        }
    }

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a routine name."
            return
        }

        let validExercises = exercises.filter { !$0.name.isEmpty }
        guard !validExercises.isEmpty else {
            errorMessage = "Add at least one exercise with a name."
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        // MAPPING: UI -> Backend Payload
        let payloadExercises: [WorkoutsService.CreateRoutinePayload.CreateExerciseTemplate] = validExercises.enumerated().map { index, row in
            
            // Logic: Backend Routine Template uses "Defaults"
            // We take the set count from the UI rows
            // We take the weight/reps from the first row as the default
            let firstSet = row.sets.first
            let setWeight = Double(firstSet?.weightText ?? "") ?? 0.0
            let setReps = Int(firstSet?.repsText ?? "") ?? 0
            
            return .init(
                name: row.name,
                description: nil,
                bodyPart: nil,
                defaultSets: row.sets.count,
                defaultReps: setReps,
                defaultWeightKg: setWeight,
                order: index
            )
        }

        let payload = WorkoutsService.CreateRoutinePayload(
            name: trimmedName,
            notes: notes.isEmpty ? nil : notes,
            exercises: payloadExercises
        )

        do {
            let result: WorkoutRoutine
            
            // Check if Editing or Creating
            if let existing = routineToEdit {
                result = try await service.updateRoutine(id: existing.id, payload: payload)
            } else {
                result = try await service.createRoutine(payload)
            }
            
            onSave(result)
            dismiss()
        } catch {
            errorMessage = "Failed to save routine."
        }
    }
}
