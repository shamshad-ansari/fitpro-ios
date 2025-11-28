import Foundation

@MainActor
final class WorkoutsService {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Routines

    func listRoutines() async throws -> [WorkoutRoutine] {
        let req = APIRequest(path: "/api/workouts", method: .GET)
        return try await api.send(req, as: [WorkoutRoutine].self)
    }

    struct CreateRoutinePayload: Encodable {
        let name: String
        var notes: String?
        var exercises: [CreateExerciseTemplate]

        struct CreateExerciseTemplate: Encodable {
            let name: String
            var description: String?
            var bodyPart: String?
            var defaultSets: Int?
            var defaultReps: Int?
            var defaultWeightKg: Double?
            var order: Int?
        }
    }

    func createRoutine(_ payload: CreateRoutinePayload) async throws -> WorkoutRoutine {
        let req = APIRequest(path: "/api/workouts", method: .POST, body: payload)
        return try await api.send(req, as: WorkoutRoutine.self)
    }
    
    // NEW: Update Routine
    func updateRoutine(id: String, payload: CreateRoutinePayload) async throws -> WorkoutRoutine {
        let req = APIRequest(path: "/api/workouts/\(id)", method: .PATCH, body: payload)
        return try await api.send(req, as: WorkoutRoutine.self)
    }
    
    // NEW: Delete Routine
    func deleteRoutine(id: String) async throws {
        let req = APIRequest(path: "/api/workouts/\(id)", method: .DELETE)
        _ = try await api.send(req, as: VoidResponse.self)
    }

    // MARK: - Sessions (history)

    struct CreateSessionPayload: Encodable {
        let routineId: String
        let startedAt: String   // ISO8601
        let finishedAt: String  // ISO8601
        var exercises: [ExercisePayload]

        struct ExercisePayload: Encodable {
            let name: String
            var sets: [SetPayload]

            struct SetPayload: Encodable {
                var index: Int
                var weightKg: Double?
                var reps: Int?
                var durationSec: Int?
                var calories: Double?
            }
        }
    }

    func createSession(_ payload: CreateSessionPayload) async throws -> WorkoutSession {
        let req = APIRequest(path: "/api/workouts/sessions", method: .POST, body: payload)
        return try await api.send(req, as: WorkoutSession.self)
    }

    func listSessions(from: String? = nil, to: String? = nil) async throws -> [WorkoutSession] {
        var query: [String: String] = [:]
        if let from { query["from"] = from }
        if let to { query["to"] = to }

        let req = APIRequest(
            path: "/api/workouts/sessions",
            method: .GET,
            query: query.isEmpty ? nil : query
        )
        return try await api.send(req, as: [WorkoutSession].self)
    }
    
    // NEW: Delete Session
    func deleteSession(id: String) async throws {
        let req = APIRequest(path: "/api/workouts/sessions/\(id)", method: .DELETE)
        _ = try await api.send(req, as: VoidResponse.self)
    }
}
