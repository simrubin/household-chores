import Combine
import SwiftUI

/// The flagship screen. A split canvas: minimalist chore preview (top) +
/// four compact action tiles (bottom).
struct HomeHubView: View {
    @Environment(AppStore.self) private var store

    @State private var scene: DayScene = .current()
    @State private var path = NavigationPath()
    @State private var showMood = false
    @State private var showAddChore = false
    @State private var showInvite = false
    @State private var completionPayload: CompletionPayload?
    @Namespace private var moodNamespace

    // MARK: - Derived

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

    private var todaysKarma: Int {
        guard let id = currentMemberID else { return 0 }
        let start = Calendar.current.startOfDay(for: .now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? .now
        return store.points(for: id, in: DateInterval(start: start, end: end))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $path) {
            choreZone
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    actionZone
                }
            .background(backdrop.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: HubRoute.self) { route in
                switch route {
                case .doItNow:
                    DoItNowDetailView(completionPayload: $completionPayload)
                case .balance:
                    BalanceDetailView()
                case .homeSettings:
                    HouseholdView()
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

    // MARK: - Chore zone (top 60%)

    private var choreZone: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.lg)

            if visibleToday.isEmpty {
                emptyChoreState
                    .padding(.horizontal, Spacing.lg)
                Spacer(minLength: 0)
            } else {
                choreScrollList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            homeNameButton
            Spacer()
            todayKarmaPill
        }
    }

    private var homeDisplayName: String {
        store.household.name.isEmpty ? "Home" : store.household.name
    }

    private var homeNameButton: some View {
        Button {
            path.append(HubRoute.homeSettings)
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "house.fill")
                    .font(.system(.body, weight: .semibold))
                Text(homeDisplayName)
                    .font(.system(.title3, weight: .semibold))
                    .lineLimit(1)
            }
        }
        .buttonStyle(.glass)
        .controlSize(.regular)
        .accessibilityLabel("Home settings, \(homeDisplayName)")
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

    // MARK: - Chore preview

    private var emptyChoreState: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: "checkmark.circle")
                .font(.title3.weight(.light))
                .foregroundStyle(Color.inkSoft.opacity(0.45))
            Text("All clear today")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(Color.inkSoft)
        }
        .padding(.top, Spacing.md)
    }

    /// Vertical fade so list content softens at scroll edges.
    private var choreListScrollEdgeMask: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.06),
                .init(color: .black, location: 0.94),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Scrollable list with system swipe actions (leading = later, trailing = done).
    private var choreScrollList: some View {
        List {
            ForEach(visibleToday) { occ in
                HubChoreRow(
                    occurrence: occ,
                    assignee: store.member(occ.assigneeID),
                    onComplete: { completeOccurrenceOnHub(occ) },
                    onOpenToday: { path.append(HubRoute.doItNow) }
                )
                .listRowInsets(EdgeInsets(top: HubChoreRow.rowVerticalInset, leading: Spacing.lg, bottom: HubChoreRow.rowVerticalInset, trailing: Spacing.lg))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        delayOccurrenceOnHub(occ)
                    } label: {
                        Label(Copy.Hub.laterSwipe, systemImage: "calendar.badge.clock")
                    }
                    .tint(.orange)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        completeOccurrenceOnHub(occ)
                    } label: {
                        Label(Copy.Hub.doItNowPrimary, systemImage: "checkmark.circle.fill")
                    }
                    .tint(Color.hubSwipeComplete)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, Spacing.xl, for: .scrollContent)
        .environment(\.defaultMinListRowHeight, HubChoreRow.listCellHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .mask(choreListScrollEdgeMask)
        .animation(Motion.standard, value: mood)
        .animation(Motion.standard, value: visibleToday.map(\.id))
    }

    // MARK: - Action zone (bottom 40%)

    private let actionColumns: [GridItem] = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    private var actionZone: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: actionColumns, spacing: Spacing.sm) {
                // Top-left — most prominent CTA
                CompactActionTile(
                    symbol: "plus",
                    label: "Add chore",
                    action: { showAddChore = true }
                )

                CompactActionTile(
                    symbol: mood.isActive ? mood.symbolName : "wand.and.stars",
                    label: mood.isActive ? "Vibe on" : "Mood",
                    action: { showMood = true }
                )
                .matchedGeometryEffect(id: "mood-card-surface", in: moodNamespace, isSource: true)
                .contextMenu {
                    if mood.isActive {
                        Button(role: .destructive, action: clearMood) {
                            Label(Copy.Hub.moodClear, systemImage: "xmark.circle.fill")
                        }
                    }
                }

                CompactActionTile(
                    symbol: "chart.bar.fill",
                    label: "Balance",
                    action: { path.append(HubRoute.balance) }
                )

                CompactActionTile(
                    symbol: "person.badge.plus",
                    label: "Invite",
                    action: { showInvite = true }
                )
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xl)
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

    private func completeOccurrenceOnHub(_ occ: Occurrence) {
        let verdict = CompletionVerdict.build(for: occ, in: store)
        Haptics.success()
        withAnimation(Motion.playful) {
            store.completeOccurrence(occ.id)
        }
        completionPayload = CompletionPayload(
            title: occ.title,
            karmaDelta: occ.effort.points,
            verdict: verdict.text,
            tint: occ.effort.tint
        )
    }

    /// Defers out of today by marking skipped; next instance comes from job recurrence.
    private func delayOccurrenceOnHub(_ occ: Occurrence) {
        Haptics.warning()
        withAnimation(Motion.standard) {
            store.skipOccurrence(occ.id)
        }
    }
}

// MARK: - Hub chore row

/// Compact row: checkbox, title, assignee + due line, avatar. Checkbox uses the same
/// playful complete animation as `OccurrenceRow`; swipes use native `swipeActions`.
private struct HubChoreRow: View {
    static let rowVerticalInset: CGFloat = 6
    /// Card content min height; with `listRowInsets` top+bottom matches `listCellHeight`.
    private static let cardBodyMinHeight: CGFloat = 64
    /// Matches List `defaultMinListRowHeight`: card + vertical list insets.
    static var listCellHeight: CGFloat { cardBodyMinHeight + rowVerticalInset * 2 }

    let occurrence: Occurrence
    let assignee: Member?
    let onComplete: () -> Void
    let onOpenToday: () -> Void

    @State private var isCompleting = false

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    private var assigneeCaption: String {
        guard let assignee else { return "Anyone" }
        if let first = assignee.name.split(separator: " ").first {
            return String(first)
        }
        return assignee.name
    }

    private var dueMeta: (text: String, color: Color) {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        if occurrence.dueDate < startOfToday {
            return (Copy.Activity.wasYesterday, Color.red.opacity(0.88))
        }
        let t = Self.timeFmt.string(from: occurrence.dueDate)
        return ("Today · \(t)", Color.inkSoft)
    }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            checkbox
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(occurrence.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)

                HStack(spacing: Spacing.xs) {
                    HStack(spacing: 3) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text(assigneeCaption)
                    }
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.inkSoft)

                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)

                    Text(dueMeta.text)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(dueMeta.color)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.selection()
                onOpenToday()
            }

            if let assignee {
                AvatarView(emoji: assignee.emoji, tint: assignee.tint, size: 28)
            } else {
                Image(systemName: "person.2")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.inkSoft)
                    .frame(width: 28, height: 28)
                    .background(Color.ink.opacity(0.06), in: Circle())
                    .accessibilityLabel(Copy.Wizard.whoOpen)
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .frame(maxWidth: .infinity, minHeight: Self.cardBodyMinHeight, alignment: .center)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(Color.ink.opacity(0.06), lineWidth: 0.5)
        )
        .opacity(isCompleting ? 0.78 : 1)
        .scaleEffect(isCompleting ? 0.98 : 1)
        .animation(Motion.responsive, value: isCompleting)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Swipe left for done, right for later. Tap chore title opens the full Today list.")
        .sensoryFeedback(.success, trigger: isCompleting)
    }

    private var checkbox: some View {
        Button(action: triggerCheckboxComplete) {
            ZStack {
                Circle()
                    .strokeBorder(Color.inkSoft.opacity(0.55), lineWidth: 1.5)
                    .frame(width: 24, height: 24)

                if isCompleting {
                    Circle()
                        .fill(occurrence.effort.tint)
                        .frame(width: 24, height: 24)
                        .transition(.scale.combined(with: .opacity))

                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                        .symbolEffect(.bounce, value: isCompleting)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Copy.Hub.doItNowPrimary) \(occurrence.title)")
    }

    private func triggerCheckboxComplete() {
        guard !isCompleting else { return }
        withAnimation(Motion.playful) { isCompleting = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onComplete()
        }
    }
}

// MARK: - Compact action tile

/// Small, two-element CTA: icon + label. Lives in a 2x2 grid at the bottom
/// of the home screen. No kicker, no subtitle — one tap target, one concept.
private struct CompactActionTile: View {
    let symbol: String
    let label: String
    let action: () -> Void

    private static let tileInk = Color.cinder
    private static let tileSurface = Color.eggshell

    var body: some View {
        Button {
            Haptics.tap(.light)
            action()
        } label: {
            HStack(spacing: Spacing.sm) {
                Text(label)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(Self.tileInk)
                    .lineLimit(1)
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Self.tileInk)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Self.tileSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(Color.chalk, lineWidth: 0.5)
            )
            .shadow(color: Color.obsidian.opacity(0.025), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.97)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Navigation route

enum HubRoute: Hashable {
    case doItNow, balance, homeSettings
}
