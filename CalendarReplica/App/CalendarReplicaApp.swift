import SwiftData
import SwiftUI

@main
struct CalendarReplicaApp: App {
    private let modelContainer: ModelContainer
    @State private var authViewModel: AuthViewModel
    @State private var calendarViewModel: CalendarViewModel

    init() {
        let container = SharedModelContainer.shared
        self.modelContainer = container

        let repository = CalendarRepository(modelContext: container.mainContext)
        _authViewModel = State(initialValue: AuthViewModel(repository: repository))
        _calendarViewModel = State(initialValue: CalendarViewModel(repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            RootNavigationView()
                .environment(authViewModel)
                .environment(calendarViewModel)
        }
        .modelContainer(modelContainer)
    }
}
