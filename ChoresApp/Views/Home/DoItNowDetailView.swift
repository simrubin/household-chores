import SwiftUI

/// Reached by tapping the "Do it now" card. Shows today's full filtered list,
/// with the active mood visible at the top. Used to be `TodayView`.
struct DoItNowDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Binding var completionPayload: CompletionPayload?

    private var currentMemberID: UUID? { store.currentMember?.id }

    private var todayOccurrences: [Occurrence] {
        store.todaysOccurrences(for: currentMemberID)
    }

    private var mood: MoodPreset {
        guard let id = currentMemberID else { return .none }
        return store.mood(for: id)
    }

    private var visibleOccurrences: [Occurrence] {
        MoodSolver.apply(to: todayOccurrences, mood: mood)
    }

    private var hiddenCount: Int {
        MoodSolver.hidden(from: todayOccurrences, mood: mood).count
    }

    var body: some View {
        ScrollView {
            listContent
                .padding(.vertical, Spacing.md)
                .animation(Motion.emphasize, value: mood)
                .animation(Motion.standard, value: visibleOccurrences.map(\.id))
        }
        .scrollContentBackground(.hidden)
        .background(backdrop)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private var listContent: some View {
        VStack(spacing: Spacing.lg) {
            if mood.isActive {
                moodBanner
                    .padding(.horizontal, Spacing.lg)
            }

            if !visibleOccurrences.isEmpty {
                occurrencesList
                    .padding(.horizontal, Spacing.lg)
            } else {
                emptyState
                    .frame(minHeight: 320)
                    .padding(.top, Spacing.xl)
            }

            if hiddenCount > 0 {
                hiddenBanner
                    .padding(.horizontal, Spacing.lg)
            }
        }
    }

    private var occurrencesList: some View {
        LazyVStack(spacing: Spacing.md) {
            ForEach(Array(visibleOccurrences.enumerated()), id: \.element.id) { index, occ in
                OccurrenceRow(
                    occurrence: occ,
                    category: store.category(occ.categoryID),
                    assignee: store.member(occ.assigneeID),
                    onComplete: { complete(occ) },
                    onSkip: { skip(occ) }
                )
                .transition(.asymmetric(
                    insertion: .push(from: .bottom).combined(with: .opacity),
                    removal: .scale(scale: 0.92).combined(with: .opacity)
                ))
                .zIndex(Double(visibleOccurrences.count - index))
            }
        }
    }

    private var emptyState: some View {
        let active = mood.isActive
        let title: String = active ? "Nothing that fits the vibe" : "Inbox zero"
        let message: String = active
            ? "Nothing matches \"\(moodLabel)\". Clear the vibe to see the rest."
            : "Nothing on your plate. Enjoy."
        let symbol: String = active ? "wind" : "sparkles"
        let tint: Color = active ? CardPalette.indigo.primary : Color.accentColor
        let actionTitle: String? = active ? Copy.Hub.moodClear : nil
        let action: (() -> Void)? = active ? { clearMood() } : nil
        return EmptyStateView(
            title: title,
            message: message,
            systemImage: symbol,
            tint: tint,
            actionTitle: actionTitle,
            action: action
        )
    }

    private var backdrop: some View {
        LinearGradient(
            colors: DayScene.current().backgroundStops(),
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var moodBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: mood.symbolName)
                .foregroundStyle(CardPalette.palette(for: mood).primary)
            Text("Vibe: \(moodLabel)")
                .font(.footnote.weight(.semibold))
            Spacer()
            Button(Copy.Hub.moodClear) { clearMood() }
                .font(.footnote.weight(.semibold))
        }
        .padding(Spacing.md)
        .background(CardPalette.palette(for: mood).tintedNeutral, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private var hiddenBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "eye.slash")
                .foregroundStyle(.secondary)
            Text("\(hiddenCount) chore\(hiddenCount == 1 ? "" : "s") hidden by the vibe")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Show all") { clearMood() }
                .font(.footnote.weight(.semibold))
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private var moodLabel: String {
        switch mood {
        case .none: "All"
        case .lowEnergy: Copy.Mood.tiredTitle
        case .quickOnly: Copy.Mood.rushingTitle
        case .avoid(let catID):
            Copy.Mood.skipCategory(store.category(catID)?.name ?? "category")
        }
    }

    // MARK: - Actions

    private func clearMood() {
        guard let id = currentMemberID else { return }
        Haptics.tap()
        withAnimation(Motion.emphasize) { store.setMood(.none, for: id) }
    }

    private func complete(_ occ: Occurrence) {
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

    private func skip(_ occ: Occurrence) {
        Haptics.warning()
        withAnimation(Motion.standard) {
            store.skipOccurrence(occ.id)
        }
    }
}

// MARK: - Verdict builder

enum CompletionVerdict {
    static func build(for occ: Occurrence, in store: AppStore) -> (text: String, overtook: Bool) {
        let remaining = max(store.todaysOccurrences().count - 1, 0)
        guard store.members.count > 1, let me = store.currentMemberID else {
            if remaining == 0 { return (Copy.Completion.verdictRemaining(0), false) }
            return (Copy.Completion.verdictRemaining(remaining), false)
        }

        let cal = Calendar.current
        let now = Date.now
        let start = cal.date(byAdding: .day, value: -7, to: now) ?? now
        let interval = DateInterval(start: start, end: now)

        // After this completion, add the delta into a projected leaderboard.
        let projected: [(Member, Int)] = store.members.map { m in
            var pts = store.points(for: m.id, in: interval)
            if m.id == me { pts += occ.effort.points }
            return (m, pts)
        }.sorted { $0.1 > $1.1 }

        guard let leader = projected.first else {
            return (Copy.Completion.verdictRemaining(remaining), false)
        }

        if leader.0.id == me {
            let runnerUp = projected.dropFirst().first
            let delta = (runnerUp?.1 ?? 0)
            let diff = leader.1 - delta
            if let other = runnerUp, diff > 0 {
                return (Copy.Completion.verdictOvertook(firstName(other.0.name), diff), true)
            }
            return (Copy.Completion.verdictRemaining(remaining), false)
        } else {
            let myPts = projected.first(where: { $0.0.id == me })?.1 ?? 0
            let diff = leader.1 - myPts
            if diff > 0 {
                return (Copy.Completion.verdictBehind(firstName(leader.0.name), diff), false)
            }
            return (Copy.Completion.verdictTied, false)
        }
    }

    private static func firstName(_ s: String) -> String {
        s.components(separatedBy: " ").first ?? s
    }
}
