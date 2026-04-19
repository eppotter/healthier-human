import SwiftUI
import SwiftData

struct DailyTrackerView: View {
    let profile: UserProfile

    @State private var selectedDate = Date()
    @State private var addingMealType: MealType? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Date navigator
                    DateNavigator(selectedDate: $selectedDate)

                    // Calorie summary
                    CalorieSummaryCard(profile: profile, date: selectedDate)

                    // Meal sections
                    ForEach(MealType.allCases, id: \.self) { meal in
                        MealSectionView(
                            mealType: meal,
                            date: selectedDate,
                            onAddFood: { addingMealType = meal }
                        )
                    }

                    // Water tracker
                    WaterTrackerCard(date: selectedDate)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $addingMealType) { meal in
            AddFoodView(mealType: meal, date: selectedDate)
        }
    }
}

// MARK: - Date Navigator

private struct DateNavigator: View {
    @Binding var selectedDate: Date

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        HStack {
            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
            .accessibilityLabel("Previous day")

            Spacer()

            VStack(spacing: 2) {
                Text(isToday ? "Today" : selectedDate.formatted(.dateTime.weekday(.wide)))
                    .font(.headline)
                Text(selectedDate.formatted(.dateTime.month().day().year()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(isToday ? Color.secondary : Color.green)
            }
            .disabled(isToday)
            .accessibilityLabel("Next day")
        }
        .padding(.top, 8)
    }
}

// MARK: - Calorie Summary

private struct CalorieSummaryCard: View {
    let profile: UserProfile
    let date: Date

    @Query private var allEntries: [FoodEntry]

    init(profile: UserProfile, date: Date) {
        self.profile = profile
        self.date = date
        let start = Calendar.current.startOfDay(for: date)
        let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        _allEntries = Query(filter: #Predicate<FoodEntry> { e in
            e.date >= start && e.date < end
        })
    }

    private var consumed: Int {
        Int(allEntries.reduce(0) { $0 + $1.calories })
    }

    private var target: CalorieTarget { profile.calorieTarget }
    private var remaining: Int { target.calories - consumed }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                StatPill(label: "Target", value: "\(target.calories)", color: .primary)
                Spacer()
                StatPill(label: "Eaten", value: "\(consumed)", color: .orange)
                Spacer()
                StatPill(label: "Remaining", value: "\(remaining)", color: remaining >= 0 ? .green : .red)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(remaining >= 0 ? Color.green : Color.red)
                        .frame(width: geo.size.width * min(Double(consumed) / Double(max(target.calories, 1)), 1.0))
                }
            }
            .frame(height: 12)

            if target.wasClampedToFloor {
                Label("Calories capped at recommended minimum (\(target.floor) cal).", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2).bold()
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 70)
    }
}

// MARK: - Meal Section

private struct MealSectionView: View {
    let mealType: MealType
    let date: Date
    let onAddFood: () -> Void

    @Query private var entries: [FoodEntry]
    @Environment(\.modelContext) private var modelContext

    init(mealType: MealType, date: Date, onAddFood: @escaping () -> Void) {
        self.mealType = mealType
        self.date = date
        self.onAddFood = onAddFood
        let start = Calendar.current.startOfDay(for: date)
        let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let raw   = mealType.rawValue
        _entries = Query(filter: #Predicate<FoodEntry> { e in
            e.date >= start && e.date < end && e.mealTypeRaw == raw
        })
    }

    private var totalCalories: Int {
        Int(entries.reduce(0) { $0 + $1.calories })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(mealType.emoji)
                Text(mealType.rawValue)
                    .font(.headline)
                Spacer()
                Text("\(totalCalories) cal")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button(action: onAddFood) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
                .accessibilityLabel("Add food to \(mealType.rawValue)")
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            if entries.isEmpty {
                Text("Nothing logged yet")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            } else {
                Divider().padding(.horizontal)
                ForEach(entries) { entry in
                    FoodEntryRow(entry: entry)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modelContext.delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct FoodEntryRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.subheadline)
                if let g = entry.grams {
                    Text("\(Int(g)) g")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let s = entry.servings {
                    Text("\(String(format: "%.1f", s)) serving\(s == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(Int(entry.calories)) cal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// MARK: - Water Tracker

private struct WaterTrackerCard: View {
    let date: Date

    @Query private var logs: [WaterLog]
    @Environment(\.modelContext) private var modelContext

    init(date: Date) {
        self.date = date
        let start = Calendar.current.startOfDay(for: date)
        let end   = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        _logs = Query(filter: #Predicate<WaterLog> { w in
            w.date >= start && w.date < end
        })
    }

    private var log: WaterLog? { logs.first }
    private var glasses: Int { log?.glasses ?? 0 }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Water", systemImage: "drop.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Spacer()
                Text("\(glasses) / 8 glasses")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                ForEach(0..<8, id: \.self) { i in
                    Image(systemName: i < glasses ? "drop.fill" : "drop")
                        .font(.title3)
                        .foregroundStyle(i < glasses ? Color.blue : Color(.systemGray4))
                        .onTapGesture {
                            setGlasses(i < glasses ? i : i + 1)
                        }
                        .accessibilityLabel(i < glasses ? "Glass \(i + 1), logged" : "Glass \(i + 1), tap to log")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func setGlasses(_ count: Int) {
        if let existing = log {
            existing.glasses = count
        } else {
            let newLog = WaterLog(date: date, glasses: count)
            modelContext.insert(newLog)
        }
    }
}
