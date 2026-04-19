import SwiftUI
import SwiftData
import Charts

struct WeightTrackerView: View {
    @Query(sort: \WeightEntry.date) private var entries: [WeightEntry]
    @Environment(\.modelContext) private var modelContext
    @State private var showingLogWeight = false
    @State private var selectedRange: ChartRange = .month

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if entries.isEmpty {
                        emptyState
                    } else {
                        summaryCard
                        chartCard
                        historyList
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Weight")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingLogWeight = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingLogWeight) {
                LogWeightView()
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            Image(systemName: "scalemass.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue.opacity(0.7))
            Text("No weight logged yet")
                .font(.title2).bold()
            Text("Tap + to log your first weight entry and start tracking your progress.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                showingLogWeight = true
            } label: {
                Label("Log Weight", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        HStack(spacing: 0) {
            if let latest = entries.last {
                StatBlock(label: "Current", value: String(format: "%.1f", latest.weightLbs), unit: "lbs", color: .blue)
            }
            Divider().frame(height: 50)
            if let first = entries.first, let latest = entries.last, entries.count > 1 {
                let delta = latest.weightLbs - first.weightLbs
                StatBlock(
                    label: "Change",
                    value: String(format: "%+.1f", delta),
                    unit: "lbs",
                    color: delta <= 0 ? .green : .orange
                )
            } else {
                StatBlock(label: "Change", value: "—", unit: "", color: .secondary)
            }
            Divider().frame(height: 50)
            StatBlock(label: "Entries", value: "\(entries.count)", unit: "logged", color: .primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Chart

    private var visibleEntries: [WeightEntry] {
        let cutoff: Date
        switch selectedRange {
        case .week:  cutoff = Calendar.current.date(byAdding: .day,   value: -7,  to: Date())!
        case .month: cutoff = Calendar.current.date(byAdding: .month, value: -1,  to: Date())!
        case .threeMonths: cutoff = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        case .all:   cutoff = .distantPast
        }
        return entries.filter { $0.date >= cutoff }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                Picker("Range", selection: $selectedRange) {
                    ForEach(ChartRange.allCases, id: \.self) { range in
                        Text(range.label).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }

            let data = visibleEntries
            if data.count < 2 {
                Text("Log at least 2 entries to see your chart.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                let minW = (data.map(\.weightLbs).min() ?? 100) - 3
                let maxW = (data.map(\.weightLbs).max() ?? 200) + 3

                Chart(data) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weightLbs)
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", entry.date),
                        yStart: .value("Min", minW),
                        yEnd: .value("Weight", entry.weightLbs)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weightLbs)
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(30)
                }
                .chartYScale(domain: minW...maxW)
                .chartYAxis {
                    AxisMarks(position: .leading) { val in
                        AxisValueLabel {
                            if let d = val.as(Double.self) {
                                Text("\(Int(d)) lbs")
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { val in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(.caption2)
                        AxisGridLine()
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - History list

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("History")
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 12)

            Divider().padding(.horizontal)

            ForEach(entries.reversed()) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.date.formatted(.dateTime.weekday(.wide).month().day().year()))
                            .font(.subheadline)
                        Text(entry.date.formatted(.dateTime.hour().minute()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(String(format: "%.1f lbs", entry.weightLbs))
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        modelContext.delete(entry)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                Divider().padding(.horizontal)
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Log Weight Sheet

struct LogWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var recent: [WeightEntry]

    @State private var weightText = ""
    @State private var date = Date()

    private var canSave: Bool {
        guard let w = Double(weightText) else { return false }
        return w > 0 && w < 1000
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight") {
                    HStack {
                        TextField(recentPlaceholder, text: $weightText)
                            .keyboardType(.decimalPad)
                        Text("lbs").foregroundStyle(.secondary)
                    }
                }
                Section("Date & time") {
                    DatePicker("When", selection: $date)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var recentPlaceholder: String {
        if let last = recent.first {
            return String(format: "%.1f", last.weightLbs)
        }
        return "e.g. 165.0"
    }

    private func save() {
        guard let lbs = Double(weightText) else { return }
        let entry = WeightEntry(date: date, weightKg: lbs * 0.453592)
        modelContext.insert(entry)
        dismiss()
    }
}

// MARK: - Supporting types

private struct StatBlock: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2).bold()
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

enum ChartRange: CaseIterable {
    case week, month, threeMonths, all
    var label: String {
        switch self {
        case .week:         "7d"
        case .month:        "1m"
        case .threeMonths:  "3m"
        case .all:          "All"
        }
    }
}
