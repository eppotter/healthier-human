import Foundation
import SwiftData

/// A reference food item — the "menu" of things a user can log.
/// Created automatically whenever a user logs a new food manually.
/// In Phase 2, also created from USDA search results.
@Model
final class Food {
    var name: String
    var caloriesPer100g: Double?
    var proteinPer100g: Double?
    var carbsPer100g: Double?
    var fatPer100g: Double?

    /// Fixed calories per serving (used when the food isn't measured by weight).
    var caloriesPerServing: Double?
    var servingDescription: String?   // e.g. "1 slice", "1 cup"

    /// Where this food came from.
    var sourceRaw: String
    /// True if this food is an alcoholic drink — used to filter the Alcohol section.
    var isAlcohol: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var entries: [FoodEntry] = []

    init(
        name: String,
        caloriesPerServing: Double? = nil,
        servingDescription: String? = nil,
        caloriesPer100g: Double? = nil,
        proteinPer100g: Double? = nil,
        carbsPer100g: Double? = nil,
        fatPer100g: Double? = nil,
        source: FoodSource = .manual,
        isAlcohol: Bool = false
    ) {
        self.name = name
        self.caloriesPerServing = caloriesPerServing
        self.servingDescription = servingDescription
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.sourceRaw = source.rawValue
        self.isAlcohol = isAlcohol
        self.createdAt = Date()
    }

    var source: FoodSource {
        FoodSource(rawValue: sourceRaw) ?? .manual
    }
}

enum FoodSource: String {
    case manual        // user typed it in
    case bundled       // shipped with the app (CommonFoods.json)
    case usda          // USDA FoodData Central API
    case openFoodFacts // phase 3
}
