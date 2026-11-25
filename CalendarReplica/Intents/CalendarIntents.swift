import AppIntents
import Foundation
import SwiftData

enum CalendarIntentError: LocalizedError {
    case emptyTitle

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Event title cannot be empty."
        }
    }
}

struct AddCalendarEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Calendar Event"
    static var description = IntentDescription("Adds a custom event to your CalendarReplica calendar.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Event Title")
    var eventTitle: String

    @Parameter(title: "Date")
    var eventDate: Date?

    nonisolated(unsafe) static var containerOverride: ModelContainer?
    nonisolated(unsafe) static var userDefaultsOverride: UserDefaults?

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let trimmedTitle = eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw CalendarIntentError.emptyTitle
        }

        let targetDate = eventDate ?? Date()
        let container = Self.containerOverride ?? SharedModelContainer.shared
        let defaults = Self.userDefaultsOverride ?? .standard
        let repository = CalendarRepository(modelContext: container.mainContext)

        let resolvedUser: UserModel
        if let activeUsername = defaults.string(forKey: SharedModelContainer.activeUsernameDefaultsKey),
           let active = try repository.findUser(username: activeUsername) {
            resolvedUser = active
        } else if let firstUser = try repository.fetchFirstUser() {
            resolvedUser = firstUser
        } else {
            resolvedUser = try repository.ensureUser(username: "siri_user")
        }

        try repository.addEvent(title: trimmedTitle, date: targetDate, owner: resolvedUser)
        let formattedDate = DateFormatting.displayDate(from: targetDate)
        let message = "Added '\(trimmedTitle)' on \(formattedDate) for \(resolvedUser.username)."
        return .result(value: message, dialog: IntentDialog(stringLiteral: message))
    }
}

struct GetDayOverviewIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Day Overview"
    static var description = IntentDescription("Checks public holidays and custom events for a specific date.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Country Code", default: "SK")
    var countryCode: String

    nonisolated(unsafe) static var containerOverride: ModelContainer?
    nonisolated(unsafe) static var userDefaultsOverride: UserDefaults?
    nonisolated(unsafe) static var holidayServiceOverride: HolidayFetching?

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let targetDate = date ?? Date()
        let container = Self.containerOverride ?? SharedModelContainer.shared
        let defaults = Self.userDefaultsOverride ?? .standard
        let holidayService = Self.holidayServiceOverride ?? NagerHolidayAPIService()
        let repository = CalendarRepository(modelContext: container.mainContext)

        let targetYear = DateFormatting.year(from: targetDate)
        let targetDateKey = DateFormatting.apiDateKey(from: targetDate)
        let formattedDate = DateFormatting.displayDate(from: targetDate)

        let holidays = (try? await holidayService.fetchHolidays(year: targetYear, countryCode: countryCode)) ?? []
        let matchingHolidays = holidays.filter { $0.date == targetDateKey }

        var userEvents: [CalendarEvent] = []
        if let activeUsername = defaults.string(forKey: SharedModelContainer.activeUsernameDefaultsKey),
           let activeUser = try repository.findUser(username: activeUsername) {
            userEvents = try repository.fetchEvents(for: targetDate, ownerUsername: activeUser.username)
        } else if let firstUser = try repository.fetchFirstUser() {
            userEvents = try repository.fetchEvents(for: targetDate, ownerUsername: firstUser.username)
        }

        var parts: [String] = []
        if !matchingHolidays.isEmpty {
            let names = matchingHolidays.map(\.localName).joined(separator: ", ")
            parts.append("Public Holidays: \(names)")
        }
        if !userEvents.isEmpty {
            let titles = userEvents.map(\.title).joined(separator: ", ")
            parts.append("Events: \(titles)")
        }

        let summary: String
        if parts.isEmpty {
            summary = "No holidays or custom events on \(formattedDate)."
        } else {
            summary = "\(formattedDate) — " + parts.joined(separator: " | ")
        }
        return .result(value: summary, dialog: IntentDialog(stringLiteral: summary))
    }
}

struct CalendarAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddCalendarEventIntent(),
            phrases: [
                "Add an event in \(.applicationName)",
                "Create a calendar event in \(.applicationName)"
            ],
            shortTitle: "Add Event",
            systemImageName: "calendar.badge.plus"
        )
        AppShortcut(
            intent: GetDayOverviewIntent(),
            phrases: [
                "Check holidays in \(.applicationName)",
                "Get day overview in \(.applicationName)"
            ],
            shortTitle: "Day Overview",
            systemImageName: "calendar.day.timeline.left"
        )
    }
}
