import Foundation

/// Exercise template inside a routine ("Skullcrusher (Barbell)", "Tricep Pushdown", etc.)
struct RoutineExercise: Codable, Equatable, Identifiable {
    // Backend does not give an _id for subdocs, so we synthesize a stable-ish id.
    var id: String { name + "|" + (description ?? "") }

    let name: String
    let description: String?
    let bodyPart: String?
    let defaultSets: Int?
    let defaultReps: Int?
    let defaultWeightKg: Double?
    let order: Int?

    enum CodingKeys: String, CodingKey {
        case name, description, bodyPart, defaultSets, defaultReps, defaultWeightKg, order
    }
}

/// Top-level routine ("Arms Day", "Legs", etc.)
struct WorkoutRoutine: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let notes: String?
    let exercises: [RoutineExercise]
    let isArchived: Bool?

    // You can use these later if you want timestamps in the UI
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, notes, exercises, isArchived, createdAt, updatedAt
    }
}
