import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    private let users: UsersService

    var isLoading = false
    var errorMessage: String?
    var user: User?

    init(users: UsersService) {
        self.users = users
    }

    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let me = try await users.me()
            self.user = me
        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            errorMessage = "Failed to load profile."
        }
    }

    func save(
        name: String?,
        fitnessLevel: String?,
        age: Int?,
        heightCm: Double?,
        weightKg: Double?,
        goals: UsersService.UpdateMePayload.GoalsPayload? 
    ) async -> Bool {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let payload = UsersService.UpdateMePayload(
                name: name?.nilIfEmpty,
                fitnessLevel: fitnessLevel?.nilIfEmpty,
                age: age,
                heightCm: heightCm,
                weightKg: weightKg,
                goals: goals
            )
            let updated = try await users.updateMe(payload)
            self.user = updated
            return true
        } catch let err as APIError {
            errorMessage = err.message
            return false
        } catch {
            errorMessage = "Failed to update profile."
            return false
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
