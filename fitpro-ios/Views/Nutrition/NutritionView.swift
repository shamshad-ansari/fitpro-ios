import SwiftUI

struct NutritionView: View {
    @Environment(\.appEnvironment) private var env
    @State private var vm: NutritionViewModel? = nil
    @State private var showAddMeal = false
    
    var body: some View {
        let factory = ServiceFactory(env: env)
        
        NavigationStack {
            ZStack {
                Theme.Color.bg.ignoresSafeArea()
                
                if let model = vm {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Theme.Spacing.l.rawValue) {
                            
                            // 1. Date Header (Simple implementation for now)
                            HStack {
                                Text("Nutrition")
                                    .font(Theme.Font.h1)
                                    .foregroundStyle(Theme.Color.text)
                                Spacer()
                                Text(model.selectedDate.formatted(date: .complete, time: .omitted))
                                    .font(Theme.Font.body)
                                    .foregroundStyle(Theme.Color.subtle)
                            }
                            .padding(.horizontal, Theme.Spacing.l.rawValue)
                            .padding(.top, Theme.Spacing.s.rawValue)
                            
                            // 2. Calorie Ring Card
                            CalorieRingCard(model: model)
                            
                            // 3. Macros Card
                            if let summary = model.summary {
                                MacrosCard(macros: summary.macros)
                            }
                            
                            // 4. Meals List
                            MealsListSection(model: model) {
                                showAddMeal = true
                            }
                            
                            Spacer().frame(height: 100)
                        }
                    }
                    .refreshable { await model.loadData() }
                } else {
                    ProgressView()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddMeal) {
                if let model = vm {
                    MealEditorView(service: factory.nutritionService()) {
                        Task { await model.loadData() }
                    }
                }
            }
            .onAppear {
                if vm == nil {
                    vm = NutritionViewModel(service: factory.nutritionService())
                }
            }
            .task {
                if let model = vm, model.summary == nil {
                    await model.loadData()
                }
            }
        }
    }
}

// MARK: - 1. Calorie Ring Component

struct CalorieRingCard: View {
    let model: NutritionViewModel
    
    var body: some View {
        VStack(spacing: Theme.Spacing.l.rawValue) {
            
            // Ring
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Theme.Color.primaryAccent.opacity(0.1), lineWidth: 20)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: model.ringProgress)
                    .stroke(
                        Theme.Color.primaryAccent,
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring, value: model.ringProgress)
                
                // Center Text
                VStack(spacing: 4) {
                    Text("\(model.caloriesLeft)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Theme.Color.text)
                    Text("kcal left")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.subtle)
                }
            }
            .frame(width: 200, height: 200)
            .padding(.top, Theme.Spacing.m.rawValue)
            
            // Stats Row
            HStack(spacing: 40) {
                statItem(label: "Eaten", value: "\(model.caloriesEaten)", color: Theme.Color.primaryAccent)
                statItem(label: "Burned", value: "\(model.caloriesBurned)", color: Theme.Color.secondary)
                statItem(label: "Goal", value: "\(model.caloriesGoal)", color: Theme.Color.subtle)
            }
            .padding(.bottom, Theme.Spacing.m.rawValue)
        }
        .padding(Theme.Spacing.l.rawValue)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, Theme.Spacing.l.rawValue)
    }
    
    private func statItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.Color.subtle)
            Text(value)
                .font(Theme.Font.h4)
                .foregroundStyle(Theme.Color.text)
        }
    }
}

// MARK: - 2. Macros Component

struct MacrosCard: View {
    let macros: NutritionSummary.MacroData
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m.rawValue) {
            Text("Macros")
                .font(Theme.Font.h3)
                .foregroundStyle(Theme.Color.text)
            
            VStack(spacing: Theme.Spacing.l.rawValue) {
                MacroRow(
                    label: "Protein",
                    icon: "fork.knife", // Placeholder for chicken leg
                    color: Color(hex: "5D5FEF"), // Example specific color
                    current: macros.protein.grams,
                    target: macros.protein.target
                )
                MacroRow(
                    label: "Carbs",
                    icon: "circle.grid.cross", // Placeholder for bread
                    color: Color(hex: "F5A623"),
                    current: macros.carbs.grams,
                    target: macros.carbs.target
                )
                MacroRow(
                    label: "Fats",
                    icon: "drop.fill", // Placeholder for oil/fat
                    color: Color(hex: "4A90E2"),
                    current: macros.fats.grams,
                    target: macros.fats.target
                )
            }
        }
        .padding(Theme.Spacing.l.rawValue)
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l.rawValue))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .padding(.horizontal, Theme.Spacing.l.rawValue)
    }
}

struct MacroRow: View {
    let label: String
    let icon: String
    let color: Color
    let current: Int
    let target: Int
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(Theme.Font.button)
                    .foregroundStyle(Theme.Color.text)
                Spacer()
                Text("\(current)/\(target)g")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.subtle)
            }
            
            // Custom Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Color.bg)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - 3. Meals List Component

struct MealsListSection: View {
    let model: NutritionViewModel
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m.rawValue) {
            HStack {
                Text("Today's Meals")
                    .font(Theme.Font.h3)
                    .foregroundStyle(Theme.Color.text)
                Spacer()
                Button("+ Add", action: onAdd)
                    .font(Theme.Font.button)
                    .foregroundStyle(Theme.Color.primaryAccent)
            }
            .padding(.horizontal, Theme.Spacing.l.rawValue)
            
            if model.meals.isEmpty {
                Text("No meals logged yet.")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.subtle)
                    .padding(.horizontal, Theme.Spacing.l.rawValue)
            } else {
                VStack(spacing: Theme.Spacing.m.rawValue) {
                    ForEach(model.meals) { meal in
                        MealRow(meal: meal)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l.rawValue)
            }
            
            // Big Add Button at bottom
            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Meal")
                }
                .font(Theme.Font.button)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.Color.primaryAccent.opacity(0.1))
                .foregroundStyle(Theme.Color.primaryAccent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundStyle(Theme.Color.primaryAccent)
                )
            }
            .padding(.horizontal, Theme.Spacing.l.rawValue)
        }
    }
}

struct MealRow: View {
    let meal: Meal
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m.rawValue) {
            // Icon based on type
            Image(systemName: iconForType(meal.type))
                .font(.system(size: 20))
                .foregroundStyle(Theme.Color.primaryAccent)
                .frame(width: 40, height: 40)
                .background(Theme.Color.bg)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.title)
                        .font(Theme.Font.h4)
                        .foregroundStyle(Theme.Color.text)
                    Spacer()
                    Text("\(meal.calories)")
                        .font(Theme.Font.h4)
                        .foregroundStyle(Theme.Color.text)
                }
                
                HStack {
                    if let time = meal.time {
                        Text(time.formatted(date: .omitted, time: .shortened))
                    }
                    if let desc = meal.description, !desc.isEmpty {
                        Text("• \(desc)")
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("kcal")
                        .font(.caption)
                }
                .font(.caption)
                .foregroundStyle(Theme.Color.subtle)
            }
        }
        .padding()
        .background(Theme.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m.rawValue))
    }
    
    func iconForType(_ type: MealType) -> String {
        switch type {
        case .breakfast: return "sun.max.fill"
        case .lunch: return "takeoutbag.and.cup.and.straw.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "carrot.fill"
        case .other: return "fork.knife"
        }
    }
}
