import Foundation
import SwiftData

/// Tracks water intake — one row per day.
@Model
final class WaterLog {
    /// The day this log belongs to (time component stripped — midnight UTC).
    var date: Date
    var glasses: Int

    init(date: Date = Date(), glasses: Int = 0) {
        self.date = Calendar.current.startOfDay(for: date)
        self.glasses = glasses
    }
}
