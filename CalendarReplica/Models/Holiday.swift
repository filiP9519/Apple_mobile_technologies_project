import Foundation

struct Holiday: Codable, Identifiable, Hashable, Sendable {
    let date: String
    let localName: String
    let name: String
    let countryCode: String

    var id: String {
        "\(countryCode)-\(date)-\(name)"
    }

    var parsedDate: Date? {
        DateFormatting.date(fromApiKey: date)
    }
}
