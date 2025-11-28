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
            self.routines = data.filter { $0.isArchived != true }
        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            errorMessage = "Failed to load workouts."
        }
    }
    
    func delete(routine: WorkoutRoutine) async {
        do {
            try await service.deleteRoutine(id: routine.id)
            // Remove locally
            if let idx = routines.firstIndex(where: { $0.id == routine.id }) {
                routines.remove(at: idx)
            }
        } catch {
            errorMessage = "Failed to delete routine."
        }
    }
}
