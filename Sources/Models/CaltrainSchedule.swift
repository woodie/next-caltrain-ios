import Foundation

enum ScheduleType: Int {
    case weekday = 0
    case weekend = 1
    case modified = 2

    var label: String {
        switch self {
        case .weekday: return "Weekday"
        case .weekend: return "Weekend"
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

class CaltrainSchedule {
    let schedule: Schedule
    let forToday: ScheduleType
    var selected: ScheduleType

    init(goodTime: GoodTimes, schedule: Schedule) {
        self.schedule = schedule
        self.forToday = CaltrainSchedule.optionIndex(goodTime: goodTime, specialDates: schedule.specialDates)
        self.selected = self.forToday
    }

    var label: String { selected.label }
    var swapped: Bool { forToday != selected }

    func next() {
        let nextRaw = (selected.rawValue + 1) % 3
        selected = ScheduleType(rawValue: nextRaw)!
    }

    static func optionIndex(goodTime: GoodTimes, specialDates: [String: Int]) -> ScheduleType {
        if let type = specialDates[goodTime.date] {
            return ScheduleType(rawValue: type) ?? .weekday
        } else if goodTime.dotw == 0 || goodTime.dotw == 6 {
            return .weekend
        } else {
            return .weekday
        }
    }
}
