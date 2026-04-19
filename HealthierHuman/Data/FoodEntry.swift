import Foundation
import SwiftData

/// A single logged food item — one row per thing a user ate.
/// Stores raw inputs (food reference + quantity), never pre-summed totals.
@Model
final class FoodEntry {
    var date: Date
    var mealTypeRaw: String

    /// Grams consumed — nil if the food is measured by serving instead.
    var grams: Double?
    /// Number of servings — nil if measured by weight.
    var servings: Double?

    /// Manual overrides (used when the user types calories directly without a food reference)
    var manualCalories: Double?
    var manualProtein: Double?
    var manualCarbs: Double?
    var manualFat: Double?
    var manualName: String?

    @Relationship(deleteRule: .nullify)
    var food: Food?

    init(
        food: Food? = nil,
        grams: Double? = nil,
        servings: Double? = nil,
        mealType: MealType,
        date: Date = Date()
    ) {
        self.food = food
        self.grams = grams
        self.servings = servings
        self.mealTypeRaw = mealType.rawValue
        self.date = date
    }

    var mealType: MealType {
        MealType(rawValue: mealTypeRaw) ?? .snack
    }

    // MARK: - Computed nutrition values

    var calories: Double {
        if let manual = manualCalories { return manual }
        guard let food else { return 0 }

        if let g = grams, let per100g = food.caloriesPer100g {
            return (g / 100) * per100g
        }
        if let s = servings, let perServing = food.caloriesPerServing {
            return s * perServing
        }
        return 0
    }

    var protein: Double {
        if let manual = manualProtein { return manual }
        guard let food, let g = grams, let per100g = food.proteinPer100g else { return 0 }
        return (g / 100) * per100g
    }

    var carbs: Double {
        if let manual = manualCarbs { return manual }
        guard let food, let g = grams, let per100g = food.carbsPer100g else { return 0 }
        return (g / 100) * per100g
    }

    var fat: Double {
        if let manual = manualFat { return manual }
        guard let food, let g = grams, let per100g = food.fatPer100g else { return 0 }
        return (g / 100) * per100g
    }

    var displayName: String {
        manualName ?? food?.name ?? "Unknown food"
    }
}

enum MealType: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case breakfast = "Breakfast"
    case lunch     = "Lunch"
    case dinner    = "Dinner"
    case snack     = "Snack"

    var emoji: String {
        switch self {
        case .breakfast: "🌅"
        case .lunch:     "☀️"
        case .dinner:    "🌙"
        case .snack:     "🍎"
        }
    }
}
