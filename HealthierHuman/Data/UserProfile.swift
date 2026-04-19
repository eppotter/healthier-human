import Foundation
import SwiftData

/// Stores the user's personal stats and goal.
/// This is a singleton — only one row ever exists.
@Model
final class UserProfile {
    var weightKg: Double
    var heightCm: Double
    var age: Int
    /// "male" or "female" — stored as String for SwiftData compatibility
    var sexRaw: String
    var activityLevelRaw: Double
    var weightGoalRaw: Double
    var createdAt: Date
    var updatedAt: Date

    init(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        sex: BiologicalSex,
        activityLevel: ActivityLevel,
        weightGoal: WeightGoal
    ) {
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.age = age
        self.sexRaw = sex == .male ? "male" : "female"
        self.activityLevelRaw = activityLevel.rawValue
        self.weightGoalRaw = weightGoal.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var sex: BiologicalSex {
        get { sexRaw == "male" ? .male : .female }
        set { sexRaw = newValue == .male ? "male" : "female" }
    }

    var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRaw) ?? .sedentary }
        set { activityLevelRaw = newValue.rawValue }
    }

    var weightGoal: WeightGoal {
        get { WeightGoal(rawValue: weightGoalRaw) ?? .maintain }
        set { weightGoalRaw = newValue.rawValue }
    }

    /// Computes the current calorie target from stored stats.
    var calorieTarget: CalorieTarget {
        CalorieCalculator.dailyTarget(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            sex: sex,
            activityLevel: activityLevel,
            goal: weightGoal
        )
    }
}
