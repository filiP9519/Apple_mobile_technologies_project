import Foundation

enum DateFormatting {
    static func apiDateKey(from date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 2026
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func displayDate(from date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 2026
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%02d.%02d.%04d", day, month, year)
    }

    static func shortDayMonth(from apiKey: String) -> String {
        let parts = apiKey.split(separator: "-")
        guard parts.count == 3 else { return apiKey }
        return "\(parts[2]).\(parts[1])"
    }

    static func date(fromApiKey key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return nil
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)
    }

    static func normalizedNoonDate(from date: Date, calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var noon = DateComponents()
        noon.year = components.year
        noon.month = components.month
        noon.day = components.day
        noon.hour = 12
        noon.minute = 0
        noon.second = 0
        return calendar.date(from: noon) ?? date
    }

    static func year(from date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.year, from: date)
    }
}
