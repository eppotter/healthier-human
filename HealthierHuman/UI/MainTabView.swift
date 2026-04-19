import SwiftUI

struct MainTabView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            DailyTrackerView(profile: profile)
                .tabItem {
                    Label("Today", systemImage: "fork.knife")
                }

            SavedFoodsView()
                .tabItem {
                    Label("Foods", systemImage: "list.bullet")
                }

            SettingsView(profile: profile)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(.green)
    }
}
