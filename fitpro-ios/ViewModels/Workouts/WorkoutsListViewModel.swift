import Foundation

@MainActor
@Observable
final class WorkoutsListViewModel {
    private let service: WorkoutsService

    var isLoading = false
    var errorMessage: String?
    var routines: [WorkoutRoutine] = []

    init(service: WorkoutsService) {
        self.service = service
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let data = try await service.listRoutines()
            // For now, show non-archived only (backend already filters, but just in case)
            self.routines = data.filter { $0.isArchived != true }
        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            errorMessage = "Failed to load workouts."
        }
    }
}
