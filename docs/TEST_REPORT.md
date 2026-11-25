# CalendarReplica Automated Test Report

- **Result**: `Passed`
- **Total Tests**: `18`
- **Passed**: `18`
- **Failed**: `0`
- **Skipped**: `0`

## Executed Test Cases

| Suite | Test Case | Result | Duration |
| --- | --- | --- | --- |
| CalendarReplicaTests / AuthViewModelTests | `testDuplicateRegistrationReturnsUsernameExistsError()` | Passed | 0.052s |
| CalendarReplicaTests / AuthViewModelTests | `testLoginWithEmptyCredentialsSetsError()` | Passed | 0.0092s |
| CalendarReplicaTests / AuthViewModelTests | `testLoginWithValidAndInvalidCredentials()` | Passed | 0.011s |
| CalendarReplicaTests / AuthViewModelTests | `testRegisterNewUserAutoAuthenticatesAndPersists()` | Passed | 0.016s |
| CalendarReplicaTests / AuthViewModelTests | `testRegisterWithEmptyCredentialsSetsError()` | Passed | 0.0071s |
| CalendarReplicaTests / AuthViewModelTests | `testSignOutClearsStateAndDefaults()` | Passed | 0.012s |
| CalendarReplicaTests / CalendarIntentsTests | `testAddCalendarEventIntentPersistsEventToSwiftData()` | Passed | 0.19s |
| CalendarReplicaTests / CalendarIntentsTests | `testGetDayOverviewIntentCombinesHolidaysAndCustomEvents()` | Passed | 0.02s |
| CalendarReplicaTests / CalendarViewModelTests | `testAddAndDeleteCustomEventPersistsInSwiftData()` | Passed | 0.026s |
| CalendarReplicaTests / CalendarViewModelTests | `testDayIndicatorStateForHolidaysCustomEventsAndBoth()` | Passed | 0.19s |
| CalendarReplicaTests / CalendarViewModelTests | `testEventsAreIsolatedPerUserAndDate()` | Passed | 0.018s |
| CalendarReplicaTests / CalendarViewModelTests | `testHolidayAPIErrorSetsMessageWithoutCrashing()` | Passed | 0.014s |
| CalendarReplicaTests / CalendarViewModelTests | `testHolidayFilteringAndYearCaching()` | Passed | 0.0071s |
| CalendarReplicaTests / CalendarViewModelTests | `testMoveMonthUpdatesDisplayedMonthAndLoadsNewYearHolidays()` | Passed | 0.01s |
| CalendarReplicaTests / HolidayAPIServiceTests | `testDecodeMockedNagerHolidayPayload()` | Passed | 0.03s |
| CalendarReplicaTests / HolidayAPIServiceTests | `testLiveNagerAPIFetchesSlovakPublicHolidays()` | Passed | 0.23s |
| CalendarReplicaTests / HolidayAPIServiceTests | `testNon200ResponseThrowsInvalidResponseError()` | Passed | 0.0031s |
| CalendarReplicaUITests / CalendarReplicaUITests | `testFullAppFlowNavigationAPIAndCustomEvents()` | Passed | 3m 14s |

## Captured Simulator Screenshots

- `01_login_screen.png`
- `02_register_screen.png`
- `03_home_screen.png`
- `04_calendar_screen.png`
- `05_custom_event_added.png`
- `05b_calendar_indicators_unselected.png`
- `06_api_holiday_and_custom_event.png`
- `07_after_event_deleted.png`
- `08_signed_out_login.png`
