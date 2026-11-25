import SwiftData
import XCTest
@testable import CalendarReplica

@MainActor
final class AuthViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var repository: CalendarRepository!
    private var defaultsSuiteName: String!
    private var userDefaults: UserDefaults!
    private var viewModel: AuthViewModel!

    override func setUpWithError() throws {
        container = try SharedModelContainer.makeContainer(inMemory: true)
        repository = CalendarRepository(modelContext: container.mainContext)
        defaultsSuiteName = "AuthViewModelTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: defaultsSuiteName)!
        viewModel = AuthViewModel(repository: repository, userDefaults: userDefaults)
    }

    override func tearDownWithError() throws {
        userDefaults.removePersistentDomain(forName: defaultsSuiteName)
        viewModel = nil
        repository = nil
        container = nil
    }

    func testLoginWithEmptyCredentialsSetsError() {
        viewModel.login(username: "   ", password: "")

        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.errorMessage, "Username and password cannot be empty!")
        XCTAssertEqual(viewModel.authState, .error("Username and password cannot be empty!"))
    }

    func testRegisterWithEmptyCredentialsSetsError() {
        viewModel.register(username: "", password: "secret")

        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.errorMessage, "Username and password cannot be empty!")
    }

    func testRegisterNewUserAutoAuthenticatesAndPersists() throws {
        viewModel.register(username: "filip", password: "password123")

        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.currentUser?.username, "filip")
        XCTAssertEqual(viewModel.authState, .authenticated(username: "filip"))
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(
            userDefaults.string(forKey: SharedModelContainer.activeUsernameDefaultsKey),
            "filip"
        )

        let stored = try repository.findUser(username: "filip")
        XCTAssertNotNil(stored)
    }

    func testDuplicateRegistrationReturnsUsernameExistsError() {
        viewModel.register(username: "filip", password: "password123")
        viewModel.signOut()

        viewModel.register(username: "filip", password: "otherPassword")

        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.errorMessage, "Username already exists")
    }

    func testLoginWithValidAndInvalidCredentials() {
        viewModel.register(username: "alice", password: "secret")
        viewModel.signOut()

        viewModel.login(username: "alice", password: "wrong")
        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.errorMessage, "Invalid username or password")

        viewModel.login(username: "alice", password: "secret")
        XCTAssertTrue(viewModel.isAuthenticated)
        XCTAssertEqual(viewModel.currentUser?.username, "alice")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSignOutClearsStateAndDefaults() {
        viewModel.register(username: "bob", password: "123")
        XCTAssertTrue(viewModel.isAuthenticated)

        viewModel.signOut()

        XCTAssertFalse(viewModel.isAuthenticated)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.authState, .unauthenticated)
        XCTAssertNil(userDefaults.string(forKey: SharedModelContainer.activeUsernameDefaultsKey))
    }
}
