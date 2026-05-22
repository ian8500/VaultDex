import SwiftUI

extension Color {
    static let vdBackground = Color(hex: 0x07080C)
    static let vdPanel = Color(hex: 0x10131A)
    static let vdPanelRaised = Color(hex: 0x181D27)
    static let vdStroke = Color(hex: 0x2A3140)
    static let vdGold = Color(hex: 0xEAC76A)
    static let vdEmerald = Color(hex: 0x58D7A4)
    static let vdCoral = Color(hex: 0xF47F72)
    static let vdViolet = Color(hex: 0x9A85FF)
    static let vdTextPrimary = Color(hex: 0xF7F2E8)
    static let vdTextSecondary = Color(hex: 0xA7B0C1)

    init(hex: UInt, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
