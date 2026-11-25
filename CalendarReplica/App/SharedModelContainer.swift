import Foundation
import SwiftData

enum SharedModelContainer {
    static let schema = Schema([UserModel.self, CalendarEvent.self])
    static let activeUsernameDefaultsKey = "calendarReplica.activeUsername"

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static let shared: ModelContainer = {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITesting")
        do {
            return try makeContainer(inMemory: isUITesting)
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }()
}
