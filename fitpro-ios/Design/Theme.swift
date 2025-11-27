import SwiftUI

enum Theme {
    enum Color {
        static let bg        = SwiftUI.Color(.systemBackground)
        static let surface   = SwiftUI.Color(.secondarySystemBackground)
        static let text      = SwiftUI.Color.primary
        static let subtle    = SwiftUI.Color.secondary
        static let accent    = SwiftUI.Color.accentColor   // swap later to your brand
        static let danger    = SwiftUI.Color.red
        static let border    = SwiftUI.Color(.separator)
    }

    enum Spacing: CGFloat {
        case xs = 6, s = 10, m = 14, l = 20, xl = 28
    }

    enum Radius: CGFloat {
        case s = 8, m = 14, l = 20
    }

    enum Font {
        static let title   = SwiftUI.Font.title2.weight(.semibold)
        static let body    = SwiftUI.Font.body
        static let label   = SwiftUI.Font.subheadline
        static let value   = SwiftUI.Font.body
        static let button  = SwiftUI.Font.headline
    }

    // layout tokens that are handy later
    enum Elevation {
        static let card = Shadow(x: 0, y: 2, r: 8, o: 0.15)
        struct Shadow { let x: CGFloat, y: CGFloat, r: CGFloat, o: CGFloat }
    }
}
