import SwiftUI

struct CreateRoutineView: View {
    @Environment(\.dismiss) private var dismiss

    private let service: WorkoutsService
    let onCreated: (WorkoutRoutine) -> Void

    // Routine-level fields
    @State private var name: String = ""
    @State private var notes: String = ""

    // Dynamic list of exercise templates
    @State private var exercises: [ExerciseRow] = [ExerciseRow()]

    @State private var isSaving = false
    @State private var errorMessage: String?

    struct ExerciseRow: Identifiable {
        let id = UUID()
        var name: String = ""
        var description: String = ""
        var bodyPart: String = ""
        var defaultSets: String = ""
        var defaultReps: String = ""
        var defaultWeightKg: String = ""
    }

    init(service: WorkoutsService, onCreated: @escaping (WorkoutRoutine) -> Void) {
        self.service = service
        self.onCreated = onCreated
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Routine name (e.g. Arms, Legs)", text: $name)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("Exercises") {
                    if exercises.isEmpty {
                        Text("Add at least one exercise.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach($exercises) { $row in
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Exercise name", text: $row.name)
                                TextField("Description (optional)", text: $row.description)

                                HStack {
                                    TextField("Body part", text: $row.bodyPart)
                                    TextField("Sets", text: $row.defaultSets)
                                        .keyboardType(.numberPad)
                                        .frame(width: 60)
                                    TextField("Reps", text: $row.defaultReps)
                                        .keyboardType(.numberPad)
                                        .frame(width: 60)
                                    TextField("Weight (kg)", text: $row.defaultWeightKg)
                                        .keyboardType(.decimalPad)
                                        .frame(width: 80)
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { offsets in
                            exercises.remove(atOffsets: offsets)
                        }
                    }

                    Button {
                        exercises.append(ExerciseRow())
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }

                if let msg = errorMessage {
                    Section {
                        Text(msg).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Workout")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save").bold()
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    // MARK: - Saving

    private func save() async {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            errorMessage = "Please enter a routine name."
            return
        }

        let nonEmptyExercises = exercises.filter {
            !$0.name.trimmingCharacters(in: .whitespaces).isEmpty
        }
        guard !nonEmptyExercises.isEmpty else {
            errorMessage = "Add at least one exercise to the routine."
            return
        }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let payload = WorkoutsService.CreateRoutinePayload(
            name: trimmedName,
            notes: notes.isEmpty ? nil : notes,
            exercises: nonEmptyExercises.enumerated().map { index, row in
                .init(
                    name: row.name,
                    description: row.description.isEmpty ? nil : row.description,
                    bodyPart: row.bodyPart.isEmpty ? nil : row.bodyPart,
                    defaultSets: Int(row.defaultSets),
                    defaultReps: Int(row.defaultReps),
                    defaultWeightKg: Double(row.defaultWeightKg),
                    order: index
                )
            }
        )

        do {
            let routine = try await service.createRoutine(payload)
            onCreated(routine)
            dismiss()
        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            errorMessage = "Failed to create routine."
        }
    }
}
