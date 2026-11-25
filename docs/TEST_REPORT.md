# CalendarReplica Automated Test Report

- **Result**: `Passed`
- **Total Tests**: `16`
- **Passed**: `16`
- **Failed**: `0`
- **Skipped**: `0`

## Executed Test Cases

| Suite | Test Case | Result | Duration |
| --- | --- | --- | --- |
| CalendarReplicaTests / AuthViewModelTests | `testDuplicateRegistrationReturnsUsernameExistsError()` | Passed | 0.043s |
| CalendarReplicaTests / AuthViewModelTests | `testLoginWithEmptyCredentialsSetsError()` | Passed | 0.0031s |
| CalendarReplicaTests / AuthViewModelTests | `testLoginWithValidAndInvalidCredentials()` | Passed | 0.0097s |
| CalendarReplicaTests / AuthViewModelTests | `testRegisterNewUserAutoAuthenticatesAndPersists()` | Passed | 0.01s |
| CalendarReplicaTests / AuthViewModelTests | `testRegisterWithEmptyCredentialsSetsError()` | Passed | 0.0029s |
| CalendarReplicaTests / AuthViewModelTests | `testSignOutClearsStateAndDefaults()` | Passed | 0.0065s |
| CalendarReplicaTests / CalendarIntentsTests | `testAddCalendarEventIntentPersistsEventToSwiftData()` | Passed | 0.031s |
| CalendarReplicaTests / CalendarIntentsTests | `testGetDayOverviewIntentCombinesHolidaysAndCustomEvents()` | Passed | 0.011s |
| CalendarReplicaTests / CalendarViewModelTests | `testAddAndDeleteCustomEventPersistsInSwiftData()` | Passed | 0.55s |
| CalendarReplicaTests / CalendarViewModelTests | `testEventsAreIsolatedPerUserAndDate()` | Passed | 0.012s |
| CalendarReplicaTests / CalendarViewModelTests | `testHolidayAPIErrorSetsMessageWithoutCrashing()` | Passed | 0.012s |
| CalendarReplicaTests / CalendarViewModelTests | `testHolidayFilteringAndYearCaching()` | Passed | 0.013s |
| CalendarReplicaTests / HolidayAPIServiceTests | `testDecodeMockedNagerHolidayPayload()` | Passed | 0.014s |
| CalendarReplicaTests / HolidayAPIServiceTests | `testLiveNagerAPIFetchesSlovakPublicHolidays()` | Passed | 0.18s |
| CalendarReplicaTests / HolidayAPIServiceTests | `testNon200ResponseThrowsInvalidResponseError()` | Passed | 0.0014s |
| CalendarReplicaUITests / CalendarReplicaUITests | `testFullAppFlowNavigationAPIAndCustomEvents()` | Passed | 2m 47s |

## Captured Simulator Screenshots

- `01_login_screen.png`
- `02_register_screen.png`
- `03_home_screen.png`
- `04_calendar_screen.png`
- `05_custom_event_added.png`
- `06_api_holiday_and_custom_event.png`
- `07_after_event_deleted.png`
- `08_signed_out_login.png`
