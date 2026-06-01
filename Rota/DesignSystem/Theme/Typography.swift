import SwiftUI

/// Typography scale built on SF Pro with a clear hierarchy.
extension Font {
    enum Rota {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 19, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let bodyMedium = Font.system(size: 16, weight: .medium)
        static let callout = Font.system(size: 15, weight: .regular)
        static let subheadline = Font.system(size: 14, weight: .medium)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .medium)
        static let caption2 = Font.system(size: 11, weight: .semibold)
        /// Big numeric display for stats and timers.
        static let mono = Font.system(size: 40, weight: .bold, design: .rounded).monospacedDigit()
    }
}

extension Text {
    /// Apply a primary/secondary text color token quickly.
    func primaryText() -> Text { self.foregroundColor(Theme.Colors.textPrimary) }
    func secondaryText() -> Text { self.foregroundColor(Theme.Colors.textSecondary) }
}
