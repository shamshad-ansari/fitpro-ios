import Foundation
import Observation

@MainActor
@Observable
final class ActiveWorkoutViewModel {

    // Nested types used by the view
    struct ActiveSet: Identifiable, Equatable {
        let id = UUID()
        var index: Int
        var weightText: String
        var repsText: String

        var hasAnyInput: Bool {
            !weightText.trimmingCharacters(in: .whitespaces).isEmpty ||
            !repsText.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    struct ActiveExercise: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let note: String?
        var sets: [ActiveSet]
    }

    // Basic routine info
    let routineId: String
    let routineName: String
    let routineNote: String?

    // Dependencies
    private let workouts: WorkoutsService

    // State exposed to the view
    var exercises: [ActiveExercise] = []
    var elapsedSec: Int = 0
    var isRunning: Bool = false
    var isSaving: Bool = false
    var errorMessage: String?

    private(set) var startedAt: Date?

    var elapsedLabel: String {
        let m = elapsedSec / 60
        let s = elapsedSec % 60
        return String(format: "%02d:%02d", m, s)
    }

    init(routine: WorkoutRoutine, workouts: WorkoutsService) {
        self.routineId = routine.id
        self.routineName = routine.name
        self.routineNote = routine.notes
        self.workouts = workouts

        // Build initial exercises with placeholder sets from the routine defaults
        self.exercises = routine.exercises.map { ex in
            let defaultSets = ex.defaultSets ?? 1
            let count = max(defaultSets, 1)

            let initialSets: [ActiveSet] = (0..<count).map { idx in
                ActiveSet(
                    index: idx + 1,
                    weightText: ex.defaultWeightKg.map { String(Int($0)) } ?? "",
                    repsText: ex.defaultReps.map { String($0) } ?? ""
                )
            }

            return ActiveExercise(
                name: ex.name,
                note: ex.description,
                sets: initialSets
            )
        }
    }

    // MARK: - Timer

    func startWorkout() {
        startedAt = Date()
        elapsedSec = 0
        isRunning = true
        errorMessage = nil
    }

    func tick() {
        guard isRunning else { return }
        elapsedSec += 1
    }

    // MARK: - Modify sets

    func addSet(to exerciseId: UUID) {
        guard let idx = exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        let nextIndex = (exercises[idx].sets.map { $0.index }.max() ?? 0) + 1
        exercises[idx].sets.append(
            ActiveSet(index: nextIndex, weightText: "", repsText: "")
        )
    }

    // MARK: - Finish and save

    func finish() async -> Bool {
        guard let startedAt else {
            errorMessage = "Workout has not started."
            return false
        }

        isSaving = true
        errorMessage = nil
        let finishedAt = Date()
        let iso = ISO8601DateFormatter()
        defer { isSaving = false }

        // Build per-exercise, per-set payload
        let exercisePayloads: [WorkoutsService.CreateSessionPayload.ExercisePayload] =
            exercises.map { ex in
                let setPayloads: [WorkoutsService.CreateSessionPayload.ExercisePayload.SetPayload] =
                    ex.sets.compactMap { set in
                        // Skip completely empty rows
                        if !set.hasAnyInput { return nil }

                        let weight = Double(set.weightText.trimmingCharacters(in: .whitespaces))
                        let reps = Int(set.repsText.trimmingCharacters(in: .whitespaces))

                        return .init(
                            index: set.index,
                            weightKg: weight,
                            reps: reps,
                            durationSec: nil,
                            calories: nil
                        )
                    }

                return .init(
                    name: ex.name,
                    sets: setPayloads
                )
            }
            .filter { !$0.sets.isEmpty }

        if exercisePayloads.isEmpty {
            errorMessage = "Please log at least one set before finishing."
            return false
        }

        let payload = WorkoutsService.CreateSessionPayload(
            routineId: routineId,
            startedAt: iso.string(from: startedAt),
            finishedAt: iso.string(from: finishedAt),
            exercises: exercisePayloads
        )

        do {
            _ = try await workouts.createSession(payload)
            return true
        } catch let err as APIError {
            errorMessage = err.message
            return false
        } catch {
            errorMessage = "Failed to save workout."
            return false
        }
    }
}
