import SwiftUI

/// Drill-in for the "Who's ahead?" card. Reuses the full balance chart
/// (lifted from the old Household view) with a warmer framing.
struct BalanceDetailView: View {
    @Environment(AppStore.self) private var store

    @State private var window: Window = .sevenDays

    enum Window: String, CaseIterable, Identifiable {
        case sevenDays = "7 days"
        case thirtyDays = "30 days"
        case allTime = "All time"
        var id: String { rawValue }
    }

    private var interval: DateInterval {
        let now = Date.now
        switch window {
        case .sevenDays:
            return DateInterval(start: Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now, end: now)
        case .thirtyDays:
            return DateInterval(start: Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now, end: now)
        case .allTime:
            return DateInterval(start: .distantPast, end: now)
        }
    }

    private var data: [(member: Member, points: Int)] {
        store.householdPoints(in: interval)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(Copy.Hub.balanceTitle)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.ink)

                Picker("Window", selection: $window.animation(Motion.standard)) {
                    ForEach(Window.allCases) { w in
                        Text(w.rawValue).tag(w)
                    }
                }
                .pickerStyle(.segmented)

                BalanceChart(data: data)
                    .frame(height: 220)
                    .animation(Motion.hero, value: window)

                VStack(spacing: Spacing.sm) {
                    ForEach(data.sorted(by: { $0.points > $1.points }), id: \.member.id) { item in
                        memberRow(item.member, points: item.points)
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .scrollContentBackground(.hidden)
        .background(backdrop)
        .navigationTitle("Balance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var backdrop: some View {
        LinearGradient(
            colors: DayScene.current().backgroundStops(),
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func memberRow(_ m: Member, points: Int) -> some View {
        HStack(spacing: Spacing.md) {
            AvatarView(emoji: m.emoji, tint: m.tint, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(m.name).font(.body.weight(.semibold))
                    if m.id == store.currentMemberID {
                        Text("you")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .foregroundStyle(.white)
                            .background(Color.ink, in: Capsule())
                    }
                }
                Text(Copy.Common.karma(points))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(points)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.ink)
        }
        .padding(Spacing.md)
        .background(CardPalette.teal.tintedNeutral, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }
}
