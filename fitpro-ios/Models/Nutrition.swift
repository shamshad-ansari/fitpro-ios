import Foundation

// Matches GET /api/nutrition/meals response
struct Meal: Codable, Identifiable, Equatable {
    let id: String
    let user: String
    let date: Date
    let type: MealType
    let title: String
    let time: Date?
    let description: String?
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatsG: Int

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user, date, type, title, time, description, calories, proteinG, carbsG, fatsG
    }
}

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack, other
    var id: String { self.rawValue }
    
    var displayName: String {
        self.rawValue.capitalized
    }
}

// Matches GET /api/nutrition/summary response
struct NutritionSummary: Codable, Equatable {
    let date: String
    let calories: CalorieData
    let macros: MacroData
    
    struct CalorieData: Codable, Equatable {
        let eaten: Int
        let burned: Int
        let goal: Int
    }
    
    struct MacroData: Codable, Equatable {
        let protein: MacroDetail
        let carbs: MacroDetail
        let fats: MacroDetail
    }
    
    struct MacroDetail: Codable, Equatable {
        let grams: Int
        let target: Int
    }
}
