import SwiftUI
import SwiftData

@main
struct HealthierHumanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            // SwiftData models will be added here as we build them
        ])
    }
}
