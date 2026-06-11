import Foundation

struct GoodTimes {
    let date: String
    let minutes: Int
    let seconds: Int
    let dotw: Int

    // TEMPORARY DEBUG HACK: set to override "now" for testing (e.g. early morning).
    // Set to nil for normal behavior. Format: minutes since midnight, e.g. 330 = 5:30am.
    static var debugOverrideMinutes: Int? = nil

    init(date: Date = Date()) {
        let run = date.addingTimeInterval(-2 * 3600)
        let cal = Calendar.current

        if let overrideMinutes = GoodTimes.debugOverrideMinutes {
            self.minutes = overrideMinutes
            self.seconds = 0
            self.dotw = cal.component(.weekday, from: run) - 1
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            self.date = fmt.string(from: run)
            return
        }

        let h = cal.component(.hour, from: run)
        let m = cal.component(.minute, from: run)
        let s = cal.component(.second, from: run)
        self.minutes = (h + 2) * 60 + m
        self.seconds = s
        self.dotw = cal.component(.weekday, from: run) - 1
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        self.date = fmt.string(from: run)
    }

    // MARK: - Static formatting

    static func partTime(_ minutes: Int) -> (String, String) {
        var hrs = minutes / 60
        let min = minutes % 60
        let mer = (hrs > 11 && hrs < 24) ? "pm" : "am"
        if hrs > 12 { hrs -= 12 }
        if hrs > 12 { hrs -= 12 }
        if hrs < 1  { hrs = 12 }
        return (String(format: "%d:%02d", hrs, min), mer)
    }

    static func fullTime(_ minutes: Int) -> String {
        let (t, mer) = partTime(minutes)
        return t + mer
    }

    // MARK: - Instance methods

    func partTime() -> (String, String) { GoodTimes.partTime(minutes) }
    func fullTime() -> String { GoodTimes.fullTime(minutes) }

    func inThePast(_ target: Int) -> Bool {
        return target - minutes < 0
    }

    func departing(_ target: Int) -> Bool {
        return target == minutes
    }

    func countdown(_ target: Int) -> String {
        let diff = target - minutes - 1
        if diff < 0 {
            return ""
        } else if diff > 59 {
            return "in \(diff / 60) hr \(diff % 60) min"
        } else {
            return "in \(diff) min \(60 - seconds) sec"
        }
    }
}
