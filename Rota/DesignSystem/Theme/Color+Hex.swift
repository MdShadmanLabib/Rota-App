import SwiftUI

extension Color {
    /// Create a color from a hex string such as "#4F46E5" or "4F46E5" (RGB)
    /// or "#4F46E580" (RGBA). Falls back to clear for malformed input.
    init(hex: String) {
        let raw = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&value)

        let r, g, b, a: Double
        switch raw.count {
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1
        case 8:
            r = Double((value & 0xFF000000) >> 24) / 255
            g = Double((value & 0x00FF0000) >> 16) / 255
            b = Double((value & 0x0000FF00) >> 8) / 255
            a = Double(value & 0x000000FF) / 255
        default:
            r = 0; g = 0; b = 0; a = 0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Returns a color that resolves differently for light and dark mode.
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
