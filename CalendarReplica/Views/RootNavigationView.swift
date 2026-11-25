import SwiftUI

enum AuthRoute: Hashable {
    case register
}

enum MainRoute: Hashable {
    case calendar
}

struct RootNavigationView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(CalendarViewModel.self) private var calendarViewModel

    @State private var authPath: [AuthRoute] = []
    @State private var mainPath: [MainRoute] = []

    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                NavigationStack(path: $mainPath) {
                    HomeView(mainPath: $mainPath)
                        .navigationDestination(for: MainRoute.self) { route in
                            switch route {
                            case .calendar:
                                CalendarView()
                            }
                        }
                }
            } else {
                NavigationStack(path: $authPath) {
                    LoginView(authPath: $authPath)
                        .navigationDestination(for: AuthRoute.self) { route in
                            switch route {
                            case .register:
                                RegisterView()
                            }
                        }
                }
            }
        }
        .task {
            calendarViewModel.setActiveUser(authViewModel.currentUser)
        }
        .onChange(of: authViewModel.currentUser?.username) { _, _ in
            calendarViewModel.setActiveUser(authViewModel.currentUser)
            if !authViewModel.isAuthenticated {
                mainPath.removeAll()
                authPath.removeAll()
            }
        }
    }
}
