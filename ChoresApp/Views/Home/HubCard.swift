import SwiftUI

// MARK: - Card primitive

/// Shared shell for every Home Hub card. The rule: **no nested cards**.
/// This view paints the surface, applies the drop glow, and lends its palette
/// to the content. Content lays out as pure HStack/VStack — no inner rounded
/// rectangles, no inner glass — per the Beem-inspired spec.
struct HubCard<Content: View>: View {
    let palette: CardPalette
    let minHeight: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        palette: CardPalette,
        minHeight: CGFloat = 140,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.palette = palette
        self.minHeight = minHeight
        self.content = content
    }

    var body: some View {
        content()
            .padding(Spacing.xl)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(palette.surfaceGradient)
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
            )
            .shadow(color: palette.glow, radius: 22, y: 10)
    }
}

// MARK: - Card building blocks

/// Small uppercase label at the top of a card — sets the card's identity at a glance.
struct HubKicker: View {
    let text: String
    let palette: CardPalette
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.caption.weight(.bold))
            }
            Text(text.uppercased())
                .font(.caption.weight(.heavy))
                .tracking(0.8)
        }
        .foregroundStyle(palette.ink.opacity(0.7))
    }
}

/// Big card title.
struct HubTitle: View {
    let text: String
    let palette: CardPalette

    var body: some View {
        Text(text)
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundStyle(palette.ink)
            .multilineTextAlignment(.leading)
    }
}

/// Card subtitle / body copy.
struct HubSubtitle: View {
    let text: String
    let palette: CardPalette

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(palette.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Primary button

/// Minimum 56pt tall primary action inside a hub card.
struct HubPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let palette: CardPalette
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            Haptics.tap(.medium)
            action()
        } label: {
            HStack(spacing: Spacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, Spacing.xl)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(palette.primary.gradient, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5))
            .shadow(color: palette.primary.opacity(0.35), radius: 8, y: 4)
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .animation(Motion.responsive, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 50, perform: {}, onPressingChanged: { isPressed = $0 })
    }
}

/// Soft pill used inside a card for a secondary action (e.g. "Clear").
struct HubSecondaryPill: View {
    let title: String
    var systemImage: String? = nil
    let palette: CardPalette
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap(.soft)
            action()
        } label: {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .imageScale(.small)
                }
                Text(title)
                    .font(.footnote.weight(.semibold))
            }
            .foregroundStyle(palette.ink)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 8)
            .background(palette.tintedNeutral, in: Capsule())
            .overlay(Capsule().strokeBorder(palette.ink.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.94)
    }
}

// MARK: - Tappable drill-in area

/// Wraps card content so the whole surface (minus the primary button area) drills into a detail view.
struct HubTapArea<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var isPressed = false

    var body: some View {
        content()
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.99 : 1)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 50, perform: {}, onPressingChanged: { isPressed = $0 })
            .onTapGesture {
                Haptics.tap(.soft)
                action()
            }
            .animation(Motion.responsive, value: isPressed)
    }
}
