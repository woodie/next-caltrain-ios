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
    let scheduleDate: Int?  // epoch ms; matches PWA's scheduleDate (stop_times.txt mtime)

    private static let remoteURL = URL(string: "https://next-caltrain-pwa.appspot.com/schedule.json")!

    private static var cachedFileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("schedule.json")
    }

    /// Synchronous load for app launch: prefer a previously-cached (fetched) schedule,
    /// falling back to the bundled copy if no cache exists or it's invalid.
    static func load() -> Schedule {
        if let cached = try? Data(contentsOf: cachedFileURL),
           let schedule = try? JSONDecoder().decode(Schedule.self, from: cached),
           schedule.isValid {
            print("[Schedule] loaded from cache, scheduleDate=\(schedule.scheduleDate ?? -1)")
            return schedule
        }
        print("[Schedule] loaded from bundle")
        return loadBundled()
    }

    private static func loadBundled() -> Schedule {
        let url = Bundle.main.url(forResource: "schedule", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        return try! JSONDecoder().decode(Schedule.self, from: data)
    }

    /// Basic structural validation: stop lists are non-empty, and every schedule
    /// table's train arrays match the length of their direction's stop list.
    var isValid: Bool {
        guard !northStops.isEmpty, !southStops.isEmpty else { return false }

        let northTables = [northWeekday, northWeekend, northModified]
        let southTables = [southWeekday, southWeekend, southModified]

        for table in northTables {
            for (_, times) in table where times.count != northStops.count {
                return false
            }
        }
        for table in southTables {
            for (_, times) in table where times.count != southStops.count {
                return false
            }
        }
        return true
    }

    /// Fetches the latest published schedule from the network and, if valid,
    /// writes it to the local cache for use on the next launch. Safe to call
    /// fire-and-forget; failures are silently ignored (current session keeps
    /// using whatever was loaded via `load()`).
    static func refreshFromNetwork() {
        URLSession.shared.dataTask(with: remoteURL) { data, response, error in
            if let error = error {
                print("[Schedule] fetch error: \(error)")
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[Schedule] no HTTP response")
                return
            }
            print("[Schedule] fetch status: \(httpResponse.statusCode)")
            guard httpResponse.statusCode == 200, let data = data else { return }

            guard let schedule = try? JSONDecoder().decode(Schedule.self, from: data) else {
                print("[Schedule] decode failed")
                return
            }
            guard schedule.isValid else {
                print("[Schedule] fetched schedule failed validation")
                return
            }

            do {
                try data.write(to: cachedFileURL, options: .atomic)
                print("[Schedule] cached fetched schedule (\(data.count) bytes) at \(cachedFileURL.path)")
            } catch {
                print("[Schedule] cache write failed: \(error)")
            }
        }.resume()
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
