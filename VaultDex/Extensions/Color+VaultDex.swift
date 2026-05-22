import SwiftUI
import UIKit

extension Color {
    static let vdBackground = Color(light: 0xFFF7D7, dark: 0x07111F)
    static let vdPanel = Color(light: 0xFFFDF4, dark: 0x101B2E)
    static let vdPanelRaised = Color(light: 0xFFFFFF, dark: 0x18263D)
    static let vdStroke = Color(light: 0xE5C764, dark: 0x344867)
    static let vdGold = Color(hex: 0xFFD84D)
    static let vdGoldDeep = Color(hex: 0xF1A900)
    static let vdSky = Color(hex: 0x6BC9FF)
    static let vdLeaf = Color(hex: 0x63D889)
    static let vdEmerald = Color(hex: 0x63D889)
    static let vdCoral = Color(hex: 0xFF7A6E)
    static let vdViolet = Color(hex: 0xA68CFF)
    static let vdNavy = Color(hex: 0x07111F)
    static let vdMidnight = Color(hex: 0x0E1A2D)
    static let vdCream = Color(hex: 0xFFF7D7)
    static let vdTextPrimary = Color(light: 0x171B24, dark: 0xFFF9EA)
    static let vdTextSecondary = Color(light: 0x5E6470, dark: 0xB9C7DC)

    init(hex: UInt, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    init(light: UInt, dark: UInt) {
        self.init(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            let red = CGFloat((hex >> 16) & 0xFF) / 255
            let green = CGFloat((hex >> 8) & 0xFF) / 255
            let blue = CGFloat(hex & 0xFF) / 255
            return UIColor(red: red, green: green, blue: blue, alpha: 1)
        })
    }
}
