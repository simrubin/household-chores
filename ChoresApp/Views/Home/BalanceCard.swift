import SwiftUI

/// Teal "Who's ahead?" card — live mini 3-bar chart + a one-line social verdict.
/// Drills into the full balance view on tap.
struct BalanceCard: View {
    /// Precomputed (member, points) tuples. Caller curates ordering and windowing.
    let data: [(member: Member, points: Int)]
    /// The current member's id, used to phrase the verdict.
    let currentMemberID: UUID?
    let onTap: () -> Void

    private let palette: CardPalette = .teal

    var body: some View {
        HubCard(palette: palette, minHeight: 180) {
            HubTapArea(action: onTap) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HubKicker(text: "BALANCE", palette: palette, symbol: "scalemass")
                    HubTitle(text: Copy.Hub.balanceTitle, palette: palette)
                    HubSubtitle(text: verdict, palette: palette)

                    MiniBalanceChart(data: displayData, palette: palette)
                        .frame(height: 72)
                        .padding(.top, Spacing.xs)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Copy.Hub.balanceTitle). \(verdict)")
        .accessibilityAddTraits(.isButton)
    }

    /// Top 3 by points — the card is a verdict, not a leaderboard.
    private var displayData: [(Member, Int)] {
        Array(data.sorted(by: { $0.points > $1.points }).prefix(3))
            .map { ($0.member, $0.points) }
    }

    private var verdict: String {
        guard data.count > 1 else { return Copy.Hub.balanceSubtitleSolo }

        let sorted = data.sorted(by: { $0.points > $1.points })
        guard let leader = sorted.first else { return Copy.Hub.balanceSubtitleTied }
        let runnerUp = sorted.dropFirst().first?.points ?? 0
        let delta = leader.points - runnerUp

        guard delta > 0 else { return Copy.Hub.balanceSubtitleTied }

        if leader.member.id == currentMemberID {
            let other = sorted.dropFirst().first?.member.name ?? "the crew"
            return Copy.Hub.balanceSubtitleAhead(firstName(other), delta)
        } else {
            return Copy.Hub.balanceSubtitleBehind(firstName(leader.member.name), delta)
        }
    }

    private func firstName(_ s: String) -> String {
        s.components(separatedBy: " ").first ?? s
    }
}

// MARK: - Mini chart

private struct MiniBalanceChart: View {
    let data: [(Member, Int)]
    let palette: CardPalette
    @State private var appeared = false

    private var maxPoints: Int { max(data.map(\.1).max() ?? 0, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.md) {
            ForEach(Array(data.enumerated()), id: \.element.0.id) { index, item in
                VStack(spacing: 6) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(palette.tintedNeutral)
                            .frame(width: 36, height: 52)
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(item.0.tint.gradient)
                            .frame(
                                width: 36,
                                height: appeared ? max(CGFloat(item.1) / CGFloat(maxPoints) * 52, item.1 > 0 ? 6 : 0) : 0
                            )
                            .animation(
                                .spring(response: 0.55, dampingFraction: 0.82).delay(Double(index) * 0.04),
                                value: appeared
                            )
                    }
                    HStack(spacing: 2) {
                        Text(item.0.emoji)
                            .font(.caption)
                        Text("\(item.1)")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .contentTransition(.numericText(value: Double(item.1)))
                            .foregroundStyle(palette.ink)
                    }
                }
            }
        }
        .onAppear { appeared = true }
    }
}
