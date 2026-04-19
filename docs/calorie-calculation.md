# Calorie Calculation Spec

This document defines the exact math the app uses to compute a user's daily calorie target. The `Domain/CalorieCalculator.swift` module must implement this spec exactly. Unit tests verify every case below.

---

## Step 1 — Basal Metabolic Rate (BMR)

BMR is the number of calories your body burns at complete rest. We use the **Mifflin-St Jeor formula**, which is considered the most accurate for general use.

**Men:**
```
BMR = (10 × weight_kg) + (6.25 × height_cm) − (5 × age) + 5
```

**Women:**
```
BMR = (10 × weight_kg) + (6.25 × height_cm) − (5 × age) − 161
```

### Worked example — BMR
- User: woman, 70 kg, 165 cm, age 30
- `BMR = (10 × 70) + (6.25 × 165) − (5 × 30) − 161`
- `BMR = 700 + 1031.25 − 150 − 161`
- `BMR = 1420.25 cal/day`

---

## Step 2 — Total Daily Energy Expenditure (TDEE)

TDEE accounts for how active the user is throughout the day.

```
TDEE = BMR × activity_multiplier
```

| Activity level | Multiplier | Description |
|---|---|---|
| Sedentary | 1.2 | Desk job, little or no exercise |
| Lightly active | 1.375 | Light exercise 1–3 days/week |
| Moderately active | 1.55 | Moderate exercise 3–5 days/week |
| Very active | 1.725 | Hard exercise 6–7 days/week |
| Extra active | 1.9 | Very hard exercise, physical job |

### Worked example — TDEE
- BMR from above: 1420.25
- Activity: Moderately active (1.55)
- `TDEE = 1420.25 × 1.55 = 2201.39 cal/day`

---

## Step 3 — Goal adjustment

Subtract a daily calorie deficit from TDEE to achieve the user's chosen weight-loss rate. 1 lb of fat ≈ 3,500 calories, so a 500 cal/day deficit produces ~1 lb/week of loss.

| Goal | Daily adjustment |
|---|---|
| Maintain weight | 0 cal |
| Lose 0.5 lb/week | −250 cal |
| Lose 1 lb/week | −500 cal |
| Lose 1.5 lb/week | −750 cal |
| Lose 2 lb/week | −1,000 cal |

```
target = TDEE + goal_adjustment   (adjustment is negative for loss goals)
```

### Worked example — goal adjustment
- TDEE: 2201.39
- Goal: Lose 1 lb/week (−500)
- `target = 2201.39 − 500 = 1701.39 → round to 1701 cal/day`

---

## Step 4 — Safety floor (HARD MINIMUM — always enforced)

Eating too few calories is dangerous. If the computed target is below the floor, **clamp it to the floor** and display a warning.

| Sex | Floor |
|---|---|
| Women | 1,200 cal/day |
| Men | 1,500 cal/day |

**Warning message to display in UI when clamped:**
> "Your goal would require fewer calories than the recommended minimum; we've capped it at [floor]. Consult a healthcare professional if you want to go lower."

### Worked example — floor triggered
- Woman, very low TDEE, goal: lose 2 lb/week
- Computed target: 980 cal/day (below 1,200)
- Final target: **1,200 cal/day** + warning shown

---

## Unit conversion helpers

The formula requires metric units. If the user enters imperial units, convert before running the formula:

```
weight_kg  = weight_lb  × 0.453592
height_cm  = height_in  × 2.54
           = (feet × 12 + inches) × 2.54
```

### Worked example — imperial input
- User enters: 5′6″, 154 lb
- `height_cm = (5×12 + 6) × 2.54 = 66 × 2.54 = 167.64 cm`
- `weight_kg = 154 × 0.453592 = 69.85 kg`

---

## Full end-to-end example

| Input | Value |
|---|---|
| Sex | Male |
| Age | 35 |
| Weight | 185 lb → 83.91 kg |
| Height | 5′10″ → 177.8 cm |
| Activity | Lightly active (1.375) |
| Goal | Lose 1 lb/week (−500) |

1. `BMR = (10 × 83.91) + (6.25 × 177.8) − (5 × 35) + 5`
   `= 839.1 + 1111.25 − 175 + 5 = 1780.35`
2. `TDEE = 1780.35 × 1.375 = 2447.98`
3. `target = 2447.98 − 500 = 1947.98 → 1948 cal/day`
4. Floor check: 1948 > 1500 ✅ No clamp needed
5. **Final target: 1,948 cal/day**
