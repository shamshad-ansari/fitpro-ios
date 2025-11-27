import Foundation

struct WorkoutSession: Codable, Identifiable, Equatable {
    // Reference to the routine (populated in GET /sessions, may be null in older docs)
    struct RoutineRef: Codable, Equatable {
        let id: String
        let name: String

        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case name
        }
    }

    // One set (row) inside an exercise
    struct SetEntry: Codable, Equatable, Identifiable {
        var id: Int { index }          // stable ID for ForEach

        let index: Int                 // 1, 2, 3, ...
        let weightKg: Double?
        let reps: Int?
        let durationSec: Int?
        let calories: Double?
        let notes: String?
    }

    // One exercise inside the session
    struct ExerciseEntry: Codable, Equatable, Identifiable {
        var id: String { name }        // good enough for now

        let name: String
        let notes: String?
        let sets: [SetEntry]
    }

    // Top-level session fields
    let id: String
    let userId: String
    let routine: RoutineRef?          // optional to tolerate old rows with null
    let startedAt: Date
    let finishedAt: Date?
    let durationSec: Int?
    let exercises: [ExerciseEntry]

    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId = "user"
        case routine = "workoutRoutine"
        case startedAt
        case finishedAt
        case durationSec
        case exercises
        case createdAt
        case updatedAt
    }
}
