import Foundation
import SwiftData

@Model
final class CalendarEvent {
    var id: UUID
    var ownerUsername: String
    var title: String
    var dateKey: String
    var date: Date
    var createdAt: Date
    var owner: UserModel?

    init(
        title: String,
        date: Date,
        ownerUsername: String,
        owner: UserModel? = nil,
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.ownerUsername = ownerUsername
        self.title = title
        self.dateKey = DateFormatting.apiDateKey(from: date)
        self.date = DateFormatting.normalizedNoonDate(from: date)
        self.createdAt = createdAt
        self.owner = owner
    }
}
