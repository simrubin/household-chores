import SwiftUI

/// Indigo "Not feeling it?" card — promotes mood from a pill row to a hero surface.
/// On tap: opens the full-screen MoodSheet via matchedGeometry namespace.
struct MoodCard: View {
    let mood: MoodPreset
    let avoidCategoryName: String?
    let namespace: Namespace.ID
    let onTapCard: () -> Void
    let onClear: () -> Void

    private let palette: CardPalette = .indigo

    var body: some View {
        HubCard(palette: palette, minHeight: 160) {
            if mood.isActive {
                activeContent
            } else {
                restingContent
            }
        }
        .matchedGeometryEffect(id: "mood-card-surface", in: namespace, isSource: true)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(voLabel)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - States

    private var restingContent: some View {
        HubTapArea(action: onTapCard) {
            HStack(alignment: .top, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HubKicker(text: "MOOD", palette: palette, symbol: "wand.and.stars")
                    HubTitle(text: Copy.Hub.moodTitle, palette: palette)
                    HubSubtitle(text: Copy.Hub.moodSubtitle, palette: palette)
                }
                Spacer(minLength: 0)
                moodOrb(symbol: "sparkles", palette: palette)
            }
        }
    }

    private var activeContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HubTapArea(action: onTapCard) {
                HStack(alignment: .top, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HubKicker(text: "ACTIVE VIBE", palette: palette, symbol: "wand.and.stars")
                        HubTitle(text: activeLabel, palette: palette)
                        HubSubtitle(text: activeBlurb, palette: palette)
                    }
                    Spacer(minLength: 0)
                    moodOrb(symbol: mood.symbolName, palette: palette)
                        .symbolEffect(.bounce, value: mood.id)
                }
            }

            HubSecondaryPill(
                title: Copy.Hub.moodClear,
                systemImage: "xmark.circle.fill",
                palette: palette,
                action: onClear
            )
        }
    }

    private func moodOrb(symbol: String, palette: CardPalette) -> some View {
        ZStack {
            Circle()
                .fill(palette.primary.gradient)
                .frame(width: 68, height: 68)
                .shadow(color: palette.glow, radius: 14, y: 6)
            Image(systemName: symbol)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Copy helpers

    private var activeLabel: String {
        switch mood {
        case .none: return Copy.Hub.moodTitle
        case .lowEnergy: return Copy.Mood.tiredTitle
        case .quickOnly: return Copy.Mood.rushingTitle
        case .avoid: return Copy.Mood.skipCategory(avoidCategoryName ?? "category")
        }
    }

    private var activeBlurb: String {
        switch mood {
        case .none: return Copy.Hub.moodSubtitle
        case .lowEnergy: return Copy.Mood.tiredSubtitle
        case .quickOnly: return Copy.Mood.rushingSubtitle
        case .avoid: return "We'll leave those for later."
        }
    }

    private var voLabel: String {
        mood.isActive
            ? "Mood: \(activeLabel). Tap to change."
            : "\(Copy.Hub.moodTitle) \(Copy.Hub.moodSubtitle)"
    }
}
