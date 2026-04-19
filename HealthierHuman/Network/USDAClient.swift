import Foundation

/// Searches the USDA FoodData Central API for foods.
/// Free to use. Rate limit: 1,000 requests/hour with DEMO_KEY.
/// Docs: https://fdc.nal.usda.gov/api-guide.html
actor USDAClient {
    static let shared = USDAClient()

    private let apiKey = "DEMO_KEY"
    private let base   = URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!

    // MARK: - Search

    /// Returns up to `pageSize` foods matching `query`.
    func search(query: String, pageSize: Int = 25) async throws -> [USDAFood] {
        var comps = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "query",    value: query),
            URLQueryItem(name: "api_key",  value: apiKey),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "dataType", value: "Foundation,SR Legacy")
        ]
        guard let url = comps.url else { throw USDAError.badURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw USDAError.badResponse }
        switch http.statusCode {
        case 200:        break
        case 429:        throw USDAError.rateLimited
        default:         throw USDAError.httpError(http.statusCode)
        }
        let decoded = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        return decoded.foods
    }
}

// MARK: - Response types

struct USDASearchResponse: Decodable {
    let foods: [USDAFood]
}

struct USDAFood: Decodable, Identifiable {
    let fdcId: Int
    let description: String
    let foodNutrients: [USDANutrient]

    var id: Int { fdcId }

    // MARK: Computed nutrition (per 100g)

    private func nutrientValue(id: Int) -> Double? {
        foodNutrients.first(where: { $0.nutrientId == id })?.value
    }

    /// Calories per 100g
    var caloriesPer100g: Double? { nutrientValue(id: 1008) }
    /// Protein (g) per 100g
    var proteinPer100g:  Double? { nutrientValue(id: 1003) }
    /// Carbohydrates (g) per 100g
    var carbsPer100g:    Double? { nutrientValue(id: 1005) }
    /// Fat (g) per 100g
    var fatPer100g:      Double? { nutrientValue(id: 1004) }

    /// Display name — title-cased for readability
    var displayName: String {
        description
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).capitalized }
            .joined(separator: ", ")
    }
}

struct USDANutrient: Decodable {
    let nutrientId: Int
    let value: Double?
}

// MARK: - Errors

enum USDAError: LocalizedError {
    case badURL
    case badResponse
    case rateLimited
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .badURL:            return "Invalid search URL."
        case .badResponse:       return "No response from the USDA server."
        case .rateLimited:       return "Too many searches — please wait a moment and try again."
        case .httpError(let c):  return "USDA server error (\(c))."
        }
    }
}
