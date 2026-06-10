import SwiftUI

// MARK: - Colors (named after legacy CSS variables)
extension Color {
    static let calPast    = Color(red: 0.0, green: 0.67, blue: 1.0)   // --msg-departed-color:  #0AF
    static let calArrive  = Color(red: 0.0, green: 1.0,  blue: 0.0)   // --msg-arriving-color:  #0F0
    static let calDepart  = Color(red: 1.0, green: 1.0,  blue: 0.0)   // --msg-departing-color: #FF0
    static let calSwapped = Color(white: 0.4)                          // --msg-selected-color:  #666
}

// MARK: - Font sizes (named after legacy CSS classes)
enum AppStyle {
    // Hero screen (.hero-screen)
    static let fontOriginHero: CGFloat = 22   // .origin-hero / .destin-hero
    static let fontBlurbHero: CGFloat  = 28   // #blurb-hero (countdown/status)
    static let fontTrainHero: CGFloat  = 18   // .train-hero (#101)
    static let fontTimeHero: CGFloat   = 28   // .time-hero (5:10)
    static let fontMeridiemHero: CGFloat = 18 // .meridiem-hero (am/pm)
    static let fontTripType: CGFloat   = 18   // #trip-type (Local)

    // Grid screen (.grid-screen / TripRow)
    static let fontTrainNumber: CGFloat = 14  // .train-number
    static let fontTrainTime: CGFloat   = 27  // .train-time
    static let fontMeridiem: CGFloat    = 15  // .meridiem

    // Trip detail screen (.trip-screen / StopRow)
    static let fontStationTime: CGFloat = 16  // .station-time
    static let fontStationName: CGFloat = 16  // .station-name

    // Status bar (#statusbar)
    static let fontStatusBar: CGFloat   = 15  // #statusbar
}
