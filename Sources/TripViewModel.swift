import SwiftUI
import Combine

class TripViewModel: ObservableObject {
    @Published var origin: String = "San Francisco"
    @Published var destination: String = "Palo Alto"
    @Published var scheduleType: ScheduleType = .weekday
    @Published var trips: [Trip] = []
    @Published var nextIndex: Int = 0
    @Published var offset: Int = 0
    @Published var goodTimes: GoodTimes = GoodTimes()

    let schedule: Schedule
    private let service: CaltrainService
    private var timer: AnyCancellable?

    private let kStopAM = "stopAM"
    private let kStopPM = "stopPM"

    var swapped: Bool {
        let today = CaltrainSchedule.optionIndex(
            date: goodTimes.date,
            dotw: goodTimes.dotw,
            specialDates: schedule.specialDates
        )
        return scheduleType != today
    }

    var serviceLabel: String {
        let trainId = trips.first?.legs.first?.trainId ?? 101
        return CaltrainService.trainType(trainId) + " Service"
    }

    var countdown: String? {
        guard offset < trips.count else { return nil }
        let c = goodTimes.countdown(trips[offset].depart)
        return c.isEmpty ? nil : c
    }

    var isDeparting: Bool {
        guard offset < trips.count else { return false }
        return goodTimes.departing(trips[offset].depart)
    }

    private var isFlipped: Bool {
        return Calendar.current.component(.hour, from: Date()) >= 12
    }

    var orderedStations: [String] {
        let direction = CaltrainService.direction(
            from: origin,
            to: destination,
            stops: schedule.southStops
        )
        return direction == "South" ? schedule.southStops : schedule.southStops.reversed()
    }

    init() {
        let sched = Schedule.load()
        self.schedule = sched
        self.service = CaltrainService(schedule: sched)

        let savedAM = UserDefaults.standard.object(forKey: "stopAM") as? Int
        let savedPM = UserDefaults.standard.object(forKey: "stopPM") as? Int
        let stations = sched.southStops
        let stopAM = savedAM.flatMap { $0 >= 0 && $0 < stations.count ? $0 : nil } ?? 15
        let stopPM = savedPM.flatMap { $0 >= 0 && $0 < stations.count ? $0 : nil } ?? 0

        let flipped = Calendar.current.component(.hour, from: Date()) >= 12
        if flipped {
            self.origin = stations[stopPM]
            self.destination = stations[stopAM]
        } else {
            self.origin = stations[stopAM]
            self.destination = stations[stopPM]
        }

        let gt = GoodTimes()
        self.goodTimes = gt
        self.scheduleType = CaltrainSchedule.optionIndex(
            date: gt.date,
            dotw: gt.dotw,
            specialDates: sched.specialDates
        )
        refresh()

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.goodTimes = GoodTimes()
                self.updateNextIndex()
            }
    }

    func refresh() {
        trips = service.routes(from: origin, to: destination, scheduleType: scheduleType)
        nextIndex = service.nextIndex(trips: trips, minutes: goodTimes.minutes)
        offset = nextIndex
        if offset >= trips.count { offset = max(0, trips.count - 1) }
    }

    func updateNextIndex() {
        nextIndex = service.nextIndex(trips: trips, minutes: goodTimes.minutes)
        // Only advance offset if time has moved past it (train departed)
        // Don't reset if user manually selected a past train
        if offset < nextIndex - 1 {
            offset = nextIndex
        }
        // Clamp to valid range
        if offset >= trips.count { offset = max(0, trips.count - 1) }
    }

    func offsetUp() {
        if offset > 0 { offset -= 1 }
    }

    func offsetDown() {
        if offset < trips.count - 1 { offset += 1 }
    }

    func swapStations() {
        let tmp = origin
        origin = destination
        destination = tmp
        saveStops()
        refresh()
    }

    func saveStops() {
        let stations = schedule.southStops
        let flipped = isFlipped
        let amStation = flipped ? destination : origin
        let pmStation = flipped ? origin : destination
        if let amIdx = stations.firstIndex(of: amStation) {
            UserDefaults.standard.set(amIdx, forKey: kStopAM)
        }
        if let pmIdx = stations.firstIndex(of: pmStation) {
            UserDefaults.standard.set(pmIdx, forKey: kStopPM)
        }
    }

    func cycleSchedule() {
        let next = (scheduleType.rawValue + 1) % 3
        scheduleType = ScheduleType(rawValue: next)!
        refresh()
    }
}
