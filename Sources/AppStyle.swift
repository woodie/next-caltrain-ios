import SwiftUI

// MARK: - Colors (named after legacy CSS variables)
extension Color {
    static let calPast    = Color(red: 0.0, green: 0.67, blue: 1.0)   // --msg-departed-color:  #0AF
    static let calArrive  = Color(red: 0.0, green: 1.0,  blue: 0.0)   // --msg-arriving-color:  #0F0
    static let calDepart  = Color(red: 1.0, green: 1.0,  blue: 0.0)   // --msg-departing-color: #FF0
    static let calSwapped = Color(white: 0.4)                          // --msg-selected-color:  #666
    static let iconCircleBackground = Color(white: 0.15)               // toolbar icon button background
}

enum AppStyle {
    // Home, List, Detail screens
    static let fontTrain: CGFloat = 18
    static let fontOrigin: CGFloat = 22
    static let fontBlurb: CGFloat  = 28

    // Toolbar icon buttons (back, swap, reset)
    static let fontStatusBar: CGFloat   = 18
    static let iconButtonSize: CGFloat  = 44
}
