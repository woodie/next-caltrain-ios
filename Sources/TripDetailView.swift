import SwiftUI

enum StopRole {
    case past, origin, destination, transfer, future
}

struct StopRow: View {
    let time: Int
    let station: String
    let role: StopRole
    let isLast: Bool

    var dotColor: Color {
        switch role {
        case .past:        return .blue
        case .origin:      return .white
        case .destination: return .white
        case .transfer:    return .white
        case .future:      return .green
        }
    }

    var textColor: Color {
        switch role {
        case .past: return .blue
        default:    return .white
        }
    }

    var lineColor: Color {
        switch role {
        case .past: return .blue
        default:    return .green
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(GoodTimes.fullTime(time))
                .foregroundColor(textColor)
                .font(.body)
                .frame(width: 75, alignment: .trailing)

            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 2)
                        .offset(y: 10)
                }
                Circle()
                    .fill(dotColor)
                    .frame(width: 10, height: 10)
            }
            .frame(width: 10)

            Text(station)
                .foregroundColor(textColor)
                .font(.body)
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

                // Skip transfer station on second leg — already shown from first leg
                if isSecondLeg && sta == CaltrainService.transferStation { continue }

                let role: StopRole
                if sta == origin && legIndex == 0 {
                    role = .origin
                } else if sta == destination {
                    role = .destination
                } else if trip.isTransfer && sta == CaltrainService.transferStation {
                    role = .transfer
                } else if goodTimes.inThePast(t) {
                    role = .past
                } else {
                    role = .future
                }

                result.append(TripStop(time: t, station: sta, role: role))
            }
        }
        return result
    }

    // Show the leg the rider is currently on based on current time
    private var currentLeg: Leg {
        guard trip.legs.count > 1 else { return trip.legs.first! }
        let transferDepart = trip.legs[1].depart
        if goodTimes.inThePast(transferDepart) {
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
                    .font(.title3.bold())
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
                                isLast: index == allStops.count - 1
                            )
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
