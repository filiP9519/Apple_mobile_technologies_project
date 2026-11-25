import SwiftUI

struct CalendarView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(CalendarViewModel.self) private var calendarViewModel

    @State private var eventTitle: String = ""
    @FocusState private var isTitleFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CalendarGridView(
                    displayedMonth: calendarViewModel.displayedMonth,
                    selectedDate: calendarViewModel.selectedDate,
                    indicatorForDate: { date in
                        calendarViewModel.indicatorState(for: date)
                    },
                    onSelectDate: { newDate in
                        Task {
                            await calendarViewModel.selectDate(newDate)
                        }
                    },
                    onChangeMonth: { offset in
                        Task {
                            await calendarViewModel.moveMonth(by: offset)
                        }
                    }
                )

                Text(DateFormatting.displayDate(from: calendarViewModel.selectedDate))
                    .font(.title2.bold())
                    .accessibilityIdentifier("calendar.selectedDate")

                if !calendarViewModel.allHolidaysForCurrentYear.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Public Holidays (\(calendarViewModel.countryCode))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(calendarViewModel.allHolidaysForCurrentYear) { holiday in
                                    let isSelected = holiday.date == DateFormatting.apiDateKey(from: calendarViewModel.selectedDate)
                                    Button {
                                        if let targetDate = holiday.parsedDate {
                                            Task {
                                                await calendarViewModel.selectDate(targetDate)
                                            }
                                        }
                                    } label: {
                                        Text("\(DateFormatting.shortDayMonth(from: holiday.date)) \(holiday.localName)")
                                            .font(.caption.weight(.medium))
                                            .lineLimit(1)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.14))
                                            )
                                            .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("calendar.holidayChip.\(holiday.date)")
                                }
                            }
                        }
                    }
                }

                VStack(spacing: 10) {
                    TextField("Event Title", text: $eventTitle)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTitleFieldFocused)
                        .accessibilityIdentifier("calendar.eventTitle")

                    Button {
                        calendarViewModel.addEvent(title: eventTitle)
                        eventTitle = ""
                        isTitleFieldFocused = false
                    } label: {
                        Text("Add event")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("calendar.addEvent")
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground))
                )

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Events on this day:")
                            .font(.headline)
                        Spacer()
                        if calendarViewModel.isLoadingHolidays {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }

                    if let apiError = calendarViewModel.apiErrorMessage {
                        HStack {
                            Text(apiError)
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Spacer()
                            Button("Retry") {
                                Task {
                                    let year = DateFormatting.year(from: calendarViewModel.selectedDate)
                                    await calendarViewModel.loadHolidaysIfNeeded(for: year, forceRefresh: true)
                                }
                            }
                            .font(.caption.weight(.semibold))
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.orange.opacity(0.12))
                        )
                    }

                    ForEach(calendarViewModel.holidaysForSelectedDate) { holiday in
                        HolidayCardView(holiday: holiday)
                    }

                    if calendarViewModel.events.isEmpty && calendarViewModel.holidaysForSelectedDate.isEmpty {
                        Text("No events.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                            .accessibilityIdentifier("calendar.emptyState")
                    } else {
                        ForEach(calendarViewModel.events, id: \.id) { event in
                            EventCardView(event: event) {
                                calendarViewModel.deleteEvent(event)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("SignOut") {
                    authViewModel.signOut()
                }
                .accessibilityIdentifier("calendar.signOut")
            }
        }
        .task {
            await calendarViewModel.selectDate(calendarViewModel.selectedDate)
        }
    }
}

private struct HolidayCardView: View {
    let holiday: Holiday

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("🎉 \(holiday.localName)")
                    .font(.body.weight(.semibold))
                    .accessibilityIdentifier("calendar.holidayCard")

                Text("\(holiday.name) • Public Holiday (\(holiday.countryCode))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.14))
        )
    }
}

private struct EventCardView: View {
    let event: CalendarEvent
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.body.weight(.medium))
                    .accessibilityIdentifier("calendar.eventCard")

                Text("Custom Event • \(DateFormatting.displayDate(from: event.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .padding(6)
            }
            .accessibilityLabel("Delete Event \(event.title)")
            .accessibilityIdentifier("calendar.deleteEvent")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.10))
        )
    }
}
