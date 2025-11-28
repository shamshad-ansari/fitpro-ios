import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    private let users: UsersService
    private let workouts: WorkoutsService // Added dependency

    var isLoading = false
    var errorMessage: String?
    var user: User?
    
    // Stats
    var totalWorkouts: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalVolumeKg: Double = 0

    init(users: UsersService, workouts: WorkoutsService) {
        self.users = users
        self.workouts = workouts
    }

    func load() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. Fetch Profile
            async let userTask = users.me()
            // 2. Fetch Sessions for Stats
            async let sessionsTask = workouts.listSessions()
            
            let (fetchedUser, sessions) = try await (userTask, sessionsTask)
            self.user = fetchedUser
            
            // 3. Calculate Stats
            calculateStats(from: sessions)
            
        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            errorMessage = "Failed to load profile."
        }
    }
    
    private func calculateStats(from sessions: [WorkoutSession]) {
        let sorted = sessions.sorted { $0.startedAt > $1.startedAt }
        
        // Total Workouts
        self.totalWorkouts = sorted.count
        
        // Total Volume (Sum of weight * reps for all sets)
        self.totalVolumeKg = sessions.reduce(0) { sessionSum, session in
            let sessionVol = session.exercises.reduce(0) { exSum, ex in
                let exVol = ex.sets.reduce(0) { setSum, set in
                    setSum + (set.weightKg ?? 0) * Double(set.reps ?? 0)
                }
                return exSum + exVol
            }
            return sessionSum + sessionVol
        }
        
        // Streaks
        let cal = Calendar.current
        let uniqueDays = Set(sorted.map { cal.startOfDay(for: $0.startedAt) }).sorted(by: >)
        
        // Current Streak
        var current = 0
        var checkDate = cal.startOfDay(for: Date())
        
        // Allow streak to continue if last workout was yesterday
        if !uniqueDays.contains(checkDate) {
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        for day in uniqueDays {
            if cal.isDate(day, inSameDayAs: checkDate) {
                current += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        self.currentStreak = current
        
        // Longest Streak
        var maxStreak = 0
        var tempStreak = 0
        // Iterate backwards through unique days to find longest sequence
        if !uniqueDays.isEmpty {
            tempStreak = 1
            maxStreak = 1
            for i in 0..<(uniqueDays.count - 1) {
                let currentDay = uniqueDays[i]
                let nextDay = uniqueDays[i + 1] // Actually previous in time since sorted desc
                
                if let diff = cal.dateComponents([.day], from: nextDay, to: currentDay).day, diff == 1 {
                    tempStreak += 1
                } else {
                    maxStreak = max(maxStreak, tempStreak)
                    tempStreak = 1
                }
            }
            maxStreak = max(maxStreak, tempStreak)
        }
        self.longestStreak = maxStreak
    }

    // Keep save() logic same as before...
    func save(name: String?, fitnessLevel: String?, age: Int?, heightCm: Double?, weightKg: Double?, goals: UsersService.UpdateMePayload.GoalsPayload?) async -> Bool {
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
            self.user = try await users.updateMe(payload)
            return true
        } catch {
            return false
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
