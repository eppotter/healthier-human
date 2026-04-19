import SwiftUI
import SwiftData

@main
struct HealthierHumanApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            UserProfile.self,
            Food.self,
            FoodEntry.self,
            WaterLog.self
        ])
    }
}
