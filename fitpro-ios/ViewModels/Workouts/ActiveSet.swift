import Foundation

/// One row in the table: SET / PREVIOUS / LBS / REPS
struct ActiveSet: Identifiable, Equatable {
    let id = UUID()
    let index: Int                     // 1, 2, 3, ...
    var weightText: String            // what the user types now
    var repsText: String              // what the user types now
    var previousText: String?         // e.g. "70 kg x 12" from history
}

/// One exercise block inside the workout (e.g., Skullcrusher)
struct ActiveExercise: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let note: String?
    var sets: [ActiveSet]
}
