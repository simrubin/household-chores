import SwiftUI

/// Coral "Add a chore" card — a single giant plus and warm copy.
/// Launches the 3-page wizard. On households with zero chores this card
/// floats to the top of the hub.
struct AddChoreCard: View {
    let onTap: () -> Void

    private let palette: CardPalette = .coral
    @State private var plusBounce = false

    var body: some View {
        HubCard(palette: palette, minHeight: 140) {
            HubTapArea(action: {
                plusBounce.toggle()
                onTap()
            }) {
                HStack(alignment: .center, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HubKicker(text: "NEW", palette: palette, symbol: "plus.circle.fill")
                        HubTitle(text: Copy.Hub.addChoreTitle, palette: palette)
                        HubSubtitle(text: Copy.Hub.addChoreSubtitle, palette: palette)
                    }
                    Spacer(minLength: 0)
                    plusOrb
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Copy.Hub.addChoreTitle). \(Copy.Hub.addChoreSubtitle)")
        .accessibilityAddTraits(.isButton)
    }

    private var plusOrb: some View {
        ZStack {
            Circle()
                .fill(palette.primary.gradient)
                .frame(width: 74, height: 74)
                .shadow(color: palette.glow, radius: 16, y: 6)
            Image(systemName: "plus")
                .font(.system(size: 32, weight: .heavy))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, value: plusBounce)
        }
    }
}
