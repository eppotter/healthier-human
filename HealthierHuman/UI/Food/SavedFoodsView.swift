import SwiftUI
import SwiftData

/// Browseable list of all foods the user has ever logged.
struct SavedFoodsView: View {
    @Query(sort: \Food.name) private var foods: [Food]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""

    private var filtered: [Food] {
        if searchText.isEmpty { return foods }
        return foods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if foods.isEmpty {
                    ContentUnavailableView(
                        "No saved foods yet",
                        systemImage: "fork.knife",
                        description: Text("Foods you log on the Today tab are saved here automatically for quick re-use.")
                    )
                } else {
                    List {
                        ForEach(filtered) { food in
                            FoodDetailRow(food: food)
                        }
                        .onDelete(perform: deleteFoods)
                    }
                    .searchable(text: $searchText, prompt: "Search foods")
                }
            }
            .navigationTitle("Saved Foods")
        }
    }

    private func deleteFoods(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filtered[index])
        }
    }
}

private struct FoodDetailRow: View {
    let food: Food

    private var calLabel: String {
        if let cal = food.caloriesPerServing {
            let desc = food.servingDescription ?? "serving"
            return "\(Int(cal)) cal / \(desc)"
        }
        if let cal = food.caloriesPer100g {
            return "\(Int(cal)) cal / 100g"
        }
        return "No calorie info"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(food.name)
                .font(.headline)
            Text(calLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if food.proteinPer100g != nil || food.carbsPer100g != nil || food.fatPer100g != nil {
                HStack(spacing: 12) {
                    if let p = food.proteinPer100g {
                        MacroChip(label: "P", value: p, color: .blue)
                    }
                    if let c = food.carbsPer100g {
                        MacroChip(label: "C", value: c, color: .orange)
                    }
                    if let f = food.fatPer100g {
                        MacroChip(label: "F", value: f, color: .yellow)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MacroChip: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        Text("\(label) \(Int(value))g")
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
