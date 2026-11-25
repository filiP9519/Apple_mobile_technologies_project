import XCTest

final class CalendarReplicaUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testFullAppFlowNavigationAPIAndCustomEvents() throws {
        // 1. Login screen & validation error check
        let loginTitle = app.staticTexts["login.title"]
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 10), "Login screen should appear at launch")
        captureScreenshot(named: "01_login_screen")

        app.buttons["login.submit"].tap()
        let loginError = app.staticTexts["login.error"]
        XCTAssertTrue(loginError.waitForExistence(timeout: 5), "Empty login should show inline error")

        // 2. Navigate to Register screen & create account
        app.buttons["login.goToRegister"].tap()
        let registerTitle = app.staticTexts["register.title"]
        XCTAssertTrue(registerTitle.waitForExistence(timeout: 5), "Register screen should appear")

        let registerUsername = app.textFields["register.username"]
        XCTAssertTrue(registerUsername.waitForExistence(timeout: 5))
        registerUsername.tap()
        registerUsername.typeText("filip\n")

        let registerPassword = app.secureTextFields["register.password"]
        XCTAssertTrue(registerPassword.waitForExistence(timeout: 5))
        registerPassword.tap()
        registerPassword.typeText("password123\n")

        captureScreenshot(named: "02_register_screen")

        let registerButton = app.buttons["register.submit"]
        scrollToAndTap(registerButton)

        // 3. Home screen verification
        let homeTitle = app.staticTexts["home.title"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 10), "Registration should navigate to Home screen")
        let welcomeLabel = app.staticTexts["home.welcome"]
        XCTAssertTrue(welcomeLabel.label.contains("filip"), "Welcome message should include username")
        captureScreenshot(named: "03_home_screen")

        // 4. Navigate to Calendar screen & wait for live Nager.Date public holidays
        app.buttons["home.openCalendar"].tap()
        let datePicker = app.datePickers["calendar.datePicker"]
        XCTAssertTrue(datePicker.waitForExistence(timeout: 10), "Calendar DatePicker should appear")
        XCTAssertTrue(app.staticTexts["calendar.selectedDate"].waitForExistence(timeout: 5))

        let holidayChipPredicate = NSPredicate(format: "identifier BEGINSWITH 'calendar.holidayChip.'")
        let firstHolidayChip = app.buttons.matching(holidayChipPredicate).firstMatch
        XCTAssertTrue(
            firstHolidayChip.waitForExistence(timeout: 15),
            "Live Nager.Date public holiday chips should load for current year"
        )
        captureScreenshot(named: "04_calendar_screen")

        // 5. Add a custom event on today's date
        let eventField = app.textFields["calendar.eventTitle"]
        scrollToAndTap(eventField)
        eventField.typeText("Doctor Appointment\n")

        let addEventButton = app.buttons["calendar.addEvent"]
        scrollToAndTap(addEventButton)

        let doctorEvent = app.staticTexts["Doctor Appointment"]
        XCTAssertTrue(doctorEvent.waitForExistence(timeout: 5), "Custom event should be displayed")
        captureScreenshot(named: "05_custom_event_added")

        // 6. Select a live API public holiday date & add a custom event on that same date
        scrollToAndTap(firstHolidayChip)

        let holidayCard = app.staticTexts["calendar.holidayCard"]
        XCTAssertTrue(holidayCard.waitForExistence(timeout: 5), "API public holiday card should appear")

        scrollToAndTap(eventField)
        eventField.typeText("Holiday Dinner\n")
        scrollToAndTap(addEventButton)

        let holidayDinnerEvent = app.staticTexts["Holiday Dinner"]
        XCTAssertTrue(holidayDinnerEvent.waitForExistence(timeout: 5), "Custom event should appear alongside API holiday")
        XCTAssertTrue(holidayCard.exists, "API holiday card should remain visible alongside custom event")
        captureScreenshot(named: "06_api_holiday_and_custom_event")

        // 7. Delete the custom event and verify API holiday stays
        let deleteButton = app.buttons["calendar.deleteEvent"].firstMatch
        scrollToAndTap(deleteButton)
        XCTAssertFalse(holidayDinnerEvent.waitForExistence(timeout: 2), "Deleted custom event should be removed")
        XCTAssertTrue(holidayCard.exists, "Public holiday card should remain after deleting custom event")
        captureScreenshot(named: "07_after_event_deleted")

        // 8. Sign out -> Login screen -> Log back in -> Verify SwiftData persistence
        app.buttons["calendar.signOut"].tap()
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 10), "SignOut should return to Login screen")
        captureScreenshot(named: "08_signed_out_login")

        let loginUsername = app.textFields["login.username"]
        loginUsername.tap()
        loginUsername.typeText("filip\n")

        let loginPassword = app.secureTextFields["login.password"]
        loginPassword.tap()
        loginPassword.typeText("password123\n")

        scrollToAndTap(app.buttons["login.submit"])

        XCTAssertTrue(homeTitle.waitForExistence(timeout: 10), "Re-login should navigate back to Home")
        app.buttons["home.openCalendar"].tap()
        XCTAssertTrue(datePicker.waitForExistence(timeout: 10))
        XCTAssertTrue(
            app.staticTexts["Doctor Appointment"].waitForExistence(timeout: 5),
            "Previously saved custom event should persist across sign-out and sign-in"
        )
    }

    private func scrollToAndTap(_ element: XCUIElement, maxSwipes: Int = 3) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Element \(element) should exist before tapping")
        for _ in 0..<maxSwipes {
            if element.isHittable {
                element.tap()
                return
            }
            app.swipeUp()
        }
        for _ in 0..<(maxSwipes * 2) {
            if element.isHittable {
                element.tap()
                return
            }
            app.swipeDown()
        }
        element.tap()
    }

    private func captureScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
