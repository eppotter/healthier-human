import SwiftUI
import SwiftData

struct SettingsView: View {
    @Bindable var profile: UserProfile

    @State private var weightLbs: String = ""
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var age: String = ""
    @State private var hasLoaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Your stats") {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("lbs", text: $weightLbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("lbs").foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Height")
                        Spacer()
                        TextField("ft", text: $heightFeet)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 40)
                        Text("ft").foregroundStyle(.secondary)
                        TextField("in", text: $heightInches)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 40)
                        Text("in").foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("years", text: $age)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("yrs").foregroundStyle(.secondary)
                    }

                    Picker("Sex", selection: $profile.sex) {
                        Text("Female").tag(BiologicalSex.female)
                        Text("Male").tag(BiologicalSex.male)
                    }
                }

                Section("Activity level") {
                    Picker("Activity", selection: $profile.activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    Text(profile.activityLevel.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Goal") {
                    Picker("Goal", selection: $profile.weightGoal) {
                        ForEach(WeightGoal.allCases, id: \.self) { goal in
                            Text(goal.displayName).tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Live calorie target preview
                Section("Your daily calorie target") {
                    let target = profile.calorieTarget
                    HStack {
                        Text("Target")
                        Spacer()
                        Text("\(target.calories) cal / day")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                    if target.wasClampedToFloor {
                        Label(
                            "Your goal would require fewer calories than the recommended minimum; we've capped it at \(target.floor). Consult a healthcare professional if you want to go lower.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { loadFromProfile() }
            .onChange(of: weightLbs)    { saveWeight() }
            .onChange(of: heightFeet)   { saveHeight() }
            .onChange(of: heightInches) { saveHeight() }
            .onChange(of: age)          { saveAge() }
        }
    }

    // MARK: - Load / Save

    private func loadFromProfile() {
        guard !hasLoaded else { return }
        hasLoaded = true
        let lbs = profile.weightKg / 0.453592
        weightLbs = String(format: "%.1f", lbs)
        let totalInches = profile.heightCm / 2.54
        heightFeet   = "\(Int(totalInches) / 12)"
        heightInches = "\(Int(totalInches) % 12)"
        age = "\(profile.age)"
    }

    private func saveWeight() {
        guard let lbs = Double(weightLbs) else { return }
        profile.weightKg = lbs * 0.453592
        profile.updatedAt = Date()
    }

    private func saveHeight() {
        guard let f = Int(heightFeet) else { return }
        let i = Double(heightInches) ?? 0
        profile.heightCm = (Double(f * 12) + i) * 2.54
        profile.updatedAt = Date()
    }

    private func saveAge() {
        guard let a = Int(age) else { return }
        profile.age = a
        profile.updatedAt = Date()
    }
}
