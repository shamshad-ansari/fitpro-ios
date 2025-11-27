import Foundation

@MainActor
@Observable
final class HomeViewModel {
    private let exercises: ExercisesService

    // Inputs / config
    private let rangeDays: Int = 7

    // State
    var isLoading = false
    var errorMessage: String?

    // Today snapshot
    var todayWorkouts: Int = 0
    var todayMinutes: Double = 0
    var todayCalories: Double = 0

    // Range totals (last 7 days)
    var totalWorkouts: Int = 0
    var totalMinutes: Double = 0
    var totalCalories: Double = 0

    // Most recent exercise
    var lastExercise: Exercise?

    init(exercises: ExercisesService) {
        self.exercises = exercises
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let cal = Calendar(identifier: .gregorian)
        let end = Date()
        guard let start = cal.date(byAdding: .day, value: -rangeDays + 1, to: end) else { return }
        let from = start.ymdKey()
        let to   = end.ymdKey()

        do {
            // 1) Try server summary
            if let serverDaily = try? await fetchServerSummary(from: from, to: to) {
                computeStats(from: serverDaily, todayKey: end.ymdKey())
                // Also try to fetch the most recent exercise for display
                try await loadLastExercise(from: from, to: to)
                return
            }

            // 2) Fallback: fetch exercises and aggregate client-side
            let page1 = try await exercises.list(.init(from: from, to: to, page: 1, limit: 200))
            let aggregated = aggregate(exercises: page1.items, days: rangeDays)
            computeStats(from: aggregated, todayKey: end.ymdKey())
            // The list is already newest → oldest from backend; first item is lastExercise
            lastExercise = page1.items.first

        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            errorMessage = "Failed to load dashboard."
        }
    }

    // MARK: - Server summary

    private func fetchServerSummary(from: String, to: String) async throws -> [DailyStat] {
        let s: [ExercisesService.DailySummary] = try await exercises.summary(from: from, to: to)
        return s.map { d in
            DailyStat(
                date: d.date,
                totalDurationMin: d.totalDurationMin ?? 0,
                totalCalories: d.totalCalories ?? 0,
                count: d.count
            )
        }
    }

    private func loadLastExercise(from: String, to: String) async throws {
        // Ask the backend for most recent exercise in the range
        let page1 = try await exercises.list(.init(from: from, to: to, page: 1, limit: 1))
        lastExercise = page1.items.first
    }

    // MARK: - Client-side aggregation fallback

    private func aggregate(exercises items: [Exercise], days: Int) -> [DailyStat] {
        var bucket: [String: (mins: Double, cals: Double, count: Int)] = [:]
        for ex in items {
            let key = ex.performedAt.ymdKey()
            var acc = bucket[key] ?? (0, 0, 0)
            acc.mins += ex.durationMin ?? 0
            acc.cals += ex.calories ?? 0
            acc.count += 1
            bucket[key] = acc
        }

        let cal = Calendar(identifier: .gregorian)
        let end = Date()
        let start = cal.date(byAdding: .day, value: -days + 1, to: end) ?? end

        var out: [DailyStat] = []
        var d = start
        while d <= end {
            let key = d.ymdKey()
            let v = bucket[key] ?? (0, 0, 0)
            out.append(DailyStat(
                date: key,
                totalDurationMin: v.mins,
                totalCalories: v.cals,
                count: v.count
            ))
            d = cal.date(byAdding: .day, value: 1, to: d)!
        }

        return out.sorted { $0.date > $1.date } // newest first
    }

    // MARK: - Compute final stats

    private func computeStats(from dailies: [DailyStat], todayKey: String) {
        totalWorkouts = dailies.reduce(0) { $0 + $1.count }
        totalMinutes  = dailies.reduce(0) { $0 + $1.totalDurationMin }
        totalCalories = dailies.reduce(0) { $0 + $1.totalCalories }

        if let today = dailies.first(where: { $0.date == todayKey }) {
            todayWorkouts = today.count
            todayMinutes  = today.totalDurationMin
            todayCalories = today.totalCalories
        } else {
            todayWorkouts = 0
            todayMinutes  = 0
            todayCalories = 0
        }
    }
}
