import Foundation
import Observation

enum AuthState: Equatable {
    case unauthenticated
    case authenticated(username: String)
    case loading
    case error(String)
}

@Observable
@MainActor
final class AuthViewModel {
    var authState: AuthState = .unauthenticated
    var currentUser: UserModel?
    var errorMessage: String?

    var isAuthenticated: Bool {
        currentUser != nil
    }

    private let repository: CalendarRepository
    private let userDefaults: UserDefaults

    init(repository: CalendarRepository, userDefaults: UserDefaults = .standard) {
        self.repository = repository
        self.userDefaults = userDefaults
    }

    func login(username: String, password: String) {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            let message = "Username and password cannot be empty!"
            errorMessage = message
            authState = .error(message)
            return
        }

        authState = .loading
        do {
            if let user = try repository.login(username: trimmedUsername, password: password) {
                currentUser = user
                errorMessage = nil
                userDefaults.set(user.username, forKey: SharedModelContainer.activeUsernameDefaultsKey)
                authState = .authenticated(username: user.username)
            } else {
                let message = "Invalid username or password"
                errorMessage = message
                authState = .error(message)
            }
        } catch {
            let message = "Login failed: \(error.localizedDescription)"
            errorMessage = message
            authState = .error(message)
        }
    }

    func register(username: String, password: String) {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUsername.isEmpty, !password.isEmpty else {
            let message = "Username and password cannot be empty!"
            errorMessage = message
            authState = .error(message)
            return
        }

        authState = .loading
        do {
            if let user = try repository.register(username: trimmedUsername, password: password) {
                currentUser = user
                errorMessage = nil
                userDefaults.set(user.username, forKey: SharedModelContainer.activeUsernameDefaultsKey)
                authState = .authenticated(username: user.username)
            } else {
                let message = "Username already exists"
                errorMessage = message
                authState = .error(message)
            }
        } catch {
            let message = "Registration failed: \(error.localizedDescription)"
            errorMessage = message
            authState = .error(message)
        }
    }

    func signOut() {
        currentUser = nil
        errorMessage = nil
        userDefaults.removeObject(forKey: SharedModelContainer.activeUsernameDefaultsKey)
        authState = .unauthenticated
    }

    func clearError() {
        errorMessage = nil
        if case .error = authState {
            authState = isAuthenticated
                ? .authenticated(username: currentUser?.username ?? "")
                : .unauthenticated
        }
    }
}
