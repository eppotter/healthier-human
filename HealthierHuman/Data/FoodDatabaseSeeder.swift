import Foundation
import SwiftData

/// Loads CommonFoods.json into SwiftData once on first launch.
/// Subsequent launches are skipped using a UserDefaults version flag.
enum FoodDatabaseSeeder {
    private static let seededVersionKey = "com.healthierhuman.fooddb.seeded.v1"

    /// Call this at app startup. No-op after the first run.
    static func seedIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seededVersionKey) else { return }
        guard let url  = Bundle.main.url(forResource: "CommonFoods", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raws = try? JSONDecoder().decode([RawFood].self, from: data) else { return }

        for raw in raws {
            let food = Food(
                name: raw.name,
                caloriesPerServing: raw.caloriesPerServing,
                servingDescription: raw.servingDescription,
                caloriesPer100g: raw.caloriesPer100g,
                proteinPer100g: raw.proteinPer100g,
                carbsPer100g: raw.carbsPer100g,
                fatPer100g: raw.fatPer100g,
                source: .bundled
            )
            context.insert(food)
        }

        UserDefaults.standard.set(true, forKey: seededVersionKey)
    }

    // MARK: - Private DTO

    private struct RawFood: Decodable {
        let name: String
        let caloriesPer100g: Double?
        let caloriesPerServing: Double?
        let servingDescription: String?
        let proteinPer100g: Double?
        let carbsPer100g: Double?
        let fatPer100g: Double?
    }
}
