import SwiftUI

/// 3-page wizard that replaces the old JobEditorView Form. Each page owns
/// one big decision; a progress dotline sits at the top and a single primary
/// CTA anchors the bottom.
///
/// Reuses for edit: pass `existing`.
struct AddChoreWizardView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let existing: Job?

    @State private var page: Page = .what
    @State private var slideEdge: Edge = .trailing

    // Draft state (shared across all pages)
    @State private var title: String = ""
    @State private var categoryID: UUID?
    @State private var recurrenceMode: RecurrenceMode = .daily
    @State private var weekdays: Set<Int> = []
    @State private var reminderTime: Date = Self.defaultReminderTime()
    @State private var effort: EffortLevel = .medium
    @State private var assigneeID: UUID? = nil

    // Placeholder typewriter
    @State private var placeholderIndex: Int = 0
    @State private var placeholderTimer: Timer? = nil

    enum Page: Int, CaseIterable { case what, when, whoEffort }

    enum RecurrenceMode: String, CaseIterable, Identifiable {
        case once, daily, someDays, weekly
        var id: String { rawValue }
        var label: String {
            switch self {
            case .once: Copy.Wizard.whenOnce
            case .daily: Copy.Wizard.whenDaily
            case .someDays: Copy.Wizard.whenSomeDays
            case .weekly: Copy.Wizard.whenWeekly
            }
        }
        var symbol: String {
            switch self {
            case .once: "1.circle.fill"
            case .daily: "sun.max.fill"
            case .someDays: "calendar.badge.clock"
            case .weekly: "repeat"
            }
        }
    }

    init(existing: Job? = nil) {
        self.existing = existing
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressDotline
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.md)

                pageContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .animation(reduceMotion ? nil : Motion.standard, value: page)
                    .animation(reduceMotion ? nil : Motion.standard, value: recurrenceMode)

                bottomBar
            }
            .background(backdrop)
            .navigationTitle(existing == nil ? Copy.Hub.addChoreTitle : "Edit chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Copy.Common.cancel) { dismiss() }
                }
                if let existing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .destructive) {
                            withAnimation { store.archiveJob(existing.id) }
                            dismiss()
                        } label: {
                            Image(systemName: "archivebox")
                        }
                        .accessibilityLabel(Copy.Common.retire)
                    }
                }
            }
            .onAppear {
                seed()
                cyclePlaceholder()
            }
            .onDisappear { placeholderTimer?.invalidate() }
        }
    }

    // MARK: - Chrome

    private var backdrop: some View {
        LinearGradient(
            colors: DayScene.current().backgroundStops(),
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var progressDotline: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Page.allCases, id: \.rawValue) { p in
                Capsule()
                    .fill(p.rawValue <= page.rawValue ? Color.ink : Color.ink.opacity(0.15))
                    .frame(height: 4)
                    .animation(Motion.standard, value: page)
            }
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case .what:
            AddChoreStepWhat(
                title: $title,
                categoryID: $categoryID,
                categories: store.categories,
                placeholderIndex: placeholderIndex
            )
            .id(Page.what)
            .transition(.asymmetric(insertion: .move(edge: slideEdge), removal: .move(edge: slideEdge == .trailing ? .leading : .trailing).combined(with: .opacity)))

        case .when:
            AddChoreStepWhen(
                recurrenceMode: $recurrenceMode,
                weekdays: $weekdays,
                reminderTime: $reminderTime
            )
            .id(Page.when)
            .transition(.asymmetric(insertion: .move(edge: slideEdge), removal: .move(edge: slideEdge == .trailing ? .leading : .trailing).combined(with: .opacity)))

        case .whoEffort:
            AddChoreStepWhoEffort(
                effort: $effort,
                assigneeID: $assigneeID,
                members: store.members
            )
            .id(Page.whoEffort)
            .transition(.asymmetric(insertion: .move(edge: slideEdge), removal: .move(edge: slideEdge == .trailing ? .leading : .trailing).combined(with: .opacity)))
        }
    }

    private var bottomBar: some View {
        HStack(spacing: Spacing.md) {
            if page != .what {
                Button {
                    Haptics.tap()
                    slideEdge = .leading
                    withAnimation(Motion.standard) {
                        page = Page(rawValue: page.rawValue - 1) ?? .what
                    }
                } label: {
                    Label(Copy.Wizard.back, systemImage: "chevron.left")
                        .labelStyle(.titleOnly)
                        .font(.headline)
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, Spacing.lg)
                        .frame(minHeight: 56)
                        .background(Color.ink.opacity(0.08), in: Capsule())
                }
                .buttonStyle(.plain)
                .pressable(scale: 0.97)
            }

            Button {
                advance()
            } label: {
                HStack(spacing: Spacing.sm) {
                    Text(ctaTitle)
                        .font(.headline)
                    if page != .whoEffort {
                        Image(systemName: "arrow.right")
                    } else {
                        Image(systemName: "sparkles")
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color.ink.gradient, in: Capsule())
                .shadow(color: Color.ink.opacity(0.35), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .pressable(scale: 0.97)
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.4)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(.ultraThinMaterial)
    }

    private var ctaTitle: String {
        switch page {
        case .what, .when: return Copy.Wizard.next
        case .whoEffort: return existing == nil ? Copy.Wizard.addChore : Copy.Wizard.saveChanges
        }
    }

    private var canAdvance: Bool {
        switch page {
        case .what:
            return !title.trimmingCharacters(in: .whitespaces).isEmpty && categoryID != nil
        case .when:
            return recurrenceMode != .someDays || !weekdays.isEmpty
        case .whoEffort:
            return true
        }
    }

    // MARK: - Actions

    private func advance() {
        Haptics.tap(.medium)
        switch page {
        case .what:
            slideEdge = .trailing
            withAnimation(Motion.standard) { page = .when }
        case .when:
            slideEdge = .trailing
            withAnimation(Motion.standard) { page = .whoEffort }
        case .whoEffort:
            save()
        }
    }

    private func save() {
        guard let catID = categoryID else { return }
        Haptics.success()

        let recurrence: RecurrenceKind = {
            switch recurrenceMode {
            case .once: return .none
            case .daily: return .daily
            case .someDays: return .weekly(weekdays)
            case .weekly: return .weekly(Set(1...7))
            }
        }()

        let startDate: Date = {
            let cal = Calendar.current
            var comps = cal.dateComponents([.year, .month, .day], from: .now)
            let t = cal.dateComponents([.hour, .minute], from: reminderTime)
            comps.hour = t.hour
            comps.minute = t.minute
            if recurrenceMode == .once {
                let d = cal.dateComponents([.year, .month, .day], from: reminderTime)
                comps.year = d.year
                comps.month = d.month
                comps.day = d.day
            }
            return cal.date(from: comps) ?? .now
        }()

        let job = Job(
            id: existing?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            notes: existing?.notes ?? "",
            categoryID: catID,
            effort: effort,
            recurrence: recurrence,
            startDate: startDate,
            defaultAssigneeID: assigneeID,
            archived: existing?.archived ?? false
        )
        store.upsertJob(job)
        dismiss()
    }

    private func seed() {
        if let existing {
            title = existing.title
            categoryID = existing.categoryID
            effort = existing.effort
            assigneeID = existing.defaultAssigneeID
            reminderTime = existing.startDate
            switch existing.recurrence {
            case .none:
                recurrenceMode = .once
                weekdays = []
            case .daily:
                recurrenceMode = .daily
                weekdays = []
            case .weekly(let days):
                if days.count == 7 {
                    recurrenceMode = .weekly
                    weekdays = days
                } else {
                    recurrenceMode = .someDays
                    weekdays = days
                }
            }
        } else {
            if categoryID == nil { categoryID = store.categories.first?.id }
            if weekdays.isEmpty {
                let today = Calendar.current.component(.weekday, from: .now)
                weekdays = [today]
            }
        }
    }

    private func cyclePlaceholder() {
        placeholderTimer?.invalidate()
        placeholderTimer = Timer.scheduledTimer(withTimeInterval: 2.4, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(Motion.emphasize) {
                    placeholderIndex = (placeholderIndex + 1) % Copy.Wizard.whatFieldPlaceholders.count
                }
            }
        }
    }

    private static func defaultReminderTime() -> Date {
        var c = DateComponents()
        c.hour = 9
        c.minute = 0
        return Calendar.current.date(from: c) ?? .now
    }
}
