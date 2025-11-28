import SwiftUI

// Helper extension for Color initialization from Hex (required since system colors are not used)
extension SwiftUI.Color {
    // Defines an initializer to create a SwiftUI.Color from a hex string, supporting
    // RGB (6-digit) format.
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1) // Default to white if invalid for safe fallback
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1.0
        )
    }
}


enum Theme {
    // MARK: - Colors (Based on visual reference, unified light scheme)
    enum Color {
        // Brand Colors
        static let primaryAccent   = SwiftUI.Color(hex: "92A3FD") // Blue
        static let secondaryAccent = SwiftUI.Color(hex: "90CEFF") // Lighter Blue (Used in some gradients/effects in visuals)
        static let secondary       = SwiftUI.Color(hex: "C58BF2") // Purple
        
        // Neutrals & Surface Colors
        static let bg              = SwiftUI.Color(hex: "FFFFFF") // White background
        static let surface         = SwiftUI.Color(hex: "F7F8FC") // Light Gray/Off-white for card/surface (Inferred from Image A)
        static let text            = SwiftUI.Color(hex: "01050F") // Black
        static let subtle          = SwiftUI.Color(hex: "7B6A72") // Gray for secondary text
        static let danger          = SwiftUI.Color.red
        static let border          = SwiftUI.Color(hex: "F7F8F8").opacity(0.2) // Border Color (lightened for subtlety)
    }

    // MARK: - Spacing
    enum Spacing: CGFloat {
        case xxs = 4, xs = 8, s = 12, m = 16, l = 24, xl = 32
    }

    // MARK: - Radii
    enum Radius: CGFloat {
        case s = 8, m = 12, l = 16, xl = 22
    }

    // MARK: - Typography (Based on Poppins reference, assuming font is configured)
    enum Font {
        // NOTE: These use placeholders for custom fonts. The system will fall back if Poppins is not configured.
        static let h1     = SwiftUI.Font.custom("Poppins-Bold", size: 24)
        static let h2     = SwiftUI.Font.custom("Poppins-Bold", size: 22)
        static let h3     = SwiftUI.Font.custom("Poppins-Bold", size: 20)
        static let h4     = SwiftUI.Font.custom("Poppins-Bold", size: 18)
        
        static let title   = h2 // Use H2 (24pt semi-bold) for general screen titles
        static let body    = SwiftUI.Font.custom("Poppins-Regular", size: 16)
        static let label   = SwiftUI.Font.custom("Poppins-SemiBold", size: 12)
        static let value   = SwiftUI.Font.custom("Poppins-Regular", size: 16)
        static let button  = SwiftUI.Font.custom("Poppins-SemiBold", size: 16)
    }

    // MARK: - Elevation
    enum Elevation {
        static let card = Shadow(x: 0, y: 4, r: 12, o: 0.1)
        struct Shadow { let x: CGFloat, y: CGFloat, r: CGFloat, o: CGFloat }
    }
}
