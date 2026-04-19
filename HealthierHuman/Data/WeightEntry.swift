import Foundation
import SwiftData

/// A single weight measurement logged by the user.
@Model
final class WeightEntry {
    var date: Date
    var weightKg: Double

    init(date: Date = Date(), weightKg: Double) {
        self.date = date
        self.weightKg = weightKg
    }

    /// Convenience — weight in pounds.
    var weightLbs: Double { weightKg / 0.453592 }
}
