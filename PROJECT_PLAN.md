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

### 1.1 Xcode project setup ✅
- [x] Create `HealthierHuman.xcodeproj` with SwiftUI + SwiftData
- [x] Set bundle ID, deployment target (iOS 18+)
- [x] Add folder structure: `App/`, `Domain/`, `Data/`, `UI/`, `Network/`
- [x] Verify app builds and runs in simulator

### 1.2 Domain layer — calorie engine ✅
- [x] Implement `CalorieCalculator.swift` (BMR, TDEE, goal adjustment, safety floor clamp)
- [x] Write unit tests covering all formula paths, edge cases, and floor clamping
- [x] All tests pass (10/10)

### 1.3 SwiftData models ✅
- [x] `UserProfile` model (weight, height, age, sex, activity level, goal)
- [x] `Food` model (name, calories, protein, carbs, fat)
- [x] `FoodEntry` model (food reference, quantity, meal type, date)
- [x] `WaterLog` model (glasses count, date)

### 1.4 Onboarding flow ✅
- [x] Multi-step onboarding form (weight → height → age → sex → activity → goal)
- [x] Live calorie target preview as user fills in fields
- [x] Safety floor warning displayed when applicable
- [x] Profile saved to SwiftData on completion

### 1.5 Daily tracker screen ✅
- [x] Today view with Breakfast / Lunch / Dinner / Snacks sections
- [x] Calorie summary bar (target / consumed / remaining)
- [x] Water tracker (glass tap counter)
- [x] Navigate between dates (previous / next day)

### 1.6 Food logging ✅
- [x] "Add food" sheet with manual entry form
- [x] Saved foods list (auto-populated from past entries, searchable)
- [x] One-tap re-log from saved foods
- [x] Entry stored as raw food reference + quantity

### 1.7 Settings / profile screen ✅
- [x] Edit all user profile fields
- [x] Calorie target updates immediately when profile changes
- [x] Safety floor warning in settings when applicable

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
