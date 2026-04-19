# CLAUDE.md — Standing instructions for every Claude Code session

This file is loaded automatically every time Claude Code opens this repo. Follow everything here without being asked.

---

## Project overview

**Healthier Human** is a native iOS diet and macro tracking app. MVP v1 is local-only (no backend, no accounts). The user is a complete beginner — explain concepts in plain English, never ask them to write or edit code directly.

---

## Tech stack

- Swift + SwiftUI (latest stable versions)
- SwiftData for all local persistence
- USDA FoodData Central API — phase 2 (free, no key required, ~380k foods, 1000 req/hr)
- Open Food Facts API — phase 3 (barcode lookups)
- No backend, no cloud sync, no accounts in MVP v1

---

## Calorie math — Mifflin-St Jeor

### BMR
- Men:   `BMR = 10 × weight_kg + 6.25 × height_cm − 5 × age + 5`
- Women: `BMR = 10 × weight_kg + 6.25 × height_cm − 5 × age − 161`

### TDEE = BMR × activity multiplier
| Activity level | Multiplier |
|---|---|
| Sedentary | 1.2 |
| Lightly active | 1.375 |
| Moderately active | 1.55 |
| Very active | 1.725 |
| Extra active | 1.9 |

### Goal adjustment (subtract from TDEE)
| Goal | Cal/day adjustment |
|---|---|
| Maintain weight | 0 |
| Lose 0.5 lb/week | −250 |
| Lose 1 lb/week | −500 |
| Lose 1.5 lb/week | −750 |
| Lose 2 lb/week | −1,000 |

### Safety floors — HARD MINIMUM, always enforce
- Women: **1,200 cal/day**
- Men: **1,500 cal/day**
- If goal math goes below the floor, clamp to the floor and show this warning in the UI:
  > "Your goal would require fewer calories than the recommended minimum; we've capped it at [floor]. Consult a healthcare professional if you want to go lower."

---

## Architecture — four layers (never mix them)

1. **Domain** (`Domain/`) — pure Swift functions, zero UIKit/SwiftUI/SwiftData imports. All calorie math lives here. Fully unit-testable.
2. **Data** (`Data/`) — SwiftData models and any repository/query helpers.
3. **Network** (`Network/`) — API clients for USDA and Open Food Facts (phase 2+). No UI code.
4. **UI** (`UI/`) — SwiftUI views and view models. Talks to Domain and Data only; never calls Network directly.

See `docs/architecture.md` for rationale.

---

## Coding conventions

- Conventional Commits for every commit: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`
- Small, focused commits — one logical change per commit
- Unit tests for **all** Domain functions from day one (pure Swift = easy to test, critical to get right)
- Store raw food entries (food reference + quantity), never pre-summed totals — preserves ability to fix bad data or swap databases
- When an architectural decision comes up, pause and ask the user before guessing
- After each meaningful step, update `PROJECT_PLAN.md` checkboxes

---

## MVP v1 scope — do not build beyond this without asking

**In scope:**
- Onboarding: collect weight, height, age, sex, activity level, goal
- Daily tracker: Breakfast / Lunch / Dinner / Snacks sections + water glasses
- Manual food entry: name, calories, protein, carbs, fat
- Saved foods: any food logged before is searchable and one-tap re-loggable
- Daily calorie target display with remaining calories
- Settings / profile screen to edit user info and goal
- Local-only SwiftData storage

**Explicitly out of scope for MVP v1:**
Cloud sync, accounts, social features, barcode scanning, Apple Health integration, home screen widgets, push notifications, exercise logging, recipe builder, photo recognition, AI features.

---

## Working with the user

- Never ask the user to write or edit code — do all coding yourself
- Explain decisions in 1–2 plain-English sentences when you make them
- When there's an error, paste it clearly and walk the user through the fix
- Teach concepts as they come up, but keep explanations concise
