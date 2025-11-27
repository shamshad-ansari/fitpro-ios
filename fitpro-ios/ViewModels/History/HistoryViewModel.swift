import Foundation
import Observation

@MainActor
@Observable
final class HistoryViewModel {
    private let workouts: WorkoutsService

    var isLoading: Bool = false
    var errorMessage: String?
    var sessions: [WorkoutSession] = []

    init(workouts: WorkoutsService) {
        self.workouts = workouts
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let items = try await workouts.listSessions()
            // newest first
            sessions = items.sorted { $0.startedAt > $1.startedAt }
        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            errorMessage = "Failed to load history."
        }
    }

    func refresh() async {
        await load()
    }
}
