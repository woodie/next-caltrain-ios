import SwiftUI

extension Color {
    static let calPast    = Color(red: 0.0, green: 0.67, blue: 1.0)   // #0AF
    static let calArrive  = Color(red: 0.0, green: 1.0,  blue: 0.0)   // #0F0
    static let calDepart  = Color(red: 1.0, green: 1.0,  blue: 0.0)   // #FF0
    static let calSwapped = Color(white: 0.4)                          // #666
}

struct TripRow: View {
    let trip: Trip
    let isNext: Bool
    let isPast: Bool
    let isDeparting: Bool
    let swapped: Bool

    var textColor: Color {
        if isPast      { return .calPast }
        if swapped     { return .calPast }
        if isDeparting { return .calDepart }
        return .white
    }

    var borderColor: Color {
        if isNext && isDeparting { return .calDepart }
        if isNext && swapped     { return .calSwapped }
        if isNext                { return .calArrive }
        return .clear
    }

    func timeView(_ minutes: Int) -> some View {
        let (t, mer) = GoodTimes.partTime(minutes)
        return HStack(alignment: .lastTextBaseline, spacing: 1) {
            Text(t)
                .font(.system(size: 27, weight: .regular))
            Text(mer)
                .font(.system(size: 15, weight: .regular))
        }
        .foregroundColor(textColor)
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("#\(trip.legs.first!.trainId)")
                .foregroundColor(textColor)
                .font(.system(size: 14, weight: .regular))
                .frame(width: 45, alignment: .leading)
            Spacer()
            timeView(trip.depart)
            Spacer()
            timeView(trip.arrive)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 2)
                .padding(.horizontal, 6)
        )
    }
}
