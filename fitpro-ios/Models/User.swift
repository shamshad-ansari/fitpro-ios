import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    var name: String
    var fitnessLevel: String?      // "beginner" | "intermediate" | "advanced"
    var age: Int?                 
    var heightCm: Double?
    var weightKg: Double?
    var goals: Goals?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email, name, fitnessLevel, age, heightCm, weightKg, goals
    }
}

struct Goals: Codable, Equatable {
    var goalType: String?          // "weight_loss" | "muscle_gain" | "maintenance"
    var targetWeightKg: Double?
    var weeklyWorkouts: Int?
}
