import Foundation
import Observation

struct DayIndicatorState: Equatable, Sendable {
    let hasHoliday: Bool
    let hasCustomEvent: Bool

    var accessibilityValue: String {
        switch (hasHoliday, hasCustomEvent) {
        case (true, true):
            return "holiday,custom"
        case (true, false):
            return "holiday"
        case (false, true):
            return "custom"
        case (false, false):
            return "none"
        }
    }
}

@Observable
@MainActor
final class CalendarViewModel {
    var selectedDate: Date = Date()
    var displayedMonth: Date = Date()
    var countryCode: String = "SK"
    var events: [CalendarEvent] = []
    var customEventDateKeys: Set<String> = []
    var holidaysForSelectedDate: [Holiday] = []
    var allHolidaysForCurrentYear: [Holiday] = []
    var isLoadingHolidays: Bool = false
    var apiErrorMessage: String?

    var holidayDateKeys: Set<String> {
        let suffix = "-\(countryCode)"
        let cachedDates = cachedHolidaysByKey
            .filter { $0.key.hasSuffix(suffix) }
            .values
            .flatMap { $0.map(\.date) }
        return Set(cachedDates).union(allHolidaysForCurrentYear.map(\.date))
    }

    private(set) var activeUser: UserModel?
    private var cachedHolidaysByKey: [String: [Holiday]] = [:]

    private let repository: CalendarRepository
    private let holidayService: HolidayFetching

    init(
        repository: CalendarRepository,
        holidayService: HolidayFetching = NagerHolidayAPIService()
    ) {
        self.repository = repository
        self.holidayService = holidayService
    }

    func indicatorState(for date: Date) -> DayIndicatorState {
        let key = DateFormatting.apiDateKey(from: date)
        return DayIndicatorState(
            hasHoliday: holidayDateKeys.contains(key),
            hasCustomEvent: customEventDateKeys.contains(key)
        )
    }

    func setActiveUser(_ user: UserModel?) {
        activeUser = user
        if user == nil {
            let now = Date()
            selectedDate = now
            displayedMonth = now
            events = []
            customEventDateKeys = []
            updateHolidaysForSelectedDate()
        } else {
            reloadEvents()
        }
    }

    func selectDate(_ date: Date) async {
        selectedDate = date
        displayedMonth = date
        reloadEvents()
        let year = DateFormatting.year(from: date)
        await loadHolidaysIfNeeded(for: year)
        updateHolidaysForSelectedDate()
    }

    func moveMonth(by offset: Int) async {
        guard let updated = Calendar.current.date(byAdding: .month, value: offset, to: displayedMonth) else {
            return
        }
        displayedMonth = updated
        let year = DateFormatting.year(from: updated)
        await loadHolidaysIfNeeded(for: year)
    }

    func loadHolidaysIfNeeded(for year: Int, forceRefresh: Bool = false) async {
        let cacheKey = "\(year)-\(countryCode)"
        if !forceRefresh, let cached = cachedHolidaysByKey[cacheKey] {
            allHolidaysForCurrentYear = cached
            updateHolidaysForSelectedDate()
            return
        }

        isLoadingHolidays = true
        apiErrorMessage = nil
        defer { isLoadingHolidays = false }

        do {
            let fetched = try await holidayService.fetchHolidays(year: year, countryCode: countryCode)
            cachedHolidaysByKey[cacheKey] = fetched
            allHolidaysForCurrentYear = fetched
            updateHolidaysForSelectedDate()
        } catch {
            apiErrorMessage = error.localizedDescription
        }
    }

    func addEvent(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let user = activeUser else { return }

        do {
            try repository.addEvent(title: trimmed, date: selectedDate, owner: user)
            reloadEvents()
        } catch {
            apiErrorMessage = "Could not save event: \(error.localizedDescription)"
        }
    }

    func deleteEvent(_ event: CalendarEvent) {
        do {
            try repository.deleteEvent(event)
            reloadEvents()
        } catch {
            apiErrorMessage = "Could not delete event: \(error.localizedDescription)"
        }
    }

    func reloadEvents() {
        guard let username = activeUser?.username else {
            events = []
            customEventDateKeys = []
            return
        }

        do {
            events = try repository.fetchEvents(for: selectedDate, ownerUsername: username)
            let allUserEvents = try repository.fetchAllEvents(ownerUsername: username)
            customEventDateKeys = Set(allUserEvents.map(\.dateKey))
        } catch {
            events = []
            customEventDateKeys = []
            apiErrorMessage = "Could not load events: \(error.localizedDescription)"
        }
    }

    private func updateHolidaysForSelectedDate() {
        let selectedKey = DateFormatting.apiDateKey(from: selectedDate)
        let year = DateFormatting.year(from: selectedDate)
        let yearHolidays = cachedHolidaysByKey["\(year)-\(countryCode)"] ?? allHolidaysForCurrentYear
        holidaysForSelectedDate = yearHolidays.filter { $0.date == selectedKey }
    }
}
