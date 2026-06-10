import Foundation

struct CaltrainSchedule: Codable {
    let specialDates: [String: Int]
    let saturdayTripIds: [Int]
    let northStops: [String]
    let southStops: [String]
    let northWeekday: [String: [Int?]]
    let northWeekend: [String: [Int?]]
    let southWeekday: [String: [Int?]]
    let southWeekend: [String: [Int?]]

    static func load() -> CaltrainSchedule {
        let url = Bundle.main.url(forResource: "schedule", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(CaltrainSchedule.self, from: data)
    }
}
