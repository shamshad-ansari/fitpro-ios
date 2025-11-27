import Foundation

struct DailyStat: Identifiable, Equatable {
    var id: String { date }             // use date as stable id
    let date: String                    // "YYYY-MM-DD"
    let totalDurationMin: Double
    let totalCalories: Double
    let count: Int
}

extension Date {
    func ymdKey() -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: self)
    }
}
