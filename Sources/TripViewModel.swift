import SwiftUI
import Combine

class TripViewModel: ObservableObject {
    @Published var origin: String = "San Francisco"
    @Published var destination: String = "Palo Alto"
    @Published var scheduleType: ScheduleType = .weekday
    @Published var trips: [Trip] = []
    @Published var nextIndex: Int = 0
    @Published var selectedTrip: Trip? = nil
    @Published var goodTimes: GoodTimes = GoodTimes()

    let schedule: Schedule
    private let service: CaltrainService
    private var timer: AnyCancellable?

    // UserDefaults keys
    private let kStopAM = "stopAM"
    private let kStopPM = "stopPM"
    private let defaultStopAM = 15  // Palo Alto in southStops
    private let defaultStopPM = 0   // San Francisco in southStops

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
        guard nextIndex < trips.count else { return nil }
        let c = goodTimes.countdown(trips[nextIndex].depart)
        return c.isEmpty ? nil : c
    }

    // AM/PM flip based on time of day
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

        // Load saved station indices
        let savedAM = UserDefaults.standard.object(forKey: "stopAM") as? Int
        let savedPM = UserDefaults.standard.object(forKey: "stopPM") as? Int
        let stations = sched.southStops
        let stopAM = savedAM.flatMap { $0 >= 0 && $0 < stations.count ? $0 : nil } ?? 15
        let stopPM = savedPM.flatMap { $0 >= 0 && $0 < stations.count ? $0 : nil } ?? 0

        // Set origin/destination based on time of day
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
        updateNextIndex()
    }

    func updateNextIndex() {
        nextIndex = service.nextIndex(trips: trips, minutes: goodTimes.minutes)
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
        // Figure out which is AM and which is PM based on current flip state
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
