import SwiftUI
import SwiftData

/// Routes the user to Onboarding (first launch) or the Daily Tracker (returning user).
/// Also triggers the one-time food database seed on first run.
struct RootView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if profiles.isEmpty {
                OnboardingView()
            } else {
                MainTabView(profile: profiles[0])
            }
        }
        .onAppear {
            FoodDatabaseSeeder.seedIfNeeded(context: modelContext)
        }
    }
}
