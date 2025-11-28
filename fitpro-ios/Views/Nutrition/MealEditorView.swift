import SwiftUI

struct MealEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let service: NutritionService
    let onSave: () -> Void
    
    @State private var title = ""
    @State private var type: MealType = .breakfast
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fats = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    Picker("Type", selection: $type) {
                        ForEach(MealType.allCases) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    TextField("Title (e.g. Oatmeal)", text: $title)
                }
                
                Section("Nutrition Data") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", text: $calories).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("0", text: $protein).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("0", text: $carbs).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Fats (g)")
                        Spacer()
                        TextField("0", text: $fats).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Log Meal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func save() async {
        isSaving = true
        defer { isSaving = false }
        
        let payload = NutritionService.CreateMealPayload(
            date: Date(),
            type: type.rawValue,
            title: title,
            calories: Int(calories) ?? 0,
            proteinG: Int(protein) ?? 0,
            carbsG: Int(carbs) ?? 0,
            fatsG: Int(fats) ?? 0
        )
        
        do {
            _ = try await service.createMeal(payload)
            onSave()
            dismiss()
        } catch {
            // handle error
        }
    }
}
