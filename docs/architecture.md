# Architecture — Healthier Human

The app is divided into four layers. Each layer has a single job, and layers only talk to each other in the directions shown below. This separation makes the code easy to test, easy to change, and easy to understand.

---

## The four layers

```
┌─────────────────────────────────────────────┐
│                   UI Layer                  │  SwiftUI views + view models
│              (UI/)                          │  What the user sees and taps
└────────────────────┬────────────────────────┘
                     │ reads/writes
          ┌──────────┴──────────┐
          │                     │
┌─────────▼──────────┐  ┌───────▼──────────────┐
│   Domain Layer     │  │    Data Layer         │
│   (Domain/)        │  │    (Data/)            │
│   Pure Swift math  │  │    SwiftData models   │
│   No imports from  │  │    & query helpers    │
│   UI or SwiftData  │  │                       │
└────────────────────┘  └───────┬──────────────┘
                                │ (phase 2+)
                      ┌─────────▼──────────────┐
                      │   Network Layer         │
                      │   (Network/)            │
                      │   USDA & Open Food      │
                      │   Facts API clients     │
                      └────────────────────────┘
```

---

## Domain layer — `Domain/`

**What it contains:** Pure Swift functions and value types. No UIKit, no SwiftUI, no SwiftData.

**Key files:**
- `CalorieCalculator.swift` — BMR, TDEE, goal adjustment, safety floor logic
- `UserProfile+Calculations.swift` — helpers that apply calculator to a profile

**Why it's isolated:** Because it has no dependencies, it can be tested with plain Swift unit tests — no simulator, no database, no UI. This is where the most critical logic lives (the calorie math), so it must be provably correct.

**Rule:** If you find yourself importing `SwiftData` or `SwiftUI` in a Domain file, stop — something is wrong.

---

## Data layer — `Data/`

**What it contains:** SwiftData `@Model` classes and any query/repository helpers that abstract database access.

**Key models:**
- `UserProfile` — weight, height, age, sex, activity level, goal
- `Food` — name, calories per 100 g (or per serving), protein, carbs, fat
- `FoodEntry` — a reference to a `Food` + quantity + meal type (breakfast/lunch/dinner/snack) + date
- `WaterLog` — glasses count + date

**Why raw entries, not totals:** We store `FoodEntry(food: banana, grams: 120)` rather than pre-computing "150 calories added". This means if we later get better nutrition data, we can recompute historical totals without losing any history.

---

## Network layer — `Network/`

**What it contains:** API clients for external food databases. Phase 2+, empty in MVP v1.

**Planned clients:**
- `USDAClient.swift` — searches USDA FoodData Central (free, no API key needed for basic use)
- `OpenFoodFactsClient.swift` — looks up foods by barcode (phase 3)

**Rule:** Network clients return plain Swift structs (DTOs). They never write directly to SwiftData — the UI layer decides what to save.

---

## UI layer — `UI/`

**What it contains:** SwiftUI views and their view models (`@Observable` classes that hold view state).

**Key screens:**
- `OnboardingFlow` — collects user stats on first launch
- `DailyTrackerView` — the main screen; shows today's meals and water
- `AddFoodView` — sheet for logging a new food entry
- `SavedFoodsView` — searchable list of previously logged foods
- `SettingsView` — edit profile and goal

**Rule:** Views call Domain functions for calculations and read/write Data models via SwiftData's `@Query` and `@Environment(\.modelContext)`. They never contain raw formula math.

---

## Data flow example — logging a meal

1. User taps **Add Food** in `DailyTrackerView`
2. `AddFoodView` shows a form; user types "Banana, 120 g, 107 cal, 1.3 g protein, 27 g carbs, 0.4 g fat"
3. On save, the UI layer creates a `FoodEntry` in SwiftData via `modelContext.insert(...)`
4. `DailyTrackerView` re-queries entries for today via `@Query` and recalculates totals using `CalorieCalculator` from the Domain layer
5. Remaining calories display updates automatically

---

## Testing strategy

| Layer | How to test |
|---|---|
| Domain | Plain XCTest unit tests — no simulator needed |
| Data | XCTest with an in-memory SwiftData container |
| Network | XCTest with URLProtocol stubs (mock HTTP responses) |
| UI | Manual testing + Xcode Previews for visual review |

Unit tests for the Domain layer are written **from day one** alongside the first implementation of `CalorieCalculator.swift`.
