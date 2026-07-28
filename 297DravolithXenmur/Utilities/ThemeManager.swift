import SwiftUI
import Combine

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum AccentPreset: String, CaseIterable, Identifiable {
    case gold
    case ocean
    case forest
    case rose

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gold: return "Gold"
        case .ocean: return "Ocean"
        case .forest: return "Forest"
        case .rose: return "Rose"
        }
    }

    var primary: Color {
        switch self {
        case .gold: return Color(red: 0.988, green: 0.816, blue: 0.290)
        case .ocean: return Color(red: 0.25, green: 0.62, blue: 0.90)
        case .forest: return Color(red: 0.30, green: 0.72, blue: 0.48)
        case .rose: return Color(red: 0.92, green: 0.40, blue: 0.55)
        }
    }

    var accent: Color {
        switch self {
        case .gold: return Color(red: 0.992, green: 0.851, blue: 0.431)
        case .ocean: return Color(red: 0.45, green: 0.78, blue: 0.95)
        case .forest: return Color(red: 0.55, green: 0.85, blue: 0.62)
        case .rose: return Color(red: 0.96, green: 0.62, blue: 0.72)
        }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var appearance: AppAppearanceMode {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Keys.appearance) }
    }

    @Published var accent: AccentPreset {
        didSet { UserDefaults.standard.set(accent.rawValue, forKey: Keys.accent) }
    }

    private enum Keys {
        static let appearance = "clarity_appearance"
        static let accent = "clarity_accent"
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Keys.appearance),
           let mode = AppAppearanceMode(rawValue: raw) {
            appearance = mode
        } else {
            appearance = .dark
        }
        if let raw = UserDefaults.standard.string(forKey: Keys.accent),
           let preset = AccentPreset(rawValue: raw) {
            accent = preset
        } else {
            accent = .gold
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var primary: Color { accent.primary }
    var accentColor: Color { accent.accent }

    func background(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.192, green: 0.192, blue: 0.192)
            : Color(red: 0.96, green: 0.96, blue: 0.97)
    }

    func surface(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.29, green: 0.29, blue: 0.29)
            : Color.white
    }

    func textPrimary(for scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : Color(red: 0.12, green: 0.12, blue: 0.14)
    }

    func textSecondary(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.612, green: 0.639, blue: 0.686)
            : Color(red: 0.40, green: 0.42, blue: 0.46)
    }
}

enum ThemeColor {
    static var primary: Color { ThemeManager.shared.primary }
    static var accent: Color { ThemeManager.shared.accentColor }
}
