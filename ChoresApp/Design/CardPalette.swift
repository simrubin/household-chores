import SwiftUI

/// "Committed color strategy" tokens for the Home Hub. Each hue carries
/// 30–60% of its card surface. Values are OKLCH (perceptual), emitted to sRGB
/// by `Color(oklch:_:_:)` in `Tokens.swift`.
enum CardPalette: String, CaseIterable, Hashable, Sendable {
    /// Do it now
    case amber
    /// Not feeling it
    case indigo
    /// Who's ahead
    case teal
    /// Add a chore
    case coral
    /// Invite the crew
    case sky
    /// Heading out (contextual)
    case sage

    // MARK: Core hue coordinates

    /// Base (L, C, H) used by the surface fill.
    var base: (L: Double, C: Double, H: Double) {
        switch self {
        case .amber:  return (0.80, 0.14, 75)
        case .indigo: return (0.62, 0.13, 275)
        case .teal:   return (0.75, 0.11, 190)
        case .coral:  return (0.75, 0.15, 25)
        case .sky:    return (0.80, 0.10, 235)
        case .sage:   return (0.80, 0.08, 140)
        }
    }

    // MARK: Derived roles

    /// Card surface — the dominant 30–60% block of color.
    var surface: Color {
        let c = base
        return Color(oklch: c.L, c.C * 0.9, c.H)
    }

    /// Slightly deeper, used for the primary button inside the card.
    var primary: Color {
        let c = base
        return Color(oklch: c.L * 0.78, c.C * 1.05, c.H)
    }

    /// Readable ink on top of `surface`. Same hue, very dark, tiny chroma.
    var ink: Color {
        let c = base
        return Color(oklch: 0.22, 0.02, c.H)
    }

    /// Secondary ink — for captions / supporting copy.
    var inkSoft: Color {
        let c = base
        return Color(oklch: 0.40, 0.02, c.H)
    }

    /// Neutral tinted toward the card hue (C 0.008) — used for inside-card
    /// mini-surfaces (e.g. a chip that isn't itself a card).
    var tintedNeutral: Color {
        let c = base
        return Color(oklch: 0.95, 0.008, c.H)
    }

    /// Glow color for shadows under the card.
    var glow: Color {
        let c = base
        return Color(oklch: c.L * 0.7, c.C, c.H, opacity: 0.35)
    }

    /// A two-stop vertical gradient using the surface tone — subtle, not flashy.
    var surfaceGradient: LinearGradient {
        let c = base
        return LinearGradient(
            colors: [
                Color(oklch: min(c.L + 0.04, 0.98), c.C * 0.85, c.H),
                Color(oklch: c.L, c.C * 0.95, c.H)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Mood variants (used by MoodSheet and MoodCard)

    /// Maps a MoodPreset to a palette for color-drenched treatments.
    static func palette(for preset: MoodPreset) -> CardPalette {
        switch preset {
        case .none: return .teal
        case .lowEnergy: return .indigo
        case .quickOnly: return .amber
        case .avoid: return .coral
        }
    }
}

// MARK: - App-wide neutrals (tinted grays)

/// Warm ink that replaces `.primary` for headings inside hub surfaces.
/// Slightly bluish to stay legible on all card hues.
extension Color {
    static let ink = Color(oklch: 0.20, 0.01, 265)
    static let inkSoft = Color(oklch: 0.45, 0.01, 265)
    static let surface = Color(oklch: 0.985, 0.003, 80)
}
