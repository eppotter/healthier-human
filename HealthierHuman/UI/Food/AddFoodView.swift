import SwiftUI
import SwiftData

/// Sheet for logging a food item to a meal.
/// Shows saved foods first, plus a manual-entry form.
struct AddFoodView: View {
    let mealType: MealType
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var showingManualEntry = false

    @Query(sort: \Food.name) private var savedFoods: [Food]

    private var filteredFoods: [Food] {
        if searchText.isEmpty { return savedFoods }
        return savedFoods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Manual entry button
                Section {
                    Button {
                        showingManualEntry = true
                    } label: {
                        Label("Enter food manually", systemImage: "square.and.pencil")
                            .foregroundStyle(.green)
                    }
                }

                // Saved foods
                if !filteredFoods.isEmpty {
                    Section("Saved Foods") {
                        ForEach(filteredFoods) { food in
                            SavedFoodRow(food: food) {
                                logSavedFood(food)
                            }
                        }
                    }
                } else if !searchText.isEmpty {
                    Section {
                        Text("No saved foods match \"\(searchText)\"")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search saved foods")
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualFoodEntryView(mealType: mealType, date: date)
            }
        }
    }

    private func logSavedFood(_ food: Food) {
        // Default to 1 serving if no per-100g data; else log 100g
        let entry: FoodEntry
        if food.caloriesPer100g != nil {
            entry = FoodEntry(food: food, grams: 100, mealType: mealType, date: date)
        } else {
            entry = FoodEntry(food: food, servings: 1, mealType: mealType, date: date)
        }
        modelContext.insert(entry)
        dismiss()
    }
}

// MARK: - Saved food row

private struct SavedFoodRow: View {
    let food: Food
    let onLog: () -> Void

    private var calLabel: String {
        if let cal = food.caloriesPerServing {
            return "\(Int(cal)) cal / serving"
        }
        if let cal = food.caloriesPer100g {
            return "\(Int(cal)) cal / 100g"
        }
        return ""
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.subheadline)
                if !calLabel.isEmpty {
                    Text(calLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: onLog) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Manual entry

struct ManualFoodEntryView: View {
    let mealType: MealType
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""

    private var canSave: Bool {
        !name.isEmpty && Double(calories) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food name") {
                    TextField("e.g. Chicken breast", text: $name)
                }
                Section("Nutrition (per serving)") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("Required", text: $calories)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("Optional", text: $protein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("Optional", text: $carbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("Optional", text: $fat)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard let cal = Double(calories) else { return }

        // Create a Food reference and save it for future re-use
        let food = Food(
            name: name,
            caloriesPerServing: cal,
            servingDescription: "1 serving",
            proteinPer100g: nil,
            carbsPer100g: nil,
            fatPer100g: nil
        )
        modelContext.insert(food)

        // Create the log entry
        let entry = FoodEntry(food: food, servings: 1, mealType: mealType, date: date)
        entry.manualProtein = Double(protein)
        entry.manualCarbs   = Double(carbs)
        entry.manualFat     = Double(fat)
        modelContext.insert(entry)

        dismiss()
    }
}

// MARK: - MealType Identifiable

extension MealType: Identifiable {
    public var id: String { rawValue }
}
