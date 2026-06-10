import SwiftUI

enum StopRole {
    case past, origin, destination, transfer, future
}

struct StopRow: View {
    let time: Int
    let station: String
    let role: StopRole
    let isLast: Bool
    var transferLabel: String? = nil

    // Line and dot color — past=cyan, future=green, matches legacy CSS
    var trackColor: Color {
        switch role {
        case .past: return .calPast
        default:    return .calArrive
        }
    }

    // Dot color — origin/destination/transfer are white (.target in legacy)
    var dotColor: Color {
        switch role {
        case .origin, .destination, .transfer: return .white
        default: return trackColor
        }
    }

    // Time and station name color
    var textColor: Color {
        switch role {
        case .past: return .calPast
        default:    return .white
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // station-time
            Text(GoodTimes.fullTime(time))
                .foregroundColor(textColor)
                .font(.system(size: AppStyle.fontStationTime, weight: .regular))
                .frame(width: 75, alignment: .trailing)

            // station-spacer: vertical line + dot
            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(trackColor)
                        .frame(width: 2)
                        .offset(y: 10)
                }
                Circle()
                    .fill(dotColor)
                    .frame(width: 10, height: 10)
            }
            .frame(width: 10)

            // station-name
            VStack(alignment: .leading, spacing: 2) {
                Text(station)
                    .foregroundColor(textColor)
                    .font(.system(size: AppStyle.fontStationName, weight: .regular))
                if let label = transferLabel {
                    Text(label)
                        .foregroundColor(.calPast)
                        .font(.system(size: AppStyle.fontStationName - 2, weight: .regular))
                }
            }
            Spacer()
        }
        .frame(minHeight: 28)
        .padding(.horizontal, 16)
    }
}

struct TripStop {
    let time: Int
    let station: String
    let role: StopRole
    var transferLabel: String? = nil
}

struct TripDetailView: View {
    let trip: Trip
    let schedule: Schedule
    let origin: String
    let destination: String
    let scheduleType: ScheduleType
    let goodTimes: GoodTimes

    private var stops: [TripStop] {
        var result: [TripStop] = []

        for (legIndex, leg) in trip.legs.enumerated() {
            let direction = CaltrainService.direction(
                from: leg.station,
                to: destination,
                stops: schedule.southStops
            )
            let stopList = direction == "North" ? schedule.northStops : schedule.southStops
            let source: [String: [Int?]]
            switch scheduleType {
            case .weekday:  source = direction == "North" ? schedule.northWeekday  : schedule.southWeekday
            case .weekend:  source = direction == "North" ? schedule.northWeekend  : schedule.southWeekend
            case .modified: source = direction == "North" ? schedule.northModified : schedule.southModified
            }
            guard let times = source[String(leg.trainId)] else { continue }

            let isSecondLeg = legIndex > 0

            for (i, time) in times.enumerated() {
                guard let t = time, i < stopList.count else { continue }
                let sta = stopList[i]

                if isSecondLeg && sta == CaltrainService.transferStation { continue }

                let isTransfer = trip.isTransfer && legIndex == 0 && sta == CaltrainService.transferStation

                let role: StopRole
                if sta == origin && legIndex == 0 {
                    role = .origin
                } else if sta == destination {
                    role = .destination
                } else if isTransfer {
                    role = .transfer
                } else if goodTimes.inThePast(t) {
                    role = .past
                } else {
                    role = .future
                }

                let transferLabel: String? = isTransfer ?
                    "→ #\(trip.legs[1].trainId) \(CaltrainService.trainType(trip.legs[1].trainId))" : nil

                result.append(TripStop(time: t, station: sta, role: role, transferLabel: transferLabel))
            }
        }
        return result
    }

    private var currentLeg: Leg {
        guard trip.legs.count > 1 else { return trip.legs.first! }
        if goodTimes.inThePast(trip.legs[1].depart) {
            return trip.legs[1]
        }
        return trip.legs.first!
    }

    var title: String {
        let leg = currentLeg
        let dir = leg.trainId % 2 == 0 ? "SB" : "NB"
        return "\(dir) #\(leg.trainId) \(CaltrainService.trainType(leg.trainId))"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: AppStyle.fontOriginHero, weight: .bold))
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 0) {
                        let allStops = stops
                        ForEach(Array(allStops.enumerated()), id: \.offset) { index, stop in
                            StopRow(
                                time: stop.time,
                                station: stop.station,
                                role: stop.role,
                                isLast: index == allStops.count - 1,
                                transferLabel: stop.transferLabel
                            )
                        }
                    }
                    .frame(maxWidth: 400)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
