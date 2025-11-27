import Foundation

struct Exercise: Codable, Identifiable, Equatable {
    let id: String
    let userId: String
    let name: String
    let category: String?
    let sets: Int?
    let reps: Int?
    let weightKg: Double?
    let durationMin: Double?
    let calories: Double?
    let notes: String?
    let performedAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId = "user"
        case name, category, sets, reps, weightKg, durationMin, calories, notes, performedAt
    }
}

// 🔧 UPDATED to match backend: supports `pages` and optional `limit`
struct Paged<T: Codable & Equatable>: Codable, Equatable {
    let items: [T]
    let total: Int
    let page: Int
    let limit: Int?    // backend doesn't send this, so make it optional
    let pages: Int?    // backend sends `pages`

    enum CodingKeys: String, CodingKey {
        case items, total, page, limit, pages
    }
}
