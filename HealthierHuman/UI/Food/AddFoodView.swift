import SwiftUI
import SwiftData

struct AddFoodView: View {
    let mealType: MealType
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedTab: FoodTab = .library
    @State private var showingManualEntry = false

    private var isAlcoholMode: Bool { mealType == .alcohol }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Source", selection: $selectedTab) {
                    ForEach(FoodTab.allCases, id: \.self) { tab in
                        Text(tab.label).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Search bar + content
                switch selectedTab {
                case .library:
                    LibrarySearchView(
                        searchText: $searchText,
                        mealType: mealType,
                        date: date,
                        alcoholOnly: isAlcoholMode,
                        onLogged: { dismiss() },
                        onManualEntry: isAlcoholMode ? nil : { showingManualEntry = true }
                    )
                case .usda:
                    USDASearchView(
                        mealType: mealType,
                        date: date,
                        defaultQuery: isAlcoholMode ? "alcoholic drink beer wine spirits" : "",
                        onLogged: { dismiss() }
                    )
                }
            }
            .navigationTitle(isAlcoholMode ? "Add Drink" : "Add Food")
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
}

enum FoodTab: CaseIterable {
    case library, usda
    var label: String {
        switch self {
        case .library: "My Library"
        case .usda:    "Search USDA"
        }
    }
}

// MARK: - Library tab (bundled + saved foods)

private struct LibrarySearchView: View {
    @Binding var searchText: String
    let mealType: MealType
    let date: Date
    let alcoholOnly: Bool
    let onLogged: () -> Void
    let onManualEntry: (() -> Void)?

    @Query(sort: \Food.name) private var allFoods: [Food]
    @Environment(\.modelContext) private var modelContext

    private var pool: [Food] {
        alcoholOnly ? allFoods.filter { $0.isAlcohol } : allFoods.filter { !$0.isAlcohol }
    }

    private var filtered: [Food] {
        guard !searchText.isEmpty else { return pool }
        let query = searchText.lowercased()
        let exact = pool.filter { $0.name.lowercased().contains(query) }
        if !exact.isEmpty { return exact }
        let queryWords = query.split(separator: " ").map(String.init)
        return pool.filter { food in
            let foodWords = food.name.lowercased().split(separator: " ").map(String.init)
            return queryWords.allSatisfy { qw in foodWords.contains { fw in fw.hasPrefix(qw) } }
        }
    }

    var body: some View {
        List {
            if let manualEntry = onManualEntry {
                Section {
                    Button {
                        manualEntry()
                    } label: {
                        Label("Enter food manually", systemImage: "square.and.pencil")
                            .foregroundStyle(.green)
                    }
                }
            }

            if filtered.isEmpty && !searchText.isEmpty {
                Section {
                    Text("No \(alcoholOnly ? "drinks" : "foods") match \"\(searchText)\".")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section(searchText.isEmpty ? (alcoholOnly ? "Drinks Library" : "Food Library") : "Results") {
                    ForEach(filtered) { food in
                        FoodRow(food: food) { log(food) }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search \(pool.count) \(alcoholOnly ? "drinks" : "foods")…")
    }

    private func log(_ food: Food) {
        let entry: FoodEntry
        if food.caloriesPer100g != nil {
            entry = FoodEntry(food: food, grams: 100, mealType: mealType, date: date)
        } else {
            entry = FoodEntry(food: food, servings: 1, mealType: mealType, date: date)
        }
        modelContext.insert(entry)
        onLogged()
    }
}

// MARK: - USDA tab

private struct USDASearchView: View {
    let mealType: MealType
    let date: Date
    let defaultQuery: String
    let onLogged: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var query = ""
    @State private var results: [USDAFood] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @State private var selectedFood: USDAFood? = nil

    var body: some View {
        List {
            if let err = errorMessage {
                Section {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.subheadline)
                }
            }

            if results.isEmpty && !isSearching && query.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Search 380,000+ foods from the\nUSDA nutrition database.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
                .listRowBackground(Color.clear)
            }

            if isSearching {
                Section {
                    HStack {
                        ProgressView()
                        Text("Searching…").foregroundStyle(.secondary)
                    }
                }
            }

            if !results.isEmpty {
                Section("\(results.count) results for \"\(query)\"") {
                    ForEach(results) { food in
                        USDAFoodRow(food: food) {
                            selectedFood = food
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: mealType == .alcohol ? "e.g. beer, wine, margarita" : "e.g. grilled chicken, greek yogurt")
        .onSubmit(of: .search) { performSearch() }
        .onAppear { if !defaultQuery.isEmpty { query = defaultQuery; performSearch() } }
        .sheet(item: $selectedFood) { food in
            USDAFoodDetailView(food: food, mealType: mealType, date: date, onLogged: onLogged)
        }
    }

    private func performSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        errorMessage = nil
        results = []
        Task {
            do {
                let found = try await USDAClient.shared.search(query: query)
                results = found
            } catch {
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }
}

private struct USDAFoodRow: View {
    let food: USDAFood
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    if let cal = food.caloriesPer100g {
                        Text("\(Int(cal)) cal / 100g")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - USDA detail / portion picker

struct USDAFoodDetailView: View {
    let food: USDAFood
    let mealType: MealType
    let date: Date
    let onLogged: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var grams: String = "100"

    private var calories: Double {
        guard let g = Double(grams), let cal = food.caloriesPer100g else { return 0 }
        return (g / 100) * cal
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    Text(food.displayName)
                        .font(.headline)
                }

                Section("Portion") {
                    HStack {
                        TextField("100", text: $grams)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                        Text("grams")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(calories)) cal")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                }

                Section("Nutrition per 100g") {
                    if let cal = food.caloriesPer100g { NutritionRow(label: "Calories",      value: cal, unit: "kcal") }
                    if let p   = food.proteinPer100g  { NutritionRow(label: "Protein",        value: p,   unit: "g")    }
                    if let c   = food.carbsPer100g    { NutritionRow(label: "Carbohydrates",  value: c,   unit: "g")    }
                    if let f   = food.fatPer100g      { NutritionRow(label: "Fat",            value: f,   unit: "g")    }
                }
            }
            .navigationTitle("Add to \(mealType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { log() }
                        .disabled(Double(grams) == nil || Double(grams)! <= 0)
                }
            }
        }
    }

    private func log() {
        guard let g = Double(grams) else { return }
        // Save to library for future re-use
        let savedFood = Food(
            name: food.displayName,
            caloriesPer100g: food.caloriesPer100g,
            proteinPer100g:  food.proteinPer100g,
            carbsPer100g:    food.carbsPer100g,
            fatPer100g:      food.fatPer100g,
            source: .usda,
            isAlcohol: mealType == .alcohol
        )
        modelContext.insert(savedFood)
        let entry = FoodEntry(food: savedFood, grams: g, mealType: mealType, date: date)
        modelContext.insert(entry)
        onLogged()
        dismiss()
    }
}

private struct NutritionRow: View {
    let label: String
    let value: Double
    let unit: String
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(String(format: "%.1f", value)) \(unit)")
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Shared food row

struct FoodRow: View {
    let food: Food
    let onLog: () -> Void

    private var calLabel: String {
        if let cal = food.caloriesPerServing, let desc = food.servingDescription {
            return "\(Int(cal)) cal / \(desc)"
        }
        if let cal = food.caloriesPer100g {
            return "\(Int(cal)) cal / 100g"
        }
        return ""
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name).font(.subheadline)
                if !calLabel.isEmpty {
                    Text(calLabel).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: onLog) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3).foregroundStyle(.green)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Manual entry (unchanged)

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

    private var canSave: Bool { !name.isEmpty && Double(calories) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food name") {
                    TextField("e.g. Chicken breast", text: $name)
                }
                Section("Nutrition (per serving)") {
                    nutrientRow("Calories", text: $calories, required: true)
                    nutrientRow("Protein (g)", text: $protein)
                    nutrientRow("Carbs (g)",   text: $carbs)
                    nutrientRow("Fat (g)",     text: $fat)
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }.disabled(!canSave)
                }
            }
        }
    }

    @ViewBuilder
    private func nutrientRow(_ label: String, text: Binding<String>, required: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(required ? "Required" : "Optional", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func save() {
        guard let cal = Double(calories) else { return }
        let food = Food(name: name, caloriesPerServing: cal, servingDescription: "1 serving", source: .manual)
        modelContext.insert(food)
        let entry = FoodEntry(food: food, servings: 1, mealType: mealType, date: date)
        entry.manualProtein = Double(protein)
        entry.manualCarbs   = Double(carbs)
        entry.manualFat     = Double(fat)
        modelContext.insert(entry)
        dismiss()
    }
}
