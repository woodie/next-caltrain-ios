import SwiftUI

struct TimeWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct TripRow: View {
    let trip: Trip
    let isNext: Bool
    let isPast: Bool
    let isDeparting: Bool
    let swapped: Bool
    var timeColumnWidth: CGFloat = 0

    var textColor: Color {
        if isPast      { return .calPast }
        if swapped     { return .calPast }
        if isDeparting { return .calDepart }
        return .white
    }

    var borderColor: Color {
        if isNext && isDeparting { return .calDepart }
        if isNext && isPast      { return .calSwapped }
        if isNext && swapped     { return .calSwapped }
        if isNext                { return .calArrive }
        return .clear
    }

    func timeView(_ minutes: Int) -> some View {
        let (t, mer) = GoodTimes.partTime(minutes)
        return HStack(alignment: .lastTextBaseline, spacing: 1) {
            Text(t)
                .font(.system(size: AppStyle.fontTrainTime, weight: .regular))
            Text(mer)
                .font(.system(size: AppStyle.fontMeridiem, weight: .regular))
        }
        .foregroundColor(textColor)
        .fixedSize(horizontal: true, vertical: false)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: TimeWidthKey.self, value: geo.size.width)
            }
        )
        .frame(width: timeColumnWidth > 0 ? timeColumnWidth : nil, alignment: .center)
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 24) {
            Text("#\(trip.legs.first!.trainId)")
                .foregroundColor(textColor)
                .font(.system(size: AppStyle.fontTrainNumber, weight: .regular))
                .frame(width: 50, alignment: .leading)
            timeView(trip.depart)
            timeView(trip.arrive)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 2)
                .padding(.horizontal, 6)
        )
    }
}
