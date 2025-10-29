import Foundation

struct Credentials: Encodable {
    let email: String
    let password: String
}
struct SignupPayload: Encodable {
    let email: String
    let name: String
    let password: String
}

@MainActor
final class AuthService {
    private let api: APIClient
    init(api: APIClient) { self.api = api }

    func login(email: String, password: String) async throws -> LoginResponse {
        let req = APIRequest(
            path: "/api/auth/login",
            method: .POST,
            body: Credentials(email: email, password: password)
        )
        return try await api.send(req, as: LoginResponse.self)
    }

    func signup(email: String, name: String, password: String) async throws -> VoidResponse {
        let req = APIRequest(
            path: "/api/auth/signup",
            method: .POST,
            body: SignupPayload(email: email, name: name, password: password)
        )
        return try await api.send(req, as: VoidResponse.self)
    }
}

// Some endpoints just return success with no data; this matches { success, data: null, message }
struct VoidResponse: Codable {}
