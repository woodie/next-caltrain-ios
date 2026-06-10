import Foundation

// MARK: - Models

struct Leg {
    let trainId: Int
    let station: String
    let depart: Int  // minutes since midnight

    var type: String { CaltrainService.trainType(trainId) }
    var directionString: String { trainId % 2 == 0 ? "SB" : "NB" }
    var label: String { "\(directionString) #\(trainId) \(type)" }
}

struct Trip {
    let legs: [Leg]
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

    func routes(from depart: String, to arrive: String, scheduleType: ScheduleType, minutes: Int) -> [Trip] {
        let needsTransfer = scheduleType == .weekday &&
            (CaltrainService.southCountyStations.contains(depart) ||
             CaltrainService.southCountyStations.contains(arrive))

        if needsTransfer {
            return transferRoutes(from: depart, to: arrive, scheduleType: scheduleType)
        } else {
            return directRoutes(from: depart, to: arrive, scheduleType: scheduleType)
        }
    }

    func nextIndex(trips: [Trip], minutes: Int) -> Int {
        return trips.firstIndex { $0.depart > minutes } ?? trips.count
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
                  times[arriveIdx] != nil else { continue }
            let leg = Leg(trainId: trainId, station: depart, depart: departTime)
            trips.append(Trip(legs: [leg]))
        }
        return trips.sorted { $0.depart < $1.depart }
    }

    private func transferRoutes(from origin: String, to destination: String, scheduleType: ScheduleType) -> [Trip] {
        let direction = CaltrainService.direction(from: origin, to: destination, stops: schedule.southStops)
        let transfer = CaltrainService.transferStation

        // South County leg: origin → San Jose Diridon
        let scSource = select(direction: direction, scheduleType: scheduleType)
        let scStops = direction == "North" ? schedule.northStops : schedule.southStops

        guard let originIdx = scStops.firstIndex(of: origin),
              let transferIdx = scStops.firstIndex(of: transfer) else { return [] }

        // Electric leg: San Jose Diridon → destination
        let elSource = select(direction: direction, scheduleType: scheduleType)
        let elStops = scStops  // same direction, same stop list

        guard let destIdx = elStops.firstIndex(of: destination) else { return [] }

        // Build map of SC trains: arrivalAtTransfer → departFromOrigin
        var scTrains: [(trainId: Int, departOrigin: Int, arriveTransfer: Int)] = []
        for (trainKey, times) in scSource {
            guard let trainId = Int(trainKey),
                  CaltrainService.isSouthCounty(trainId),
                  originIdx < times.count,
                  transferIdx < times.count,
                  let departTime = times[originIdx],
                  let arriveTime = times[transferIdx] else { continue }
            scTrains.append((trainId, departTime, arriveTime))
        }
        scTrains.sort { $0.departOrigin < $1.departOrigin }

        // Build sorted list of electric trains departing San Jose Diridon
        var elTrains: [(trainId: Int, departTransfer: Int)] = []
        for (trainKey, times) in elSource {
            guard let trainId = Int(trainKey),
                  !CaltrainService.isSouthCounty(trainId),
                  transferIdx < times.count,
                  destIdx < times.count,
                  let departTime = times[transferIdx],
                  times[destIdx] != nil else { continue }
            elTrains.append((trainId, departTime))
        }
        elTrains.sort { $0.departTransfer < $1.departTransfer }

        // Match each SC train to the next available electric
        var trips: [Trip] = []
        for sc in scTrains {
            guard let el = elTrains.first(where: { $0.departTransfer >= sc.arriveTransfer }) else { continue }
            let leg1 = Leg(trainId: sc.trainId, station: origin, depart: sc.departOrigin)
            let leg2 = Leg(trainId: el.trainId, station: transfer, depart: el.departTransfer)
            trips.append(Trip(legs: [leg1, leg2]))
        }
        return trips
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
