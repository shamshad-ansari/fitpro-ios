import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    var name: String
    var gender: String?
    var fitnessLevel: String?
    var age: Int?
    var heightCm: Double?
    var weightKg: Double?
    var goals: Goals?
    
    // NEW: For "Member since" badge
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email, name, fitnessLevel, age, heightCm, weightKg, goals, createdAt
    }
}

struct Goals: Codable, Equatable {
    var goalType: String?
    var targetWeightKg: Double?
    var weeklyWorkouts: Int?
}
