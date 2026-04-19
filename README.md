# Healthier Human

A native iOS app for tracking daily meals, macros, water intake, and calorie targets — built with Swift, SwiftUI, and SwiftData.

## What it does

- Computes a personalized daily calorie target from your stats (weight, height, age, sex, activity level, and weight goal) using the Mifflin-St Jeor formula
- Lets you log meals across four categories: Breakfast, Lunch, Dinner, and Snacks
- Tracks water glasses alongside food
- Saves every food you've ever logged so you can re-add it with one tap
- Shows remaining calories for the day at a glance

## MVP scope

Local-only, no accounts, no cloud sync. Everything lives on your device via SwiftData.

## Tech stack

- Swift + SwiftUI (latest)
- SwiftData for persistence
- USDA FoodData Central API (phase 2)
- Open Food Facts API for barcode lookups (phase 3)

## Project structure

```
HealthierHuman/
├── App/                  # App entry point, root view
├── Domain/               # Pure-Swift calorie math, no UI or DB deps
├── Data/                 # SwiftData models and repositories
├── Network/              # API clients (phase 2+)
└── UI/                   # SwiftUI views and view models
```

See `docs/architecture.md` for the full layer design and `docs/calorie-calculation.md` for the formula spec.

## Development

Open `HealthierHuman.xcodeproj` in Xcode, select a simulator or your iPhone, and hit Run.

Unit tests for the calorie engine live in `HealthierHumanTests/` and can be run with ⌘U.
