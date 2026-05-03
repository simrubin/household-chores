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
            } else {
                choreList
                    .padding(.horizontal, Spacing.lg)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
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

    private var choreList: some View {
        let rows = Array(visibleToday.prefix(7))
        let hasMore = visibleToday.count > 7
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { idx, occ in
                choreRow(occ)
                if idx < rows.count - 1 {
                    Rectangle()
                        .fill(Color.ink.opacity(0.06))
                        .frame(height: 0.5)
                }
            }
        }
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: hasMore ? 0.72 : 0.88),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .animation(Motion.standard, value: mood)
    }

    private func choreRow(_ occ: Occurrence) -> some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(Color.accentColor.opacity(occ.isCompleted ? 0.22 : 0.85))
                .frame(width: 7, height: 7)

            Text(occ.title)
                .font(.system(.body, weight: occ.isCompleted ? .regular : .medium))
                .foregroundStyle(occ.isCompleted ? Color.inkSoft : Color.ink)
                .strikethrough(occ.isCompleted, color: Color.inkSoft)
                .lineLimit(1)

            Spacer()

            if occ.isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.inkSoft)
            }
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .onTapGesture { path.append(HubRoute.doItNow) }
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
