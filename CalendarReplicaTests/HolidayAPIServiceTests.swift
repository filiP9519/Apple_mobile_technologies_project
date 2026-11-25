import XCTest
@testable import CalendarReplica

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class HolidayAPIServiceTests: XCTestCase {
    private var mockSession: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        mockSession = nil
        super.tearDown()
    }

    func testDecodeMockedNagerHolidayPayload() async throws {
        let json = """
        [
          {
            "date": "2026-01-01",
            "localName": "Deň vzniku Slovenskej republiky",
            "name": "Day of the Establishment of the Slovak Republic",
            "countryCode": "SK",
            "fixed": false,
            "global": true
          },
          {
            "date": "2026-12-25",
            "localName": "Prvý sviatok vianočný",
            "name": "Christmas Day",
            "countryCode": "SK"
          }
        ]
        """
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.url?.absoluteString, "https://date.nager.at/api/v3/PublicHolidays/2026/SK")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data(json.utf8))
        }

        let service = NagerHolidayAPIService(session: mockSession)
        let holidays = try await service.fetchHolidays(year: 2026, countryCode: "SK")

        XCTAssertEqual(holidays.count, 2)
        XCTAssertEqual(holidays[0].date, "2026-01-01")
        XCTAssertEqual(holidays[0].localName, "Deň vzniku Slovenskej republiky")
        XCTAssertEqual(holidays[1].name, "Christmas Day")
    }

    func testNon200ResponseThrowsInvalidResponseError() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let service = NagerHolidayAPIService(session: mockSession)
        do {
            _ = try await service.fetchHolidays(year: 2026, countryCode: "SK")
            XCTFail("Expected invalidResponse error")
        } catch let error as HolidayAPIError {
            XCTAssertEqual(error, .invalidResponse(500))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLiveNagerAPIFetchesSlovakPublicHolidays() async throws {
        let service = NagerHolidayAPIService()
        let holidays = try await service.fetchHolidays(year: 2026, countryCode: "SK")

        XCTAssertFalse(holidays.isEmpty, "Live Nager.Date API should return SK holidays for 2026")
        XCTAssertTrue(holidays.contains { $0.date == "2026-01-01" && $0.localName == "Deň vzniku Slovenskej republiky" })
        XCTAssertTrue(holidays.contains { $0.date == "2026-12-25" && $0.localName == "Prvý sviatok vianočný" })
    }
}
