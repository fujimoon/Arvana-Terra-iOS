import SwiftUI

// MARK: - App Configuration
struct AppConfig {
    static let apiBaseURL = "http://localhost:3001/api/v1"
    static let wsURL = "ws://localhost:3001"
    static let appName = "Arvana Terra"
    static let appVersion = "1.0.0"
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    static let primaryNavy = Color(hex: "#1B3A6B")
    static let secondaryBlue = Color(hex: "#2E5EAA")
    static let accentBlue = Color(hex: "#4A90D9")
    static let textDark = Color(hex: "#1A1A2E")
    static let textGray = Color(hex: "#6B7280")
    static let successGreen = Color(hex: "#059669")
    static let warningOrange = Color(hex: "#D97706")
    static let errorRed = Color(hex: "#DC2626")
    static let backgroundGray = Color(hex: "#FAFAFA")
    static let surfaceWhite = Color(hex: "#FFFFFF")
    static let borderGray = Color(hex: "#E5E7EB")
}
