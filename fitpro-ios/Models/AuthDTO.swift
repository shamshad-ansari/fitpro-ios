import Foundation

// Matches login response: { success, data: { user, token }, message }
struct LoginResponse: Codable {
    let user: User
    let token: String
}
