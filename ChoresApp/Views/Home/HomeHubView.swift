import Combine
import SwiftUI

/// The flagship screen. Replaces TodayView as the app's front door.
/// Stacks outcome cards in priority order, swapped by the time of day.
struct HomeHubView: View {
    @Environment(AppStore.self) private var store

    @State private var scene: DayScene = .current()
    @State private var path = NavigationPath()
    @State private var showMood = false
    @State private var showAddChore = false
    @State private var showInvite = false
    @State private var completionPayload: CompletionPayload?
    @Namespace private var moodNamespace

    private var currentMemberID: UUID? { store.currentMember?.id }

    private var allToday: [Occurrence] {
        store.todaysOccurrences(for: currentMemberID)
    }

    private var visibleToday: [Occurrence] {
        let m = mood
        return MoodSolver.apply(to: allToday, mood: m)
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
                VStack(spacing: Spacing.lg) {
                    header
                        .padding(.horizontal, Spacing.lg)
                        .padding(.top, Spacing.sm)

                    VStack(spacing: Spacing.md) {
                        ForEach(orderedCards, id: \.self) { kind in
                            card(for: kind)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                    removal: .opacity
                                ))
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.huge)
                }
                .animation(Motion.emphasize, value: mood)
                .animation(Motion.hero, value: orderedCards)
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
                Text(homeName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.inkSoft)
            }
            Spacer()
            todayKarmaPill
        }
    }

    private var homeName: String {
        store.household.name.isEmpty ? "Home" : store.household.name
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

    // MARK: - Cards

    enum CardKind: Hashable {
        case doItNow, mood, balance, addChore, invite
    }

    private var orderedCards: [CardKind] {
        var base: [CardKind] = [.doItNow, .mood]
        if store.members.count > 1 {
            base.append(.balance)
        }
        base.append(.addChore)
        if store.members.count == 1 {
            base.append(.invite)
        }

        // Empty-state: if no chores exist at all, float AddChore to top.
        if store.jobs.filter({ !$0.archived }).isEmpty {
            if let idx = base.firstIndex(of: .addChore) {
                base.remove(at: idx)
                base.insert(.addChore, at: 0)
            }
        }

        // Evening shift: promote Balance above Mood.
        if scene.isEveningShift, base.contains(.balance), let b = base.firstIndex(of: .balance), let m = base.firstIndex(of: .mood), b > m {
            base.remove(at: b)
            base.insert(.balance, at: m)
        }

        return base
    }

    @ViewBuilder
    private func card(for kind: CardKind) -> some View {
        switch kind {
        case .doItNow:
            let next = visibleToday.first
            let remaining = max(visibleToday.count - 1, 0)
            DoItNowCard(
                nextTask: next,
                category: next.flatMap { store.category($0.categoryID) },
                remainingCount: remaining,
                onDone: { if let n = next { completeFromHub(n) } },
                onDrill: { path.append(HubRoute.doItNow) },
                onAdd: { showAddChore = true }
            )

        case .mood:
            MoodCard(
                mood: mood,
                avoidCategoryName: avoidCategoryName,
                namespace: moodNamespace,
                onTapCard: { showMood = true },
                onClear: clearMood
            )

        case .balance:
            BalanceCard(
                data: balanceData,
                currentMemberID: currentMemberID,
                onTap: { path.append(HubRoute.balance) }
            )

        case .addChore:
            AddChoreCard(onTap: { showAddChore = true })

        case .invite:
            InviteCrewCard(onTap: { showInvite = true })
        }
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

    private func completeFromHub(_ occ: Occurrence) {
        let verdict = CompletionVerdict.build(for: occ, in: store)
        Haptics.success()
        withAnimation(Motion.playful) {
            store.completeOccurrence(occ.id)
        }
        completionPayload = CompletionPayload(
            title: occ.title,
            karmaDelta: occ.effort.points,
            verdict: verdict.text,
            tint: CardPalette.amber.primary
        )
    }
}

// MARK: - Navigation route

enum HubRoute: Hashable {
    case doItNow, balance
}
