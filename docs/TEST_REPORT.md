# CalendarReplica Automated Test Report

- **Result**: `Passed`
- **Total Tests**: `18`
- **Passed**: `18`
- **Failed**: `0`
- **Skipped**: `0`

## Executed Test Cases

| Suite | Test Case | Result | Duration |
| --- | --- | --- | --- |
| CalendarReplicaTests / AuthViewModelTests | `testDuplicateRegistrationReturnsUsernameExistsError()` | Passed | 0.048s |
| CalendarReplicaTests / AuthViewModelTests | `testLoginWithEmptyCredentialsSetsError()` | Passed | 0.0085s |
| CalendarReplicaTests / AuthViewModelTests | `testLoginWithValidAndInvalidCredentials()` | Passed | 0.014s |
| CalendarReplicaTests / AuthViewModelTests | `testRegisterNewUserAutoAuthenticatesAndPersists()` | Passed | 0.018s |
| CalendarReplicaTests / AuthViewModelTests | `testRegisterWithEmptyCredentialsSetsError()` | Passed | 0.0048s |
| CalendarReplicaTests / AuthViewModelTests | `testSignOutClearsStateAndDefaults()` | Passed | 0.0077s |
| CalendarReplicaTests / CalendarIntentsTests | `testAddCalendarEventIntentPersistsEventToSwiftData()` | Passed | 0.034s |
| CalendarReplicaTests / CalendarIntentsTests | `testGetDayOverviewIntentCombinesHolidaysAndCustomEvents()` | Passed | 0.017s |
| CalendarReplicaTests / CalendarViewModelTests | `testAddAndDeleteCustomEventPersistsInSwiftData()` | Passed | 0.023s |
| CalendarReplicaTests / CalendarViewModelTests | `testDayIndicatorStateForHolidaysCustomEventsAndBoth()` | Passed | 0.026s |
| CalendarReplicaTests / CalendarViewModelTests | `testEventsAreIsolatedPerUserAndDate()` | Passed | 0.018s |
| CalendarReplicaTests / CalendarViewModelTests | `testHolidayAPIErrorSetsMessageWithoutCrashing()` | Passed | 0.012s |
| CalendarReplicaTests / CalendarViewModelTests | `testHolidayFilteringAndYearCaching()` | Passed | 0.12s |
| CalendarReplicaTests / CalendarViewModelTests | `testMoveMonthUpdatesDisplayedMonthAndLoadsNewYearHolidays()` | Passed | 0.006s |
| CalendarReplicaTests / HolidayAPIServiceTests | `testDecodeMockedNagerHolidayPayload()` | Passed | 0.49s |
| CalendarReplicaTests / HolidayAPIServiceTests | `testLiveNagerAPIFetchesSlovakPublicHolidays()` | Passed | 1s |
| CalendarReplicaTests / HolidayAPIServiceTests | `testNon200ResponseThrowsInvalidResponseError()` | Passed | 0.0029s |
| CalendarReplicaUITests / CalendarReplicaUITests | `testFullAppFlowNavigationAPIAndCustomEvents()` | Passed | 2m 48s |

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
