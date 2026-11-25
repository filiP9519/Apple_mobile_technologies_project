import SwiftUI

private struct CalendarGridDay: Identifiable {
    let id: String
    let date: Date
    let dayNumber: Int
}

struct CalendarGridView: View {
    let displayedMonth: Date
    let selectedDate: Date
    let indicatorForDate: (Date) -> DayIndicatorState
    let onSelectDate: (Date) -> Void
    let onChangeMonth: (Int) -> Void

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private static let monthTitleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private var weekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let startIndex = max(0, calendar.firstWeekday - 1)
        return Array(symbols[startIndex...] + symbols[..<startIndex]).map { $0.uppercased() }
    }

    private var monthGrid: (leadingEmptyCount: Int, days: [CalendarGridDay]) {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let year = components.year,
              let month = components.month,
              let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1, hour: 12)),
              let dayRange = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return (0, [])
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmpty = (firstWeekday - calendar.firstWeekday + 7) % 7

        let days: [CalendarGridDay] = dayRange.compactMap { day in
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) else {
                return nil
            }
            return CalendarGridDay(
                id: DateFormatting.apiDateKey(from: date, calendar: calendar),
                date: date,
                dayNumber: day
            )
        }
        return (leadingEmpty, days)
    }

    var body: some View {
        let grid = monthGrid
        let selectedKey = DateFormatting.apiDateKey(from: selectedDate, calendar: calendar)
        let todayKey = DateFormatting.apiDateKey(from: Date(), calendar: calendar)

        VStack(spacing: 12) {
            HStack {
                Text(Self.monthTitleFormatter.string(from: displayedMonth))
                    .font(.headline)
                    .accessibilityIdentifier("calendar.monthTitle")

                Spacer()

                HStack(spacing: 12) {
                    Button {
                        onChangeMonth(-1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 30, height: 30)
                    }
                    .accessibilityLabel("Previous Month")
                    .accessibilityIdentifier("calendar.prevMonth")

                    Button {
                        onChangeMonth(1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 30, height: 30)
                    }
                    .accessibilityLabel("Next Month")
                    .accessibilityIdentifier("calendar.nextMonth")
                }
            }
            .padding(.horizontal, 4)

            HStack(spacing: 4) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0..<grid.leadingEmptyCount, id: \.self) { _ in
                    Color.clear
                        .frame(height: 44)
                }

                ForEach(grid.days) { item in
                    let indicator = indicatorForDate(item.date)
                    let isSelected = item.id == selectedKey
                    let isToday = item.id == todayKey

                    Button {
                        onSelectDate(item.date)
                    } label: {
                        VStack(spacing: 3) {
                            ZStack {
                                Circle()
                                    .fill(circleFill(isSelected: isSelected, indicator: indicator))

                                if let strokeColor = circleStroke(isSelected: isSelected, isToday: isToday, indicator: indicator) {
                                    Circle()
                                        .stroke(strokeColor, lineWidth: isToday && !indicator.hasHoliday && !indicator.hasCustomEvent ? 1.2 : 1.5)
                                }

                                Text("\(item.dayNumber)")
                                    .font(.subheadline.weight(isSelected || isToday || indicator.hasHoliday || indicator.hasCustomEvent ? .semibold : .regular))
                                    .foregroundStyle(textColor(isSelected: isSelected, isToday: isToday, indicator: indicator))
                            }
                            .frame(width: 34, height: 34)

                            HStack(spacing: 3) {
                                if indicator.hasHoliday {
                                    Circle()
                                        .fill(Color.purple)
                                        .frame(width: 5, height: 5)
                                }
                                if indicator.hasCustomEvent {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .frame(height: 6)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("calendar.day.\(item.id)")
                    .accessibilityLabel(DateFormatting.displayDate(from: item.date))
                    .accessibilityValue(indicator.accessibilityValue)
                }
            }

            Divider()

            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.20))
                            .frame(width: 14, height: 14)
                        Circle()
                            .stroke(Color.purple.opacity(0.55), lineWidth: 1.2)
                            .frame(width: 14, height: 14)
                    }
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 5, height: 5)
                    Text("National Holiday")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("calendar.legend.holiday")

                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.18))
                            .frame(width: 14, height: 14)
                        Circle()
                            .stroke(Color.blue.opacity(0.55), lineWidth: 1.2)
                            .frame(width: 14, height: 14)
                    }
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 5, height: 5)
                    Text("Custom Event")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("calendar.legend.custom")

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 14, height: 14)
                    Text("Selected")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("calendar.legend.selected")
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func circleFill(isSelected: Bool, indicator: DayIndicatorState) -> AnyShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor)
        }
        switch (indicator.hasHoliday, indicator.hasCustomEvent) {
        case (true, true):
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.purple.opacity(0.22), Color.blue.opacity(0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case (true, false):
            return AnyShapeStyle(Color.purple.opacity(0.20))
        case (false, true):
            return AnyShapeStyle(Color.blue.opacity(0.18))
        case (false, false):
            return AnyShapeStyle(Color.clear)
        }
    }

    private func circleStroke(isSelected: Bool, isToday: Bool, indicator: DayIndicatorState) -> Color? {
        guard !isSelected else { return nil }
        switch (indicator.hasHoliday, indicator.hasCustomEvent) {
        case (true, _):
            return Color.purple.opacity(0.50)
        case (false, true):
            return Color.blue.opacity(0.55)
        case (false, false):
            return isToday ? Color.accentColor.opacity(0.45) : nil
        }
    }

    private func textColor(isSelected: Bool, isToday: Bool, indicator: DayIndicatorState) -> Color {
        if isSelected {
            return .white
        }
        if indicator.hasHoliday {
            return .purple
        }
        if indicator.hasCustomEvent {
            return .blue
        }
        if isToday {
            return .accentColor
        }
        return .primary
    }
}
