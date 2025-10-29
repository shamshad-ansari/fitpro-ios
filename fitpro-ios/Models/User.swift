import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let fitnessLevel: String?
    let goals: Goals?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email, name, fitnessLevel, goals
    }
}

struct Goals: Codable {
    let goalType: String?
    let targetWeightKg: Double?
    let weeklyWorkouts: Int?
}
