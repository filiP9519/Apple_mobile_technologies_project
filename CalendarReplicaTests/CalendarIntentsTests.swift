import AppIntents
import SwiftData
import XCTest
@testable import CalendarReplica

private struct IntentMockHolidayService: HolidayFetching {
    let holidays: [Holiday]

    func fetchHolidays(year: Int, countryCode: String) async throws -> [Holiday] {
        holidays
    }
}

@MainActor
final class CalendarIntentsTests: XCTestCase {
    private var container: ModelContainer!
    private var repository: CalendarRepository!
    private var defaultsSuiteName: String!
    private var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        container = try SharedModelContainer.makeContainer(inMemory: true)
        repository = CalendarRepository(modelContext: container.mainContext)
        defaultsSuiteName = "CalendarIntentsTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: defaultsSuiteName)!

        AddCalendarEventIntent.containerOverride = container
        AddCalendarEventIntent.userDefaultsOverride = userDefaults
        GetDayOverviewIntent.containerOverride = container
        GetDayOverviewIntent.userDefaultsOverride = userDefaults
    }

    override func tearDownWithError() throws {
        AddCalendarEventIntent.containerOverride = nil
        AddCalendarEventIntent.userDefaultsOverride = nil
        GetDayOverviewIntent.containerOverride = nil
        GetDayOverviewIntent.userDefaultsOverride = nil
        GetDayOverviewIntent.holidayServiceOverride = nil
        userDefaults.removePersistentDomain(forName: defaultsSuiteName)
        repository = nil
        container = nil
    }

    func testAddCalendarEventIntentPersistsEventToSwiftData() async throws {
        _ = try repository.register(username: "filip", password: "pw")
        userDefaults.set("filip", forKey: SharedModelContainer.activeUsernameDefaultsKey)

        let targetDate = try XCTUnwrap(DateFormatting.date(fromApiKey: "2026-05-01"))
        let intent = AddCalendarEventIntent()
        intent.eventTitle = "Siri Scheduled Lunch"
        intent.eventDate = targetDate

        let result = try await intent.perform()
        let dialogValue = result.value ?? ""

        XCTAssertTrue(dialogValue.contains("Siri Scheduled Lunch"))
        XCTAssertTrue(dialogValue.contains("01.05.2026"))
        XCTAssertTrue(dialogValue.contains("filip"))

        let stored = try repository.fetchEvents(for: targetDate, ownerUsername: "filip")
        XCTAssertEqual(stored.map(\.title), ["Siri Scheduled Lunch"])
    }

    func testGetDayOverviewIntentCombinesHolidaysAndCustomEvents() async throws {
        let user = try XCTUnwrap(repository.register(username: "filip", password: "pw"))
        userDefaults.set("filip", forKey: SharedModelContainer.activeUsernameDefaultsKey)

        let targetDate = try XCTUnwrap(DateFormatting.date(fromApiKey: "2026-01-01"))
        try repository.addEvent(title: "New Year Brunch", date: targetDate, owner: user)

        GetDayOverviewIntent.holidayServiceOverride = IntentMockHolidayService(holidays: [
            Holiday(
                date: "2026-01-01",
                localName: "Deň vzniku Slovenskej republiky",
                name: "Day of the Establishment of the Slovak Republic",
                countryCode: "SK"
            )
        ])

        let intent = GetDayOverviewIntent()
        intent.date = targetDate
        intent.countryCode = "SK"

        let result = try await intent.perform()
        let summary = result.value ?? ""

        XCTAssertTrue(summary.contains("01.01.2026"))
        XCTAssertTrue(summary.contains("Deň vzniku Slovenskej republiky"))
        XCTAssertTrue(summary.contains("New Year Brunch"))
    }
}
