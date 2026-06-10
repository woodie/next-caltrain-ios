import Foundation

enum ScheduleType: Int, Equatable {
    case weekday = 0
    case weekend = 1
    case modified = 2

    var label: String {
        switch self {
        case .weekday:  return "Weekday"
        case .weekend:  return "Weekend"
        case .modified: return "Modified"
        }
    }
}

struct Schedule: Codable {
    let specialDates: [String: Int]
    let northStops: [String]
    let southStops: [String]
    let northWeekday: [String: [Int?]]
    let northWeekend: [String: [Int?]]
    let northModified: [String: [Int?]]
    let southWeekday: [String: [Int?]]
    let southWeekend: [String: [Int?]]
    let southModified: [String: [Int?]]

    static func load() -> Schedule {
        let url = Bundle.main.url(forResource: "schedule", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(Schedule.self, from: data)
    }
}

struct CaltrainSchedule {
    static func optionIndex(date: String, dotw: Int, specialDates: [String: Int]) -> ScheduleType {
        if let type = specialDates[date] {
            return ScheduleType(rawValue: type) ?? .weekday
        } else if dotw == 0 || dotw == 6 {
            return .weekend
        } else {
            return .weekday
        }
    }
}
