import Foundation

@MainActor
@Observable
final class HomeViewModel {
    private let workoutsService: WorkoutsService
    private let usersService: UsersService
    private let nutritionService: NutritionService // <-- NEW DEPENDENCY

    // MARK: - Dashboard Data
    
    var userName: String = "User"
    var routines: [WorkoutRoutine] = []
    var recentActivity: [WorkoutSession] = []
    
    // Nutrition Data (NEW)
    var nutritionSummary: NutritionSummary?
    
    // Stats
    var weeklyWorkouts: Int = 0
    var totalWorkouts: Int = 0
    var currentStreak: Int = 0
    
    // State
    var isLoading = false
    var errorMessage: String?

    init(workouts: WorkoutsService, users: UsersService, nutrition: NutritionService) {
        self.workoutsService = workouts
        self.usersService = users
        self.nutritionService = nutrition
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Parallel Fetching: User, Routines, History, Nutrition
            async let userTask = usersService.me()
            async let routinesTask = workoutsService.listRoutines()
            async let sessionsTask = workoutsService.listSessions()
            async let nutritionTask = nutritionService.getSummary(date: Date()) // Fetch today's nutrition
            
            let (user, allRoutines, sessions, nutSummary) = try await (userTask, routinesTask, sessionsTask, nutritionTask)
            
            // Assign Data
            self.userName = user.name.components(separatedBy: " ").first ?? user.name
            self.routines = allRoutines.filter { $0.isArchived != true }
            self.nutritionSummary = nutSummary
            
            // Stats Logic
            let sortedSessions = sessions.sorted { $0.startedAt > $1.startedAt }
            self.recentActivity = Array(sortedSessions.prefix(5))
            self.totalWorkouts = sessions.count
            self.weeklyWorkouts = calculateWeeklyWorkouts(sessions)
            self.currentStreak = calculateStreak(sessions)
            
        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            // Ignore nutrition errors silently if just starting out, or log them
            print("Dashboard load error: \(error)")
        }
    }
    
    // MARK: - Logic Helpers
    
    private func calculateWeeklyWorkouts(_ sessions: [WorkoutSession]) -> Int {
        let cal = Calendar.current
        let now = Date()
        guard let startOfWeek = cal.date(byAdding: .day, value: -7, to: now) else { return 0 }
        return sessions.filter { $0.startedAt >= startOfWeek }.count
    }
    
    private func calculateStreak(_ sessions: [WorkoutSession]) -> Int {
        let cal = Calendar.current
        let uniqueDays = Set(sessions.map { cal.startOfDay(for: $0.startedAt) }).sorted(by: >)
        
        var streak = 0
        var checkDate = cal.startOfDay(for: Date())
        
        if !uniqueDays.contains(checkDate) {
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        for day in uniqueDays {
            if cal.isDate(day, inSameDayAs: checkDate) {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }
}
