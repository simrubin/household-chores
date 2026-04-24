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
    static let standard: Animation = .smooth(duration: 0.22)
    static let responsive: Animation = .snappy(duration: 0.18, extraBounce: 0.05)
    static let playful: Animation = .bouncy(duration: 0.42, extraBounce: 0.18)
    static let emphasize: Animation = .spring(response: 0.42, dampingFraction: 0.76)
    static let hero: Animation = .spring(response: 0.55, dampingFraction: 0.82)
}

// MARK: - Color helpers

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

    /// Build a Color from OKLCH coordinates. Perceptually-uniform hue control
    /// (Björn Ottosson's OKLab → linear sRGB → sRGB gamma).
    /// - Parameters:
    ///   - L: lightness in [0, 1]
    ///   - C: chroma (≈0 is gray; typical range 0–0.37)
    ///   - H: hue in degrees (0 = red, 90 = yellow, 180 = cyan-ish, 270 = blue)
    ///   - opacity: 0–1
    init(oklch L: Double, _ C: Double, _ H: Double, opacity: Double = 1.0) {
        let hRad = H * .pi / 180.0
        let a = C * cos(hRad)
        let b = C * sin(hRad)

        let lp = L + 0.3963377774 * a + 0.2158037573 * b
        let mp = L - 0.1055613458 * a - 0.0638541728 * b
        let sp = L - 0.0894841775 * a - 1.2914855480 * b

        let l3 = lp * lp * lp
        let m3 = mp * mp * mp
        let s3 = sp * sp * sp

        let rLin = 4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3
        let gLin = -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3
        let bLin = -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3

        func gamma(_ v: Double) -> Double {
            let c = Swift.min(Swift.max(v, 0), 1)
            return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1.0 / 2.4) - 0.055
        }

        self = Color(
            red: gamma(rLin),
            green: gamma(gLin),
            blue: gamma(bLin),
            opacity: opacity
        )
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

// MARK: - Scene (morning / day / evening / night)

/// The app tilts its hub background and card priority toward the time of day.
/// "A 25-year-old housemate checking their phone in the kitchen at 7pm to see
/// if bin night is their problem." — we stay light + warm, just darker after dusk.
enum DayScene {
    case morning, day, evening, night

    static func current(_ now: Date = .now, calendar: Calendar = .current) -> DayScene {
        let hour = calendar.component(.hour, from: now)
        switch hour {
        case 5..<11: return .morning
        case 11..<17: return .day
        case 17..<22: return .evening
        default: return .night
        }
    }

    /// A three-stop background gradient tinted for the scene. Always light.
    /// Evening nudges warmer + a touch darker — never full dark mode.
    func backgroundStops() -> [Color] {
        switch self {
        case .morning:
            return [
                Color(oklch: 0.98, 0.02, 80),
                Color(oklch: 0.96, 0.04, 60),
                Color(oklch: 0.97, 0.02, 40)
            ]
        case .day:
            return [
                Color(oklch: 0.98, 0.01, 230),
                Color(oklch: 0.97, 0.02, 220),
                Color(oklch: 0.98, 0.01, 210)
            ]
        case .evening:
            return [
                Color(oklch: 0.94, 0.05, 40),
                Color(oklch: 0.90, 0.07, 25),
                Color(oklch: 0.86, 0.08, 300)
            ]
        case .night:
            return [
                Color(oklch: 0.86, 0.06, 280),
                Color(oklch: 0.82, 0.08, 270),
                Color(oklch: 0.78, 0.08, 260)
            ]
        }
    }

    /// One-word mood label for the hub header greeting, per tone guide.
    var greetingTime: String {
        switch self {
        case .morning: "Morning"
        case .day: "Afternoon"
        case .evening: "Evening"
        case .night: "Late one"
        }
    }

    /// True after 19:00 local — triggers the "evening shift" reordering of cards.
    var isEveningShift: Bool { self == .evening || self == .night }
}
