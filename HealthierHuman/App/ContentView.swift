import SwiftUI

/// Root view — will route to Onboarding or Daily Tracker
/// depending on whether the user has completed setup.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)

            Text("Healthier Human")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Building something great…")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
