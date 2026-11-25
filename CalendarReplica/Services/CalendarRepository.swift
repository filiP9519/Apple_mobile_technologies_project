import Foundation
import SwiftData

@MainActor
final class CalendarRepository {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Authentication

    func login(username: String, password: String) throws -> UserModel? {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { user in
                user.username == trimmedUsername && user.password == password
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func register(username: String, password: String) throws -> UserModel? {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if try findUser(username: trimmedUsername) != nil {
            return nil
        }

        let newUser = UserModel(username: trimmedUsername, password: password)
        modelContext.insert(newUser)
        try modelContext.save()
        return newUser
    }

    func findUser(username: String) throws -> UserModel? {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptor = FetchDescriptor<UserModel>(
            predicate: #Predicate { user in
                user.username == trimmedUsername
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchFirstUser() throws -> UserModel? {
        var descriptor = FetchDescriptor<UserModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func ensureUser(username: String, defaultPassword: String = "shortcut") throws -> UserModel {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = try findUser(username: trimmedUsername) {
            return existing
        }
        let created = UserModel(username: trimmedUsername, password: defaultPassword)
        modelContext.insert(created)
        try modelContext.save()
        return created
    }

    // MARK: - Events

    func fetchEvents(for date: Date, ownerUsername: String) throws -> [CalendarEvent] {
        let targetDateKey = DateFormatting.apiDateKey(from: date)
        let targetUsername = ownerUsername
        let descriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { event in
                event.ownerUsername == targetUsername && event.dateKey == targetDateKey
            },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchAllEvents(ownerUsername: String) throws -> [CalendarEvent] {
        let targetUsername = ownerUsername
        let descriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { event in
                event.ownerUsername == targetUsername
            },
            sortBy: [SortDescriptor(\.dateKey, order: .forward), SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    @discardableResult
    func addEvent(title: String, date: Date, owner: UserModel) throws -> CalendarEvent {
        let event = CalendarEvent(
            title: title,
            date: date,
            ownerUsername: owner.username,
            owner: owner
        )
        modelContext.insert(event)
        try modelContext.save()
        return event
    }

    func deleteEvent(_ event: CalendarEvent) throws {
        modelContext.delete(event)
        try modelContext.save()
    }

    func deleteEvent(id: UUID) throws {
        let targetId = id
        let descriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { event in
                event.id == targetId
            }
        )
        if let match = try modelContext.fetch(descriptor).first {
            modelContext.delete(match)
            try modelContext.save()
        }
    }
}
