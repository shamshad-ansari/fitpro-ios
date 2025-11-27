import Foundation

@MainActor
final class UsersService {
    private let api: APIClient
    init(api: APIClient) { self.api = api }

    func me() async throws -> User {
        let req = APIRequest(path: "/api/users/me", method: .GET)
        return try await api.send(req, as: User.self)
    }

    struct UpdateMePayload: Encodable {
        var name: String?
        var fitnessLevel: String?
        var age: Int?                         
        var heightCm: Double?
        var weightKg: Double?
        var goals: GoalsPayload?

        struct GoalsPayload: Encodable {
            var goalType: String?
            var targetWeightKg: Double?
            var weeklyWorkouts: Int?
        }
    }

    func updateMe(_ body: UpdateMePayload) async throws -> User {
        let req = APIRequest(path: "/api/users/me", method: .PUT, body: body)
        return try await api.send(req, as: User.self)
    }
}
