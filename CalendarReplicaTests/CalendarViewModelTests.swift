import SwiftData
import XCTest
@testable import CalendarReplica

private final class MockHolidayService: HolidayFetching, @unchecked Sendable {
    var holidaysByYear: [Int: [Holiday]] = [:]
    var errorToThrow: Error?
    private(set) var fetchCalls: [(year: Int, countryCode: String)] = []

    func fetchHolidays(year: Int, countryCode: String) async throws -> [Holiday] {
        fetchCalls.append((year, countryCode))
        if let errorToThrow {
            throw errorToThrow
        }
        return holidaysByYear[year] ?? []
    }
}

@MainActor
final class CalendarViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var repository: CalendarRepository!
    private var mockService: MockHolidayService!
    private var viewModel: CalendarViewModel!
    private var userA: UserModel!
    private var userB: UserModel!

    override func setUpWithError() throws {
        container = try SharedModelContainer.makeContainer(inMemory: true)
        repository = CalendarRepository(modelContext: container.mainContext)
        mockService = MockHolidayService()
        mockService.holidaysByYear[2026] = [
            Holiday(
                date: "2026-01-01",
                localName: "Deň vzniku Slovenskej republiky",
                name: "Day of the Establishment of the Slovak Republic",
                countryCode: "SK"
            ),
            Holiday(
                date: "2026-12-25",
                localName: "Prvý sviatok vianočný",
                name: "Christmas Day",
                countryCode: "SK"
            )
        ]
        mockService.holidaysByYear[2027] = [
            Holiday(
                date: "2027-01-01",
                localName: "Deň vzniku Slovenskej republiky",
                name: "Day of the Establishment of the Slovak Republic",
                countryCode: "SK"
            )
        ]
        userA = try repository.register(username: "userA", password: "pwA")!
        userB = try repository.register(username: "userB", password: "pwB")!
        viewModel = CalendarViewModel(repository: repository, holidayService: mockService)
        viewModel.setActiveUser(userA)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        mockService = nil
        repository = nil
        container = nil
    }

    func testAddAndDeleteCustomEventPersistsInSwiftData() async throws {
        let jan1 = try XCTUnwrap(DateFormatting.date(fromApiKey: "2026-01-01"))
        await viewModel.selectDate(jan1)

        viewModel.addEvent(title: "Team Standup")
        XCTAssertEqual(viewModel.events.count, 1)
        XCTAssertEqual(viewModel.events.first?.title, "Team Standup")

        let persisted = try repository.fetchEvents(for: jan1, ownerUsername: "userA")
        XCTAssertEqual(persisted.count, 1)

        if let event = viewModel.events.first {
            viewModel.deleteEvent(event)
        }
        XCTAssertTrue(viewModel.events.isEmpty)
        XCTAssertTrue(try repository.fetchEvents(for: jan1, ownerUsername: "userA").isEmpty)
    }

    func testEventsAreIsolatedPerUserAndDate() async throws {
        let jan1 = try XCTUnwrap(DateFormatting.date(fromApiKey: "2026-01-01"))
        let jan2 = try XCTUnwrap(DateFormatting.date(fromApiKey: "2026-01-02"))

        await viewModel.selectDate(jan1)
        viewModel.addEvent(title: "UserA Jan1")

        await viewModel.selectDate(jan2)
        XCTAssertTrue(viewModel.events.isEmpty)

        viewModel.setActiveUser(userB)
        await viewModel.selectDate(jan1)
        XCTAssertTrue(viewModel.events.isEmpty)

        viewModel.addEvent(title: "UserB Jan1")
        XCTAssertEqual(viewModel.events.map(\.title), ["UserB Jan1"])

        viewModel.setActiveUser(userA)
        XCTAssertEqual(viewModel.events.map(\.title), ["UserA Jan1"])
    }

    func testHolidayFilteringAndYearCaching() async throws {
        let jan1 = try XCTUnwrap(DateFormatting.date(fromApiKey: "2026-01-01"))
        let jan2 = try XCTUnwrap(DateFormatting.date(fromApiKey: "2026-01-02"))
        let jan1_2027 = try XCTUnwrap(DateFormatting.date(fromApiKey: "2027-01-01"))

        await viewModel.selectDate(jan1)
        XCTAssertEqual(viewModel.holidaysForSelectedDate.count, 1)
        XCTAssertEqual(viewModel.holidaysForSelectedDate.first?.localName, "Deň vzniku Slovenskej republiky")
        XCTAssertEqual(mockService.fetchCalls.count, 1)

        await viewModel.selectDate(jan2)
        XCTAssertTrue(viewModel.holidaysForSelectedDate.isEmpty)
        XCTAssertEqual(mockService.fetchCalls.count, 1, "Same year should use cached holidays")

        await viewModel.selectDate(jan1_2027)
        XCTAssertEqual(viewModel.holidaysForSelectedDate.count, 1)
        XCTAssertEqual(mockService.fetchCalls.count, 2, "Switching year should fetch holidays for new year")
    }

    func testHolidayAPIErrorSetsMessageWithoutCrashing() async throws {
        mockService.errorToThrow = HolidayAPIError.invalidResponse(503)
        let mar15 = try XCTUnwrap(DateFormatting.date(fromApiKey: "2026-03-15"))

        await viewModel.selectDate(mar15)

        XCTAssertEqual(viewModel.apiErrorMessage, "Holiday API returned HTTP 503.")
        XCTAssertTrue(viewModel.holidaysForSelectedDate.isEmpty)
    }
}
