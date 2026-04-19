import Foundation

// MARK: - Input types

/// Biological sex, used in the Mifflin-St Jeor formula.
enum BiologicalSex {
    case male
    case female
}

/// How active the user is day-to-day.
enum ActivityLevel: Double {
    case sedentary        = 1.2
    case lightlyActive    = 1.375
    case moderatelyActive = 1.55
    case veryActive       = 1.725
    case extraActive      = 1.9
}

/// The user's chosen weight goal.
enum WeightGoal: Double {
    case maintain         =    0
    case loseHalfPound    = -250
    case loseOnePound     = -500
    case loseOneHalfPound = -750
    case loseTwoPounds    = -1000
}

// MARK: - Calculator

/// Pure-Swift calorie calculation engine.
/// No UIKit, SwiftUI, or SwiftData imports — fully unit-testable.
///
/// All public functions are free functions (no shared state).
/// See docs/calorie-calculation.md for the full spec and worked examples.
enum CalorieCalculator {

    // MARK: Unit conversion

    /// Converts pounds to kilograms.
    static func kilograms(fromPounds pounds: Double) -> Double {
        pounds * 0.453592
    }

    /// Converts a height in feet + inches to centimetres.
    static func centimetres(fromFeet feet: Int, inches: Double) -> Double {
        (Double(feet) * 12 + inches) * 2.54
    }

    // MARK: Step 1 — BMR (Mifflin-St Jeor)

    /// Calculates Basal Metabolic Rate in calories/day.
    /// - Parameters:
    ///   - weightKg: Body weight in kilograms.
    ///   - heightCm: Height in centimetres.
    ///   - age: Age in whole years.
    ///   - sex: Biological sex.
    static func bmr(weightKg: Double, heightCm: Double, age: Int, sex: BiologicalSex) -> Double {
        let base = (10 * weightKg) + (6.25 * heightCm) - (5 * Double(age))
        switch sex {
        case .male:   return base + 5
        case .female: return base - 161
        }
    }

    // MARK: Step 2 — TDEE

    /// Calculates Total Daily Energy Expenditure in calories/day.
    static func tdee(bmr: Double, activityLevel: ActivityLevel) -> Double {
        bmr * activityLevel.rawValue
    }

    // MARK: Step 3 — Daily calorie target

    /// The safety floor below which we never recommend going.
    static func safetyFloor(for sex: BiologicalSex) -> Double {
        switch sex {
        case .male:   return 1500
        case .female: return 1200
        }
    }

    /// Returns the recommended daily calorie target, clamped to the safety floor.
    /// - Returns: A `CalorieTarget` containing the final value and a flag
    ///   indicating whether the floor was applied.
    static func dailyTarget(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        sex: BiologicalSex,
        activityLevel: ActivityLevel,
        goal: WeightGoal
    ) -> CalorieTarget {
        let bmrValue  = bmr(weightKg: weightKg, heightCm: heightCm, age: age, sex: sex)
        let tdeeValue = tdee(bmr: bmrValue, activityLevel: activityLevel)
        let raw       = tdeeValue + goal.rawValue   // goal adjustment is negative for loss
        let floor     = safetyFloor(for: sex)
        let clamped   = raw < floor

        return CalorieTarget(
            calories: Int(clamped ? floor : raw.rounded()),
            wasClampedToFloor: clamped,
            floor: Int(floor)
        )
    }
}

// MARK: - Output type

/// The result of a calorie target calculation.
struct CalorieTarget: Equatable {
    /// The recommended daily calorie intake.
    let calories: Int
    /// `true` if the goal math went below the safety floor and was clamped.
    let wasClampedToFloor: Bool
    /// The floor value that was applied (1200 for women, 1500 for men).
    let floor: Int
}
