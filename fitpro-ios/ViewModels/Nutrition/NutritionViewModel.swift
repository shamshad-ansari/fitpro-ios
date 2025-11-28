import Foundation

@MainActor
@Observable
final class NutritionViewModel {
    private let service: NutritionService
    
    var selectedDate: Date = Date()
    var isLoading = false
    var errorMessage: String?
    
    // Data
    var summary: NutritionSummary?
    var meals: [Meal] = []
    
    // Computed logic for the Ring Chart
    var caloriesEaten: Int { summary?.calories.eaten ?? 0 }
    var caloriesBurned: Int { summary?.calories.burned ?? 0 }
    var caloriesGoal: Int { summary?.calories.goal ?? 2000 }
    
    // Logic: Left = (Goal + Burned) - Eaten
    // Reference image implies dynamic adjustment based on activity
    var caloriesLeft: Int {
        let totalBudget = caloriesGoal + caloriesBurned
        return max(0, totalBudget - caloriesEaten)
    }
    
    // Ring Progress (0.0 to 1.0)
    var ringProgress: Double {
        let totalBudget = Double(caloriesGoal + caloriesBurned)
        guard totalBudget > 0 else { return 0 }
        return Double(caloriesEaten) / totalBudget
    }

    init(service: NutritionService) {
        self.service = service
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Fetch both in parallel
            async let sumTask = service.getSummary(date: selectedDate)
            async let mealsTask = service.listMeals(date: selectedDate)
            
            let (sum, mList) = try await (sumTask, mealsTask)
            self.summary = sum
            self.meals = mList
        } catch let err as APIError {
            errorMessage = err.message
        } catch {
            errorMessage = "Failed to load nutrition data."
        }
    }
    
    func deleteMeal(_ meal: Meal) async {
        do {
            try await service.deleteMeal(id: meal.id)
            await loadData() // Refresh
        } catch {
            errorMessage = "Failed to delete meal."
        }
    }
}
