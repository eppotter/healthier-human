# Project Plan — Healthier Human

Progress is tracked here. Claude Code updates checkboxes after each step.

---

## Phase 0 — Scaffolding & planning ✅

- [x] Clone repo to `~/Developer/healther-human`
- [x] Write `README.md`
- [x] Write `CLAUDE.md` (standing instructions)
- [x] Write `PROJECT_PLAN.md` (this file)
- [x] Write `.gitignore`
- [x] Write `docs/calorie-calculation.md`
- [x] Write `docs/architecture.md`
- [x] Initial commit and push

---

## Phase 1 — MVP v1: Core app

### 1.1 Xcode project setup
- [ ] Create `HealthierHuman.xcodeproj` with SwiftUI + SwiftData
- [ ] Set bundle ID, deployment target (iOS 17+)
- [ ] Add folder structure: `App/`, `Domain/`, `Data/`, `UI/`, `Network/`
- [ ] Verify app builds and runs in simulator

### 1.2 Domain layer — calorie engine
- [ ] Implement `CalorieCalculator.swift` (BMR, TDEE, goal adjustment, safety floor clamp)
- [ ] Write unit tests covering all formula paths, edge cases, and floor clamping
- [ ] All tests pass

### 1.3 SwiftData models
- [ ] `UserProfile` model (weight, height, age, sex, activity level, goal)
- [ ] `Food` model (name, calories, protein, carbs, fat)
- [ ] `FoodEntry` model (food reference, quantity, meal type, date)
- [ ] `WaterLog` model (glasses count, date)

### 1.4 Onboarding flow
- [ ] Multi-step onboarding form (weight → height → age → sex → activity → goal)
- [ ] Live calorie target preview as user fills in fields
- [ ] Safety floor warning displayed when applicable
- [ ] Profile saved to SwiftData on completion

### 1.5 Daily tracker screen
- [ ] Today view with Breakfast / Lunch / Dinner / Snacks sections
- [ ] Calorie summary bar (target / consumed / remaining)
- [ ] Water tracker (glass tap counter)
- [ ] Navigate between dates (previous / next day)

### 1.6 Food logging
- [ ] "Add food" sheet with manual entry form
- [ ] Saved foods list (auto-populated from past entries, searchable)
- [ ] One-tap re-log from saved foods
- [ ] Entry stored as raw food reference + quantity

### 1.7 Settings / profile screen
- [ ] Edit all user profile fields
- [ ] Calorie target updates immediately when profile changes
- [ ] Safety floor warning in settings when applicable

### 1.8 Polish & QA
- [ ] App icon and launch screen
- [ ] Empty states (no meals logged yet, first-time use)
- [ ] Error states (invalid input in forms)
- [ ] Accessibility labels on interactive elements
- [ ] Test on physical iPhone

---

## Phase 2 — USDA FoodData Central integration

- [ ] Implement `USDAClient.swift` in `Network/`
- [ ] Food search UI in the "Add food" sheet
- [ ] Map API response to local `Food` model
- [ ] Cache search results in SwiftData to reduce API calls
- [ ] Handle rate limit (1,000 req/hr) gracefully

---

## Phase 3 — Barcode scanning (Open Food Facts)

- [ ] Camera permission and barcode scan UI
- [ ] Implement `OpenFoodFactsClient.swift`
- [ ] Map barcode result to local `Food` model
- [ ] Fallback to manual entry when barcode not found

---

## Phase 4 — App Store launch

- [ ] Apple Developer account enrolled
- [ ] App Store Connect listing created (name, description, screenshots)
- [ ] Privacy policy (required — app collects health data locally)
- [ ] TestFlight beta with at least one external tester
- [ ] App Store review submission
- [ ] Version 1.0 released

---

## Backlog (post-launch ideas — do not build until v1 ships)

- Apple Health integration
- Home screen widget (daily progress)
- Push notification reminders
- Exercise logging
- Recipe builder
- Barcode scan history
- iCloud sync
