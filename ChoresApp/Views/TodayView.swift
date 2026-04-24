import SwiftUI

struct TodayView: View {
    @Environment(AppStore.self) private var store
    @Namespace private var moodNamespace
    @State private var showJobEditor = false
    @State private var confettiTrigger: Int = 0

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

    private var todaysPoints: Int {
        guard let id = currentMemberID else { return 0 }
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? .now
        return store.points(for: id, in: DateInterval(start: startOfDay, end: endOfDay))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    headerStats

                    MoodBarView(
                        mood: mood,
                        categories: store.categories,
                        namespace: moodNamespace,
                        onSelect: selectMood
                    )

                    if !visibleOccurrences.isEmpty {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(Array(visibleOccurrences.enumerated()), id: \.element.id) { index, occ in
                                OccurrenceRow(
                                    occurrence: occ,
                                    category: store.category(occ.categoryID),
                                    assignee: store.member(occ.assigneeID),
                                    onComplete: { complete(occ) },
                                    onSkip: { skip(occ) }
                                )
                                .transition(
                                    .asymmetric(
                                        insertion: .push(from: .bottom).combined(with: .opacity),
                                        removal: .scale(scale: 0.92).combined(with: .opacity)
                                    )
                                )
                                .transformEffect(.identity)
                                .zIndex(Double(visibleOccurrences.count - index))
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    } else {
                        emptyState
                            .padding(.top, Spacing.xl)
                    }

                    if hiddenCount > 0 {
                        hiddenBanner
                            .padding(.horizontal, Spacing.lg)
                    }
                }
                .padding(.vertical, Spacing.md)
                .animation(Motion.emphasize, value: mood)
                .animation(Motion.standard, value: visibleOccurrences.map(\.id))
            }
            .scrollContentBackground(.hidden)
            .background(backdrop)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        showJobEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Add job")
                }
            }
            .sheet(isPresented: $showJobEditor) {
                JobEditorView()
            }
            .overlay(alignment: .top) {
                CelebrationLayer(trigger: confettiTrigger)
                    .allowsHitTesting(false)
            }
        }
    }

    private var headerStats: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(greeting)
                    .font(.title2.weight(.bold))
                Text(dateSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()

            PointsPill(points: todaysPoints, tint: .yellow)
        }
        .padding(.horizontal, Spacing.lg)
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.accentColor.opacity(0.06),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var emptyState: some View {
        EmptyStateView(
            title: mood.isActive ? "Nothing that fits your mood" : "You're all caught up",
            message: mood.isActive
                ? "No tasks match \"\(mood.title)\". Snooze the mood or peek at what's hidden below."
                : "Enjoy the quiet. Future chores are safely queued.",
            systemImage: mood.isActive ? "wind" : "sparkles",
            tint: mood.isActive ? .purple : .accentColor,
            actionTitle: mood.isActive ? "Clear mood" : nil,
            action: mood.isActive ? { selectMood(.none) } : nil
        )
        .padding(.horizontal, Spacing.lg)
    }

    private var hiddenBanner: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "eye.slash")
                .foregroundStyle(.secondary)
            Text("\(hiddenCount) task\(hiddenCount == 1 ? "" : "s") hidden by \"\(mood.title)\"")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Show all") { selectMood(.none) }
                .font(.footnote.weight(.semibold))
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let name = store.currentMember?.name.components(separatedBy: " ").first ?? "friend"
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        case 17..<22: timeGreeting = "Good evening"
        default: timeGreeting = "Hi"
        }
        return "\(timeGreeting), \(name)"
    }

    private var dateSubtitle: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE · d MMM"
        return fmt.string(from: .now)
    }

    // MARK: - Actions

    private func selectMood(_ preset: MoodPreset) {
        guard let id = currentMemberID else { return }
        Haptics.tap(.medium)
        withAnimation(Motion.emphasize) {
            store.setMood(preset, for: id)
        }
    }

    private func complete(_ occ: Occurrence) {
        Haptics.success()
        withAnimation(Motion.playful) {
            store.completeOccurrence(occ.id)
            confettiTrigger &+= 1
        }
    }

    private func skip(_ occ: Occurrence) {
        Haptics.warning()
        withAnimation(Motion.standard) {
            store.skipOccurrence(occ.id)
        }
    }
}

// MARK: - Celebration overlay (PhaseAnimator-driven pop of glyphs)

struct CelebrationLayer: View {
    let trigger: Int

    var body: some View {
        PhaseAnimator([0, 1, 2], trigger: trigger) { phase in
            HStack(spacing: Spacing.lg) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: ["star.fill", "sparkle", "checkmark.seal.fill"].randomElement() ?? "star.fill")
                        .font(.title)
                        .foregroundStyle(celebrationTint(for: i).gradient)
                        .opacity(phase == 1 ? 1 : 0)
                        .scaleEffect(phase == 1 ? 1.2 : 0.5)
                        .offset(y: phase == 2 ? -140 : 0)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        } animation: { phase in
            switch phase {
            case 0: .snappy(duration: 0.05)
            case 1: .bouncy(duration: 0.35)
            default: .easeOut(duration: 0.55)
            }
        }
    }

    private func celebrationTint(for i: Int) -> Color {
        [.yellow, .pink, .mint, .purple, .orange][i % 5]
    }
}
