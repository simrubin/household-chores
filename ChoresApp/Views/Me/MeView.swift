import SwiftUI

/// Right tab. Profile + karma history + entry points to the Chore library
/// (was "Jobs") and The crew (was "Household").
struct MeView: View {
    @Environment(AppStore.self) private var store

    @State private var showEdit = false

    private var me: Member? { store.currentMember }

    private var weekKarma: Int {
        guard let id = me?.id else { return 0 }
        let now = Date.now
        let start = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        return store.points(for: id, in: DateInterval(start: start, end: now))
    }

    private var allTimeKarma: Int {
        guard let id = me?.id else { return 0 }
        return store.points(for: id, in: DateInterval(start: .distantPast, end: .now))
    }

    private var completedCount: Int {
        guard let id = me?.id else { return 0 }
        return store.occurrences.filter { $0.completedByID == id }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    profileCard
                    karmaCard
                    navCard

                    Spacer(minLength: Spacing.huge)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
            }
            .scrollContentBackground(.hidden)
            .background(backdrop.ignoresSafeArea())
            .navigationTitle(Copy.Me.navTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEdit) {
                if let me {
                    MemberEditorView(existing: me)
                }
            }
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: DayScene.current().backgroundStops(),
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: - Profile card

    private var profileCard: some View {
        HubCard(palette: .sage, minHeight: 140) {
            HStack(spacing: Spacing.lg) {
                if let m = me {
                    AvatarView(emoji: m.emoji, tint: m.tint, size: 68)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(me?.name ?? "You")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(CardPalette.sage.ink)
                    Text(Copy.Me.signedInAs)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CardPalette.sage.inkSoft)
                }
                Spacer()
                HubSecondaryPill(
                    title: Copy.Me.editProfile,
                    systemImage: "pencil",
                    palette: .sage,
                    action: { showEdit = true }
                )
            }
        }
    }

    // MARK: - Karma card

    private var karmaCard: some View {
        HubCard(palette: .teal, minHeight: 160) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HubKicker(text: Copy.Me.karma, palette: .teal, symbol: "star.fill")

                HStack(alignment: .lastTextBaseline, spacing: Spacing.xl) {
                    karmaStat(label: Copy.Me.thisWeek, value: weekKarma, emphasize: true)
                    karmaStat(label: Copy.Me.allTime, value: allTimeKarma, emphasize: false)
                    karmaStat(label: "Done", value: completedCount, emphasize: false)
                }
            }
        }
    }

    private func karmaStat(label: String, value: Int, emphasize: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.heavy))
                .tracking(0.6)
                .foregroundStyle(CardPalette.teal.inkSoft)
            Text("\(value)")
                .font(.system(size: emphasize ? 44 : 28, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
                .foregroundStyle(CardPalette.teal.ink)
        }
    }

    // MARK: - Nav card

    private var navCard: some View {
        VStack(spacing: Spacing.md) {
            NavigationLink {
                JobsView()
            } label: {
                navRow(
                    title: Copy.Me.choreLibrary,
                    subtitle: Copy.Me.choreLibrarySubtitle,
                    systemImage: "tray.full.fill",
                    palette: .amber
                )
            }
            .buttonStyle(.plain)
            .pressable(scale: 0.99)

            NavigationLink {
                HouseholdView()
            } label: {
                navRow(
                    title: Copy.Me.household,
                    subtitle: Copy.Me.householdSubtitle,
                    systemImage: "house.fill",
                    palette: .indigo
                )
            }
            .buttonStyle(.plain)
            .pressable(scale: 0.99)
        }
    }

    private func navRow(title: String, subtitle: String, systemImage: String, palette: CardPalette) -> some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(palette.primary.gradient)
                    .frame(width: 46, height: 46)
                Image(systemName: systemImage)
                    .foregroundStyle(.white)
                    .font(.headline)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.ink.opacity(0.35))
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .strokeBorder(Color.ink.opacity(0.06), lineWidth: 0.5)
        )
    }
}
