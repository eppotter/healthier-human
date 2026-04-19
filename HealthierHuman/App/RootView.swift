import SwiftUI
import SwiftData

/// Routes the user to Onboarding (first launch) or the Daily Tracker (returning user).
struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if profiles.isEmpty {
            OnboardingView()
        } else {
            MainTabView(profile: profiles[0])
        }
    }
}
