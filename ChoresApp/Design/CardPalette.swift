import SwiftUI

/// Warm-grey card palette. Every case maps to a different lightness step
/// within the Eggshell→Chalk scale, keeping cards visually distinct without
/// introducing chroma. Low-chroma OKLCH (C ≤ 0.012, H 75–80) ensures all
/// surfaces read as refined warm grey.
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
    /// Onboarding — softest warm grey, very inviting
    case petal

    // MARK: Core lightness coordinates (all warm grey, varying L only)

    /// Base (L, C, H). C is intentionally ≤ 0.012 so every card reads as
    /// a warm grey surface — never chromatic.
    var base: (L: Double, C: Double, H: Double) {
        switch self {
        case .amber:  return (0.88, 0.011, 76)   // powder-warm — primary CTA card
        case .indigo: return (0.91, 0.008, 75)   // light warm grey
        case .teal:   return (0.86, 0.010, 75)   // chalk-warm — slightly deeper
        case .coral:  return (0.93, 0.007, 78)   // very light warm grey
        case .sky:    return (0.95, 0.005, 75)   // near-eggshell
        case .sage:   return (0.89, 0.011, 78)   // warm medium grey
        case .petal:  return (0.96, 0.004, 75)   // lightest — close to eggshell
        }
    }

    // MARK: Derived roles

    /// Card surface — the dominant fill.
    var surface: Color {
        let c = base
        return Color(oklch: c.L, c.C, c.H)
    }

    /// Dark charcoal used for primary CTA button backgrounds (white text on top).
    var primary: Color {
        return Color(oklch: 0.22, 0.010, 75)
    }

    /// Near-black warm ink for headings and primary labels.
    var ink: Color {
        return Color(oklch: 0.16, 0.008, 75)
    }

    /// Warm Gravel-equivalent ink for captions and secondary copy.
    var inkSoft: Color {
        return Color(oklch: 0.50, 0.016, 76)
    }

    /// Near-eggshell used for chip / mini-surface backgrounds inside cards.
    var tintedNeutral: Color {
        return Color(oklch: 0.97, 0.006, 76)
    }

    /// Very subtle warm grey shadow for cards — never colored.
    var glow: Color {
        return Color(oklch: 0.55, 0.008, 75, opacity: 0.06)
    }

    /// Two-stop gradient: slightly lighter top-leading → base bottom-trailing.
    var surfaceGradient: LinearGradient {
        let c = base
        return LinearGradient(
            colors: [
                Color(oklch: min(c.L + 0.025, 0.98), 0.005, 78),
                Color(oklch: c.L, 0.010, 75)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Mood variants (used by MoodSheet and MoodCard)

    /// Maps a MoodPreset to a palette variant — all warm grey, just varying depth.
    static func palette(for preset: MoodPreset) -> CardPalette {
        switch preset {
        case .none: return .teal
        case .lowEnergy: return .indigo
        case .quickOnly: return .amber
        case .avoid: return .coral
        }
    }
}

// MARK: - App-wide semantic neutrals

/// Warm grey semantic colors. Used directly throughout all views.
extension Color {
    /// Near-black warm ink — Obsidian. Primary text, icon fills.
    static let ink = Color(oklch: 0.16, 0.008, 75)
    /// Warm Gravel — secondary body text, nav items, subheadings.
    static let inkSoft = Color(oklch: 0.50, 0.016, 76)
    /// Eggshell — primary surface background for rows, cards.
    static let surface = Color(hex: "#fdfcfc")
}
