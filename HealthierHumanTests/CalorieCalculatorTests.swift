import Testing
@testable import HealthierHuman

// MARK: - Unit conversion tests

@Suite("Unit Conversions")
struct UnitConversionTests {

    @Test("Pounds to kilograms")
    func poundsToKilograms() {
        #expect(CalorieCalculator.kilograms(fromPounds: 154).isApproximately(69.85, tolerance: 0.01))
    }

    @Test("Feet and inches to centimetres")
    func feetInchesToCentimetres() {
        // 5'6" = 66 inches = 167.64 cm
        #expect(CalorieCalculator.centimetres(fromFeet: 5, inches: 6).isApproximately(167.64, tolerance: 0.01))
        // 5'10" = 70 inches = 177.8 cm
        #expect(CalorieCalculator.centimetres(fromFeet: 5, inches: 10).isApproximately(177.8, tolerance: 0.01))
    }
}

// MARK: - BMR tests

@Suite("BMR — Mifflin-St Jeor")
struct BMRTests {

    @Test("Female BMR — worked example from spec")
    func femaleBMR() {
        // Woman, 70 kg, 165 cm, age 30 → 1420.25
        let result = CalorieCalculator.bmr(weightKg: 70, heightCm: 165, age: 30, sex: .female)
        #expect(result.isApproximately(1420.25, tolerance: 0.5))
    }

    @Test("Male BMR — worked example from spec")
    func maleBMR() {
        // Man, 83.91 kg, 177.8 cm, age 35 → 1780.35
        let result = CalorieCalculator.bmr(weightKg: 83.91, heightCm: 177.8, age: 35, sex: .male)
        #expect(result.isApproximately(1780.35, tolerance: 0.5))
    }
}

// MARK: - TDEE tests

@Suite("TDEE")
struct TDEETests {

    @Test("TDEE — moderately active female from spec")
    func tdeeModeratelyActiveFemale() {
        // BMR 1420.25 × 1.55 = 2201.39
        let result = CalorieCalculator.tdee(bmr: 1420.25, activityLevel: .moderatelyActive)
        #expect(result.isApproximately(2201.39, tolerance: 1.0))
    }
}

// MARK: - Daily target tests

@Suite("Daily Calorie Target")
struct DailyTargetTests {

    @Test("No floor clamp needed — male, lightly active, lose 1 lb/week")
    func targetAboveFloor() {
        // From full worked example in spec: expect ~1948 cal
        let target = CalorieCalculator.dailyTarget(
            weightKg: 83.91,
            heightCm: 177.8,
            age: 35,
            sex: .male,
            activityLevel: .lightlyActive,
            goal: .loseOnePound
        )
        #expect(target.calories >= 1500)             // above male floor
        #expect(target.wasClampedToFloor == false)
        #expect((1900...2000).contains(target.calories))
    }

    @Test("Female safety floor — 1200 cal/day")
    func femaleSafetyFloor() {
        // Very low inputs to force a floor clamp
        let target = CalorieCalculator.dailyTarget(
            weightKg: 45,
            heightCm: 150,
            age: 60,
            sex: .female,
            activityLevel: .sedentary,
            goal: .loseTwoPounds
        )
        #expect(target.calories == 1200)
        #expect(target.wasClampedToFloor == true)
        #expect(target.floor == 1200)
    }

    @Test("Male safety floor — 1500 cal/day")
    func maleSafetyFloor() {
        // Very low inputs to force a floor clamp
        let target = CalorieCalculator.dailyTarget(
            weightKg: 55,
            heightCm: 155,
            age: 70,
            sex: .male,
            activityLevel: .sedentary,
            goal: .loseTwoPounds
        )
        #expect(target.calories == 1500)
        #expect(target.wasClampedToFloor == true)
        #expect(target.floor == 1500)
    }

    @Test("Maintain weight — no deficit applied")
    func maintainWeight() {
        let target = CalorieCalculator.dailyTarget(
            weightKg: 70,
            heightCm: 170,
            age: 30,
            sex: .female,
            activityLevel: .moderatelyActive,
            goal: .maintain
        )
        // TDEE ≈ 2140, maintain = no adjustment, well above floor
        #expect(target.wasClampedToFloor == false)
        #expect(target.calories > 1800)
    }

    @Test("Safety floor value correct per sex")
    func safetyFloorValues() {
        #expect(CalorieCalculator.safetyFloor(for: .female) == 1200)
        #expect(CalorieCalculator.safetyFloor(for: .male) == 1500)
    }
}

// MARK: - Helper

extension Double {
    /// Returns true if this value is within `tolerance` of `other`.
    func isApproximately(_ other: Double, tolerance: Double) -> Bool {
        abs(self - other) <= tolerance
    }
}
