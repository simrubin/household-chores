import SwiftUI

/// Spacing scale (4-pt grid). Use these everywhere instead of hard-coded numbers.
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let huge: CGFloat = 48
}

/// Corner radius scale tuned for Liquid Glass on iOS 26.
enum Radius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let pill: CGFloat = 999
}

/// Motion tokens. Every animated view must use one of these spring presets
/// so timing stays consistent across the app.
enum Motion {
    /// Default for structural transitions (~220ms smooth spring).
    static let standard: Animation = .smooth(duration: 0.22)
    /// Reaction to direct touch (buttons, chips, toggles).
    static let responsive: Animation = .snappy(duration: 0.18, extraBounce: 0.05)
    /// Celebration / accomplishment (completion checkmarks, confetti-ish pops).
    static let playful: Animation = .bouncy(duration: 0.42, extraBounce: 0.18)
    /// Emphasis for important state changes (mood reshuffle).
    static let emphasize: Animation = .spring(response: 0.42, dampingFraction: 0.76)
    /// Slow hero morphs (matched geometry between cards).
    static let hero: Animation = .spring(response: 0.55, dampingFraction: 0.82)
}

/// Canonical hex → Color parser.
extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}

/// Curated palette for categories/members. Stored as hex so models stay Codable.
enum Palette {
    static let swatches: [String] = [
        "#F97373", "#F7B267", "#F4D35E", "#9BC53D",
        "#4ECDC4", "#4D96FF", "#A06CD5", "#F58FBA",
        "#7D8597", "#2EC4B6", "#FF9F1C", "#E63946"
    ]
}
