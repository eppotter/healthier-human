import SwiftUI
import SwiftData

/// Multi-step onboarding that collects the user's stats and creates their profile.
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var step = 0

    // Form state
    @State private var weightLbs: String = ""
    @State private var heightFeet: String = ""
    @State private var heightInches: String = ""
    @State private var age: String = ""
    @State private var sex: BiologicalSex = .female
    @State private var activityLevel: ActivityLevel = .sedentary
    @State private var weightGoal: WeightGoal = .maintain

    private let totalSteps = 6

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(step + 1), total: Double(totalSteps))
                .tint(.green)
                .padding(.horizontal)
                .padding(.top)

            TabView(selection: $step) {
                welcomeStep.tag(0)
                weightStep.tag(1)
                heightStep.tag(2)
                ageStep.tag(3)
                activityStep.tag(4)
                goalStep.tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        OnboardingStepContainer(
            title: "Welcome to\nHealthier Human",
            subtitle: "Let's set up your personal calorie target. It only takes a minute.",
            systemImage: "fork.knife.circle.fill",
            imageColor: .green,
            canContinue: true,
            onNext: { step = 1 }
        ) { EmptyView() }
    }

    private var weightStep: some View {
        OnboardingStepContainer(
            title: "What's your\ncurrent weight?",
            subtitle: "Used to calculate your daily calorie target.",
            systemImage: "scalemass.fill",
            imageColor: .blue,
            canContinue: !weightLbs.isEmpty && Double(weightLbs) != nil,
            onNext: { step = 2 }
        ) {
            HStack {
                TextField("e.g. 165", text: $weightLbs)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 140)
                Text("lbs")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var heightStep: some View {
        OnboardingStepContainer(
            title: "How tall are you?",
            subtitle: "Used to calculate your daily calorie target.",
            systemImage: "arrow.up.and.down",
            imageColor: .orange,
            canContinue: !heightFeet.isEmpty && Int(heightFeet) != nil,
            onNext: { step = 3 }
        ) {
            HStack(spacing: 12) {
                HStack {
                    TextField("5", text: $heightFeet)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 70)
                    Text("ft")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    TextField("8", text: $heightInches)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 70)
                    Text("in")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var ageStep: some View {
        OnboardingStepContainer(
            title: "How old are you?",
            subtitle: "Metabolism changes with age — this keeps the math accurate.",
            systemImage: "birthday.cake.fill",
            imageColor: .pink,
            canContinue: !age.isEmpty && Int(age) != nil,
            onNext: { step = 4 }
        ) {
            HStack {
                TextField("e.g. 32", text: $age)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 100)
                Text("years")
                    .foregroundStyle(.secondary)
            }

            Picker("Sex", selection: $sex) {
                Text("Female").tag(BiologicalSex.female)
                Text("Male").tag(BiologicalSex.male)
            }
            .pickerStyle(.segmented)
            .padding(.top, 8)
        }
    }

    private var activityStep: some View {
        OnboardingStepContainer(
            title: "How active are you?",
            subtitle: "Think about a typical week, including work and exercise.",
            systemImage: "figure.walk",
            imageColor: .purple,
            canContinue: true,
            onNext: { step = 5 }
        ) {
            VStack(spacing: 10) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    ActivityRow(level: level, selected: activityLevel == level)
                        .onTapGesture { activityLevel = level }
                }
            }
        }
    }

    private var goalStep: some View {
        OnboardingStepContainer(
            title: "What's your goal?",
            subtitle: "We'll adjust your calorie target to match.",
            systemImage: "target",
            imageColor: .red,
            canContinue: true,
            onNext: saveAndFinish
        ) {
            VStack(spacing: 10) {
                ForEach(WeightGoal.allCases, id: \.self) { goal in
                    GoalRow(goal: goal, selected: weightGoal == goal)
                        .onTapGesture { weightGoal = goal }
                }
            }

            // Live preview of calorie target
            if let w = Double(weightLbs),
               let f = Int(heightFeet),
               let a = Int(age) {
                let inches = Double(heightInches) ?? 0
                let target = CalorieCalculator.dailyTarget(
                    weightKg: CalorieCalculator.kilograms(fromPounds: w),
                    heightCm: CalorieCalculator.centimetres(fromFeet: f, inches: inches),
                    age: a,
                    sex: sex,
                    activityLevel: activityLevel,
                    goal: weightGoal
                )
                CalorieTargetPreview(target: target, sex: sex)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Save

    private func saveAndFinish() {
        guard let w = Double(weightLbs),
              let f = Int(heightFeet),
              let a = Int(age) else { return }
        let inches = Double(heightInches) ?? 0
        let profile = UserProfile(
            weightKg: CalorieCalculator.kilograms(fromPounds: w),
            heightCm: CalorieCalculator.centimetres(fromFeet: f, inches: inches),
            age: a,
            sex: sex,
            activityLevel: activityLevel,
            weightGoal: weightGoal
        )
        modelContext.insert(profile)
    }
}

// MARK: - Supporting views

private struct OnboardingStepContainer<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let imageColor: Color
    let canContinue: Bool
    let onNext: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: systemImage)
                    .font(.system(size: 60))
                    .foregroundStyle(imageColor)
                    .padding(.top, 32)

                VStack(spacing: 8) {
                    Text(title)
                        .font(.largeTitle).bold()
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                content()
                    .padding(.horizontal)

                Button(action: onNext) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canContinue ? Color.green : Color.gray.opacity(0.3))
                        .foregroundStyle(canContinue ? .white : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canContinue)
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
    }
}

private struct ActivityRow: View {
    let level: ActivityLevel
    let selected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(level.displayName)
                    .font(.headline)
                Text(level.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(selected ? Color.green.opacity(0.1) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct GoalRow: View {
    let goal: WeightGoal
    let selected: Bool

    var body: some View {
        HStack {
            Text(goal.displayName)
                .font(.headline)
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(selected ? Color.green.opacity(0.1) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct CalorieTargetPreview: View {
    let target: CalorieTarget
    let sex: BiologicalSex

    var body: some View {
        VStack(spacing: 8) {
            Text("Your daily target")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(target.calories)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
            Text("calories / day")
                .font(.caption)
                .foregroundStyle(.secondary)

            if target.wasClampedToFloor {
                Label(
                    "Your goal would require fewer calories than the recommended minimum; we've capped it at \(target.floor). Consult a healthcare professional if you want to go lower.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - CaseIterable conformances

extension ActivityLevel: CaseIterable {
    public static var allCases: [ActivityLevel] {
        [.sedentary, .lightlyActive, .moderatelyActive, .veryActive, .extraActive]
    }
    var displayName: String {
        switch self {
        case .sedentary:        "Sedentary"
        case .lightlyActive:    "Lightly Active"
        case .moderatelyActive: "Moderately Active"
        case .veryActive:       "Very Active"
        case .extraActive:      "Extra Active"
        }
    }
    var description: String {
        switch self {
        case .sedentary:        "Desk job, little or no exercise"
        case .lightlyActive:    "Light exercise 1–3 days/week"
        case .moderatelyActive: "Moderate exercise 3–5 days/week"
        case .veryActive:       "Hard exercise 6–7 days/week"
        case .extraActive:      "Very hard exercise or physical job"
        }
    }
}

extension WeightGoal: CaseIterable {
    public static var allCases: [WeightGoal] {
        [.maintain, .loseHalfPound, .loseOnePound, .loseOneHalfPound, .loseTwoPounds]
    }
    var displayName: String {
        switch self {
        case .maintain:           "Maintain weight"
        case .loseHalfPound:      "Lose 0.5 lb / week"
        case .loseOnePound:       "Lose 1 lb / week"
        case .loseOneHalfPound:   "Lose 1.5 lb / week"
        case .loseTwoPounds:      "Lose 2 lb / week  (max)"
        }
    }
}
