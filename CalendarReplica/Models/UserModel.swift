import Foundation
import SwiftData

@Model
final class UserModel {
    var id: UUID
    @Attribute(.unique) var username: String
    var password: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \CalendarEvent.owner)
    var events: [CalendarEvent] = []

    init(
        username: String,
        password: String,
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.username = username
        self.password = password
        self.createdAt = createdAt
    }
}
