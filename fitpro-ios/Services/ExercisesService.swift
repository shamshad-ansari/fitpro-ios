import Foundation

@MainActor
final class ExercisesService {
    private let api: APIClient
    init(api: APIClient) { self.api = api }

    struct CreatePayload: Encodable {
        let name: String
        var category: String?
        var sets: Int?
        var reps: Int?
        var weightKg: Double?
        var durationMin: Double?
        var calories: Double?
        var notes: String?
        var performedAt: String? // ISO-8601 date string (let APIClient encode ISO if you prefer)
    }

    func create(_ payload: CreatePayload) async throws -> Exercise {
        let req = APIRequest(path: "/api/exercises", method: .POST, body: payload)
        return try await api.send(req, as: Exercise.self)
    }

    struct ListQuery {
        var from: String?   // "YYYY-MM-DD"
        var to: String?     // "YYYY-MM-DD"
        var page: Int = 1
        var limit: Int = 20
    }

    func list(_ q: ListQuery) async throws -> Paged<Exercise> {
        var params: [String: String] = ["page": String(q.page), "limit": String(q.limit)]
        if let from = q.from { params["from"] = from }
        if let to = q.to { params["to"] = to }
        let req = APIRequest(path: "/api/exercises", method: .GET, query: params)
        return try await api.send(req, as: Paged<Exercise>.self)
    }

    struct DailySummary: Codable, Equatable {
        let date: String         // YYYY-MM-DD
        let totalDurationMin: Double?
        let totalCalories: Double?
        let count: Int
    }

    func summary(from: String, to: String) async throws -> [DailySummary] {
        let req = APIRequest(
            path: "/api/exercises/summary",
            method: .GET,
            query: ["from": from, "to": to]
        )
        return try await api.send(req, as: [DailySummary].self)
    }
}

extension ExercisesService {
    /// Last logged exercise for a given name (used for PREVIOUS column).
    func last(for name: String) async throws -> Exercise? {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let req = APIRequest(
            path: "/api/exercises/last",
            method: .GET,
            query: ["name": encoded]
        )
        // The endpoint returns `{ success, data: Exercise|null }`
        // but our APIClient expects a Decodable. We'll decode `Exercise?`.
        return try await api.send(req, as: Exercise?.self)
    }
}

