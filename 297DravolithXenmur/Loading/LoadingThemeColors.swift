import SwiftUI

/// Color tokens used by Loading UI (copied syndicate screens).
extension Color {
    static var appBackground: Color { ThemeManager.shared.background(for: .dark) }
    static var appSurface: Color { ThemeManager.shared.surface(for: .dark) }
    static var appPrimary: Color { ThemeManager.shared.primary }
    static var appAccent: Color { ThemeManager.shared.accentColor }
    static var appTextPrimary: Color { ThemeManager.shared.textPrimary(for: .dark) }
    static var appTextSecondary: Color { ThemeManager.shared.textSecondary(for: .dark) }
}
