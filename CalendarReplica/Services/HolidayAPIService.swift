import Foundation

protocol HolidayFetching: Sendable {
    func fetchHolidays(year: Int, countryCode: String) async throws -> [Holiday]
}

enum HolidayAPIError: LocalizedError, Equatable {
    case invalidURL
    case invalidResponse(Int)
    case decodingFailed
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid holiday API URL."
        case .invalidResponse(let statusCode):
            return "Holiday API returned HTTP \(statusCode)."
        case .decodingFailed:
            return "Failed to parse holiday data."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

struct NagerHolidayAPIService: HolidayFetching {
    private let session: URLSession
    private let baseURL: String

    init(
        session: URLSession = .shared,
        baseURL: String = "https://date.nager.at"
    ) {
        self.session = session
        self.baseURL = baseURL
    }

    func fetchHolidays(year: Int, countryCode: String) async throws -> [Holiday] {
        let cleanedCode = countryCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let url = URL(string: "\(baseURL)/api/v3/PublicHolidays/\(year)/\(cleanedCode)") else {
            throw HolidayAPIError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw HolidayAPIError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HolidayAPIError.invalidResponse(-1)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw HolidayAPIError.invalidResponse(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode([Holiday].self, from: data)
        } catch {
            throw HolidayAPIError.decodingFailed
        }
    }
}
