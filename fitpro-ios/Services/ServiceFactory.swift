import Foundation

@MainActor
struct ServiceFactory {
    let env: AppEnvironment
    func authService() -> AuthService { AuthService(api: env.apiClient) }
    func usersService() -> UsersService { UsersService(api: env.apiClient) }
    func exercisesService() -> ExercisesService { ExercisesService(api: env.apiClient) }
    func workoutsService() -> WorkoutsService { WorkoutsService(api: env.apiClient) }
    func nutritionService() -> NutritionService { NutritionService(api: env.apiClient) }
}
