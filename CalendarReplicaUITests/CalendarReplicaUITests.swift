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
        focusAndType("filip\n", into: registerUsername)

        let registerPassword = app.secureTextFields["register.password"]
        focusAndType("password123\n", into: registerPassword)

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
        let monthTitle = app.staticTexts["calendar.monthTitle"]
        XCTAssertTrue(monthTitle.waitForExistence(timeout: 10), "Calendar month grid should appear")
        let selectedDateLabel = app.staticTexts["calendar.selectedDate"]
        XCTAssertTrue(selectedDateLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["calendar.legend.holiday"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["calendar.legend.custom"].waitForExistence(timeout: 5))

        let holidayChipPredicate = NSPredicate(format: "identifier BEGINSWITH 'calendar.holidayChip.'")
        let firstHolidayChip = app.buttons.matching(holidayChipPredicate).firstMatch
        XCTAssertTrue(
            firstHolidayChip.waitForExistence(timeout: 15),
            "Live Nager.Date public holiday chips should load for current year"
        )
        Thread.sleep(forTimeInterval: 0.5)

        let todayKey = apiKey(fromDisplayDate: selectedDateLabel.label)
        let adjacentDayKey = adjacentApiKey(fromDisplayDate: selectedDateLabel.label)
        let todayDayButton = app.buttons["calendar.day.\(todayKey)"]
        XCTAssertTrue(todayDayButton.waitForExistence(timeout: 5), "Today's cell should exist in calendar grid")
        let initialTodayIndicator = (todayDayButton.value as? String) ?? ""
        XCTAssertFalse(initialTodayIndicator.contains("custom"), "Today should not have a custom event indicator yet")

        captureScreenshot(named: "04_calendar_screen")

        // 5. Add a custom event on today's date and verify blue custom indicator updates
        let eventField = app.textFields["calendar.eventTitle"]
        focusAndType("Doctor Appointment\n", into: eventField)

        let addEventButton = app.buttons["calendar.addEvent"]
        scrollToAndTap(addEventButton)

        let doctorEvent = app.staticTexts["Doctor Appointment"]
        XCTAssertTrue(doctorEvent.waitForExistence(timeout: 5), "Custom event should be displayed")
        let updatedTodayIndicator = (todayDayButton.value as? String) ?? ""
        XCTAssertTrue(updatedTodayIndicator.contains("custom"), "Today should now show custom event indicator")
        captureScreenshot(named: "05_custom_event_added")

        // 5b. Tap an adjacent day so today clearly shows its unselected slight-blue circle & dot
        let adjacentButton = app.buttons["calendar.day.\(adjacentDayKey)"]
        scrollToAndTap(adjacentButton)
        XCTAssertTrue(todayDayButton.waitForExistence(timeout: 5))
        XCTAssertTrue(((todayDayButton.value as? String) ?? "").contains("custom"))
        captureScreenshot(named: "05b_calendar_indicators_unselected")

        // 6. Select a live API public holiday date, verify slight-purple holiday indicator, & add a custom event
        let holidayDateKey = firstHolidayChip.identifier.replacingOccurrences(of: "calendar.holidayChip.", with: "")
        scrollToAndTap(firstHolidayChip)

        let holidayCard = app.staticTexts["calendar.holidayCard"]
        XCTAssertTrue(holidayCard.waitForExistence(timeout: 5), "API public holiday card should appear")

        let holidayDayButton = app.buttons["calendar.day.\(holidayDateKey)"]
        XCTAssertTrue(holidayDayButton.waitForExistence(timeout: 5))
        XCTAssertEqual(holidayDayButton.value as? String, "holiday")

        focusAndType("Holiday Dinner\n", into: eventField)
        scrollToAndTap(addEventButton)

        let holidayDinnerEvent = app.staticTexts["Holiday Dinner"]
        XCTAssertTrue(holidayDinnerEvent.waitForExistence(timeout: 5), "Custom event should appear alongside API holiday")
        XCTAssertTrue(holidayCard.exists, "API holiday card should remain visible alongside custom event")
        XCTAssertEqual(holidayDayButton.value as? String, "holiday,custom")
        captureScreenshot(named: "06_api_holiday_and_custom_event")

        // 7. Delete the custom event and verify holiday indicator remains while custom indicator clears
        let deleteButton = app.buttons["calendar.deleteEvent"].firstMatch
        scrollToAndTap(deleteButton)
        XCTAssertFalse(holidayDinnerEvent.waitForExistence(timeout: 2), "Deleted custom event should be removed")
        XCTAssertTrue(holidayCard.exists, "Public holiday card should remain after deleting custom event")
        XCTAssertEqual(holidayDayButton.value as? String, "holiday")
        captureScreenshot(named: "07_after_event_deleted")

        // 7b. Verify month navigation arrows work cleanly
        let currentMonthTitle = monthTitle.label
        scrollToAndTap(app.buttons["calendar.nextMonth"])
        XCTAssertNotEqual(monthTitle.label, currentMonthTitle, "Next month button should advance displayed month")
        scrollToAndTap(app.buttons["calendar.prevMonth"])
        XCTAssertEqual(monthTitle.label, currentMonthTitle, "Previous month button should return to original month")

        // 8. Sign out -> Login screen -> Log back in -> Verify SwiftData persistence & indicator
        app.buttons["calendar.signOut"].tap()
        XCTAssertTrue(loginTitle.waitForExistence(timeout: 10), "SignOut should return to Login screen")
        captureScreenshot(named: "08_signed_out_login")

        let loginUsername = app.textFields["login.username"]
        focusAndType("filip\n", into: loginUsername)

        let loginPassword = app.secureTextFields["login.password"]
        focusAndType("password123\n", into: loginPassword)

        scrollToAndTap(app.buttons["login.submit"])

        XCTAssertTrue(homeTitle.waitForExistence(timeout: 10), "Re-login should navigate back to Home")
        app.buttons["home.openCalendar"].tap()
        XCTAssertTrue(monthTitle.waitForExistence(timeout: 10))
        XCTAssertTrue(todayDayButton.waitForExistence(timeout: 5))
        XCTAssertTrue(((todayDayButton.value as? String) ?? "").contains("custom"))

        let persistedEvent = app.staticTexts["Doctor Appointment"]
        if !persistedEvent.waitForExistence(timeout: 3) {
            app.swipeUp()
        }
        XCTAssertTrue(
            persistedEvent.waitForExistence(timeout: 5),
            "Previously saved custom event should persist across sign-out and sign-in"
        )
    }

    private func apiKey(fromDisplayDate display: String) -> String {
        let parts = display.split(separator: ".")
        guard parts.count == 3 else { return "" }
        return "\(parts[2])-\(parts[1])-\(parts[0])"
    }

    private func adjacentApiKey(fromDisplayDate display: String) -> String {
        let parts = display.split(separator: ".")
        guard parts.count == 3, let day = Int(parts[0]) else { return "" }
        let adjacent = day == 1 ? 2 : day - 1
        return String(format: "%@-%@-%02d", String(parts[2]), String(parts[1]), adjacent)
    }

    private func focusAndType(_ text: String, into field: XCUIElement) {
        scrollToAndTap(field)
        if !app.keyboards.firstMatch.waitForExistence(timeout: 2) {
            Thread.sleep(forTimeInterval: 0.4)
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        field.typeText(text)
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
