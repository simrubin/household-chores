import Combine
import SwiftUI

/// The flagship screen. Replaces TodayView as the app's front door.
/// A Beem-inspired grid of compact CTA tiles, each carrying its own color world.
/// Tap any tile to drill in, open a sheet, or hop into the primary flow.
struct HomeHubView: View {
    @Environment(AppStore.self) private var store

    @State private var scene: DayScene = .current()
    @State private var path = NavigationPath()
    @State private var showMood = false
    @State private var showAddChore = false
    @State private var showInvite = false
    @State private var completionPayload: CompletionPayload?
    @Namespace private var moodNamespace

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: Spacing.md),
        GridItem(.flexible(), spacing: Spacing.md)
    ]

    private var currentMemberID: UUID? { store.currentMember?.id }

    private var allToday: [Occurrence] {
        store.todaysOccurrences(for: currentMemberID)
    }

    private var visibleToday: [Occurrence] {
        MoodSolver.apply(to: allToday, mood: mood)
    }

    private var mood: MoodPreset {
        guard let id = currentMemberID else { return .none }
        return store.mood(for: id)
    }

    private var avoidCategoryName: String? {
        if case .avoid(let id) = mood {
            return store.category(id)?.name
        }
        return nil
    }

    private var balanceData: [(member: Member, points: Int)] {
        let cal = Calendar.current
        let now = Date.now
        let start = cal.date(byAdding: .day, value: -7, to: now) ?? now
        return store.householdPoints(in: DateInterval(start: start, end: now))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    header
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.sm)

                    VStack(spacing: Spacing.md) {
                        LazyVGrid(columns: columns, spacing: Spacing.md) {
                            ForEach(gridTiles, id: \.self) { kind in
                                tile(for: kind)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.94)).combined(with: .move(edge: .bottom)),
                                        removal: .opacity.combined(with: .scale(scale: 0.96))
                                    ))
                            }
                        }

                        if fullWidthTiles.contains(.invite) {
                            inviteTile
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.huge)
                    .animation(Motion.emphasize, value: mood)
                    .animation(Motion.hero, value: orderedTiles)
                }
            }
            .scrollContentBackground(.hidden)
            .background(backdrop.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: HubRoute.self) { route in
                switch route {
                case .doItNow:
                    DoItNowDetailView(completionPayload: $completionPayload)
                case .balance:
                    BalanceDetailView()
                }
            }
            .sheet(isPresented: $showMood) {
                MoodSheet(namespace: moodNamespace)
            }
            .sheet(isPresented: $showAddChore) {
                AddChoreWizardView()
            }
            .sheet(isPresented: $showInvite) {
                InviteCodeSheet()
            }
            .overlay {
                if let payload = completionPayload {
                    CompletionMoment(payload: payload) {
                        completionPayload = nil
                    }
                    .transition(.opacity)
                    .zIndex(1000)
                }
            }
            .animation(Motion.standard, value: completionPayload)
            .onAppear { refreshScene() }
            .onReceive(Timer.publish(every: 120, on: .main, in: .common).autoconnect()) { _ in
                refreshScene()
            }
        }
    }

    private func refreshScene() {
        withAnimation(Motion.hero) {
            scene = .current()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(Color.ink)
                Text(homeSummary)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.inkSoft)
            }
            Spacer()
            todayKarmaPill
        }
    }

    private var homeSummary: String {
        let name = store.household.name.isEmpty ? "Home" : store.household.name
        let n = visibleToday.count
        if n == 0 { return name }
        return "\(name) • \(n) on the go"
    }

    private var greeting: String {
        let name = store.currentMember?.name.components(separatedBy: " ").first ?? "you"
        return "\(scene.greetingTime), \(name)"
    }

    private var todayKarmaPill: some View {
        let pts = todaysKarma
        return HStack(spacing: 4) {
            Image(systemName: "star.fill")
            Text("\(pts)")
                .contentTransition(.numericText(value: Double(pts)))
                .monospacedDigit()
        }
        .font(.subheadline.weight(.bold))
        .foregroundStyle(Color.ink)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 8)
        .background(Color.ink.opacity(0.08), in: Capsule())
        .accessibilityLabel("\(pts) karma today")
    }

    private var todaysKarma: Int {
        guard let id = currentMemberID else { return 0 }
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? .now
        return store.points(for: id, in: DateInterval(start: start, end: end))
    }

    // MARK: - Tiles

    enum TileKind: Hashable {
        case doItNow, mood, balance, addChore, invite
    }

    /// All tiles in their intended order — used for animation keying.
    private var orderedTiles: [TileKind] {
        gridTiles + fullWidthTiles
    }

    /// Tiles that sit inside the 2-column grid.
    private var gridTiles: [TileKind] {
        var tiles: [TileKind] = [.doItNow, .mood, .balance, .addChore]

        // Evening shift: surface balance alongside "do it now" earlier in the
        // grid so bin-night / chore chases come first at 7pm.
        if scene.isEveningShift, let b = tiles.firstIndex(of: .balance) {
            tiles.remove(at: b)
            tiles.insert(.balance, at: 1)
        }

        // Empty-state: if no chores exist at all, float "new chore" to the top.
        if store.jobs.filter({ !$0.archived }).isEmpty,
           let add = tiles.firstIndex(of: .addChore) {
            tiles.remove(at: add)
            tiles.insert(.addChore, at: 0)
        }

        return tiles
    }

    /// Tiles that span the full width below the grid.
    private var fullWidthTiles: [TileKind] {
        store.members.count == 1 ? [.invite] : []
    }

    @ViewBuilder
    private func tile(for kind: TileKind) -> some View {
        switch kind {
        case .doItNow: doItNowTile
        case .mood: moodTile
        case .balance: balanceTile
        case .addChore: addChoreTile
        case .invite: inviteTile
        }
    }

    // MARK: - Tile variants

    private var doItNowTile: some View {
        let next = visibleToday.first
        let remaining = max(visibleToday.count - 1, 0)
        let palette = CardPalette.amber
        return HubTile(
            palette: palette,
            symbol: "bolt.fill",
            kicker: Copy.Hub.doItNowTitle,
            title: next?.title ?? "All clear",
            subtitle: next == nil
                ? Copy.Hub.doItNowEmptySubtitle
                : Copy.Hub.doItNowMore(remaining),
            badge: next.map { "\($0.effort.estimatedMinutes) min" },
            action: {
                if next == nil {
                    showAddChore = true
                } else {
                    path.append(HubRoute.doItNow)
                }
            }
        )
        .accessibilityHint(next == nil ? "Add your first chore" : "Open today's list")
    }

    private var moodTile: some View {
        let palette = CardPalette.indigo
        let isActive = mood.isActive
        let title = isActive ? moodActiveLabel : Copy.Hub.moodTitle
        let subtitle = isActive ? Copy.Hub.moodClear : Copy.Hub.moodSubtitle
        return HubTile(
            palette: palette,
            symbol: isActive ? mood.symbolName : "wand.and.stars",
            kicker: isActive ? "ACTIVE VIBE" : "MOOD",
            title: title,
            subtitle: subtitle,
            badge: nil,
            animatedSymbol: isActive,
            action: { showMood = true }
        )
        .matchedGeometryEffect(id: "mood-card-surface", in: moodNamespace, isSource: true)
        .contextMenu {
            if isActive {
                Button(role: .destructive, action: clearMood) {
                    Label(Copy.Hub.moodClear, systemImage: "xmark.circle.fill")
                }
            }
        }
    }

    private var balanceTile: some View {
        let palette = CardPalette.teal
        let verdict = balanceVerdict
        return HubTile(
            palette: palette,
            symbol: "chart.bar.fill",
            kicker: Copy.Hub.balanceTitle,
            title: verdict.title,
            subtitle: verdict.subtitle,
            badge: nil,
            action: { path.append(HubRoute.balance) }
        )
    }

    private var addChoreTile: some View {
        let palette = CardPalette.coral
        return HubTile(
            palette: palette,
            symbol: "plus",
            kicker: "NEW",
            title: Copy.Hub.addChoreTitle,
            subtitle: Copy.Hub.addChoreSubtitle,
            badge: nil,
            action: { showAddChore = true }
        )
    }

    private var inviteTile: some View {
        let palette = CardPalette.sky
        return HubTile(
            palette: palette,
            symbol: "person.2.fill",
            kicker: "INVITE",
            title: Copy.Hub.inviteTitle,
            subtitle: Copy.Hub.inviteSubtitle,
            badge: nil,
            alignment: .horizontal,
            action: { showInvite = true }
        )
    }

    // MARK: - Helpers

    private var moodActiveLabel: String {
        switch mood {
        case .none: return Copy.Hub.moodTitle
        case .lowEnergy: return Copy.Mood.tiredTitle
        case .quickOnly: return Copy.Mood.rushingTitle
        case .avoid: return Copy.Mood.skipCategory(avoidCategoryName ?? "category")
        }
    }

    private var balanceVerdict: (title: String, subtitle: String) {
        guard let meID = currentMemberID else {
            return ("This week", Copy.Hub.balanceSubtitleSolo)
        }
        let data = balanceData
        guard data.count > 1 else {
            return ("Solo show", Copy.Hub.balanceSubtitleSolo)
        }
        let sorted = data.sorted { $0.points > $1.points }
        let mine = sorted.first { $0.member.id == meID } ?? sorted[0]
        let top = sorted[0]
        if top.member.id == meID {
            let runnerUp = sorted.dropFirst().first
            if let runnerUp {
                let delta = mine.points - runnerUp.points
                if delta == 0 {
                    return ("All square", Copy.Hub.balanceSubtitleTied)
                }
                return ("You're ahead", Copy.Hub.balanceSubtitleAhead(runnerUp.member.name, delta))
            }
            return ("You're ahead", Copy.Hub.balanceSubtitleTied)
        }
        let delta = top.points - mine.points
        if delta == 0 {
            return ("All square", Copy.Hub.balanceSubtitleTied)
        }
        return ("Catch up?", Copy.Hub.balanceSubtitleBehind(top.member.name, delta))
    }

    // MARK: - Background

    private var backdrop: some View {
        LinearGradient(
            colors: scene.backgroundStops(),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Actions

    private func clearMood() {
        guard let id = currentMemberID else { return }
        Haptics.tap()
        withAnimation(Motion.emphasize) {
            store.setMood(.none, for: id)
        }
    }
}

// MARK: - Hub tile

/// A compact colored CTA tile. One icon, one tap target, one action.
/// Keeps the "no nested cards" rule — the flooded palette background is the card.
private struct HubTile: View {
    enum Layout { case vertical, horizontal }

    let palette: CardPalette
    let symbol: String
    let kicker: String
    let title: String
    let subtitle: String?
    let badge: String?
    var animatedSymbol: Bool = false
    var alignment: Layout = .vertical
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap(.light)
            action()
        } label: {
            content
                .frame(maxWidth: .infinity, minHeight: alignment == .horizontal ? 0 : 168, alignment: .topLeading)
                .padding(Spacing.lg)
                .background(palette.surfaceGradient)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                )
                .shadow(color: palette.glow, radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.97)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(kicker). \(title)."))
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var content: some View {
        switch alignment {
        case .vertical: verticalContent
        case .horizontal: horizontalContent
        }
    }

    private var verticalContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                iconOrb
                Spacer()
                if let badge { badgePill(badge) }
            }

            Spacer(minLength: Spacing.md)

            VStack(alignment: .leading, spacing: 4) {
                Text(kicker.uppercased())
                    .font(.caption2.weight(.heavy))
                    .tracking(0.7)
                    .foregroundStyle(palette.ink.opacity(0.65))
                    .lineLimit(1)
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .contentTransition(.interpolate)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(palette.inkSoft)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    private var horizontalContent: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            iconOrb
            VStack(alignment: .leading, spacing: 2) {
                Text(kicker.uppercased())
                    .font(.caption2.weight(.heavy))
                    .tracking(0.7)
                    .foregroundStyle(palette.ink.opacity(0.65))
                    .lineLimit(1)
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.ink)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(palette.inkSoft)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(palette.ink.opacity(0.55))
        }
    }

    private var iconOrb: some View {
        ZStack {
            Circle()
                .fill(palette.tintedNeutral.opacity(0.92))
                .frame(width: 44, height: 44)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 0.5))
            Group {
                if animatedSymbol {
                    Image(systemName: symbol)
                        .symbolEffect(.bounce, value: symbol)
                } else {
                    Image(systemName: symbol)
                }
            }
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(palette.ink)
        }
    }

    private func badgePill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(palette.ink)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 4)
            .background(palette.tintedNeutral.opacity(0.92), in: Capsule())
            .overlay(Capsule().strokeBorder(palette.ink.opacity(0.06), lineWidth: 0.5))
    }
}

// MARK: - Navigation route

enum HubRoute: Hashable {
    case doItNow, balance
}
