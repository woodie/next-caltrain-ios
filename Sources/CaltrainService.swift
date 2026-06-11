import Foundation

// MARK: - Models

struct Leg {
    let trainId: Int
    let station: String
    let depart: Int  // minutes since midnight
}

struct Trip: Identifiable {
    let id: Int       // lead train ID
    let legs: [Leg]
    let arrive: Int   // arrival at final destination (minutes since midnight)

    var depart: Int { legs.first!.depart }
    var isTransfer: Bool { legs.count > 1 }
}

// MARK: - Service

struct CaltrainService {
    let schedule: Schedule

    static let southCountyStations: Set<String> = [
        "Gilroy", "San Martin", "Morgan Hill", "Blossom Hill", "Capitol"
    ]
    static let transferStation = "San Jose Diridon"

    // MARK: - Public

    // NOTE: South County <-> electric transfer routing has been removed for now.
    // The previous implementation incorrectly treated any trip touching a South
    // County station as needing a transfer (even SC-to-SC trips), and the
    // electric/SC table+stop-list pairing for transfers needs more investigation.
    // See git history (CaltrainService.swift, transferRoutes/needsTransfer) to
    // restore/rework this later.
    func routes(from depart: String, to arrive: String, scheduleType: ScheduleType) -> [Trip] {
        return directRoutes(from: depart, to: arrive, scheduleType: scheduleType)
    }

    func nextIndex(trips: [Trip], minutes: Int) -> Int {
        return trips.firstIndex { $0.depart >= minutes } ?? trips.count
    }

    // MARK: - Private

    private func directRoutes(from depart: String, to arrive: String, scheduleType: ScheduleType) -> [Trip] {
        let direction = CaltrainService.direction(from: depart, to: arrive, stops: schedule.southStops)
        let source = select(direction: direction, scheduleType: scheduleType)
        let stops = direction == "North" ? schedule.northStops : schedule.southStops

        guard let departIdx = stops.firstIndex(of: depart),
              let arriveIdx = stops.firstIndex(of: arrive) else { return [] }

        var trips: [Trip] = []
        for (trainKey, times) in source {
            guard let trainId = Int(trainKey),
                  departIdx < times.count,
                  arriveIdx < times.count,
                  let departTime = times[departIdx],
                  let arriveTime = times[arriveIdx] else { continue }
            let leg = Leg(trainId: trainId, station: depart, depart: departTime)
            trips.append(Trip(id: trainId, legs: [leg], arrive: arriveTime))
        }
        return trips.sorted { $0.depart < $1.depart }
    }

    // MARK: - Helpers

    static func direction(from depart: String, to arrive: String, stops: [String]) -> String {
        let departIdx = stops.firstIndex(of: depart) ?? 0
        let arriveIdx = stops.firstIndex(of: arrive) ?? 0
        return departIdx < arriveIdx ? "South" : "North"
    }

    static func isSouthCounty(_ trainId: Int) -> Bool {
        return trainId > 800 && trainId <= 900
    }

    static func trainType(_ trainId: Int) -> String {
        switch trainId {
        case 901...:    return "Unknown"
        case 801...900: return "South County"
        case 501...800: return "Express"
        case 401...500: return "Limited"
        case 101...400: return "Local"
        default:        return "Unknown"
        }
    }

    private func select(direction: String, scheduleType: ScheduleType) -> [String: [Int?]] {
        switch scheduleType {
        case .weekday:  return direction == "North" ? schedule.northWeekday  : schedule.southWeekday
        case .weekend:  return direction == "North" ? schedule.northWeekend  : schedule.southWeekend
        case .modified: return direction == "North" ? schedule.northModified : schedule.southModified
        }
    }
}
