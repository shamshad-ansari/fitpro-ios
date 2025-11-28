import Foundation

@MainActor
final class NutritionService {
    private let api: APIClient
    init(api: APIClient) { self.api = api }

    // GET /api/nutrition/summary?date=YYYY-MM-DD
    func getSummary(date: Date) async throws -> NutritionSummary {
        let dateStr = date.ymdKey() // Extension exists in your project
        let req = APIRequest(
            path: "/api/nutrition/summary",
            method: .GET,
            query: ["date": dateStr]
        )
        return try await api.send(req, as: NutritionSummary.self)
    }

    // GET /api/nutrition/meals?from=...&to=...
    func listMeals(date: Date) async throws -> [Meal] {
        let dateStr = date.ymdKey()
        // We fetch meals for the specific single day
        let req = APIRequest(
            path: "/api/nutrition/meals",
            method: .GET,
            query: ["from": dateStr, "to": dateStr]
        )
        return try await api.send(req, as: [Meal].self)
    }

    struct CreateMealPayload: Encodable {
        let date: Date
        let type: String
        let title: String
        let calories: Int
        let proteinG: Int
        let carbsG: Int
        let fatsG: Int
    }

    // POST /api/nutrition/meals
    func createMeal(_ payload: CreateMealPayload) async throws -> Meal {
        let req = APIRequest(path: "/api/nutrition/meals", method: .POST, body: payload)
        return try await api.send(req, as: Meal.self)
    }
    
    // DELETE /api/nutrition/meals/:id
    func deleteMeal(id: String) async throws {
        let req = APIRequest(path: "/api/nutrition/meals/\(id)", method: .DELETE)
        _ = try await api.send(req, as: VoidResponse.self) // Reusing VoidResponse from Auth
    }
}
