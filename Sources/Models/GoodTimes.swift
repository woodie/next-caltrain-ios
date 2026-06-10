import Foundation

struct GoodTimes {
    let date: String
    let minutes: Int
    let dotw: Int

    init(date: Date = Date()) {
        let run = date.addingTimeInterval(-2 * 3600)
        let cal = Calendar.current
        let h = cal.component(.hour, from: run)
        let m = cal.component(.minute, from: run)
        self.minutes = (h + 2) * 60 + m
        self.dotw = cal.component(.weekday, from: run) - 1
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        self.date = fmt.string(from: run)
    }
}
