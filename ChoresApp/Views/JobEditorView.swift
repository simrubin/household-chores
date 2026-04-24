import SwiftUI

struct JobEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let existing: Job?

    @State private var title: String
    @State private var notes: String
    @State private var categoryID: UUID
    @State private var effort: EffortLevel
    @State private var recurrenceMode: RecurrenceMode
    @State private var selectedWeekdays: Set<Int>
    @State private var assigneeID: UUID?
    @State private var reminderTime: Date
    @State private var showingCategoryManager = false

    private enum RecurrenceMode: String, CaseIterable, Identifiable {
        case none, daily, weekly
        var id: String { rawValue }
        var label: String {
            switch self {
            case .none: "One-time"
            case .daily: "Daily"
            case .weekly: "Weekly"
            }
        }
    }

    init(existing: Job? = nil) {
        self.existing = existing
        _title = State(initialValue: existing?.title ?? "")
        _notes = State(initialValue: existing?.notes ?? "")
        _categoryID = State(initialValue: existing?.categoryID ?? UUID())
        _effort = State(initialValue: existing?.effort ?? .medium)
        _assigneeID = State(initialValue: existing?.defaultAssigneeID)

        let defaultTime: Date = {
            var comps = DateComponents()
            comps.hour = 9; comps.minute = 0
            return Calendar.current.date(from: comps) ?? .now
        }()
        _reminderTime = State(initialValue: existing?.startDate ?? defaultTime)

        if let rec = existing?.recurrence {
            switch rec {
            case .none:
                _recurrenceMode = State(initialValue: .none)
                _selectedWeekdays = State(initialValue: [])
            case .daily:
                _recurrenceMode = State(initialValue: .daily)
                _selectedWeekdays = State(initialValue: [])
            case .weekly(let days):
                _recurrenceMode = State(initialValue: .weekly)
                _selectedWeekdays = State(initialValue: days)
            }
        } else {
            _recurrenceMode = State(initialValue: .weekly)
            let today = Calendar.current.component(.weekday, from: .now)
            _selectedWeekdays = State(initialValue: [today])
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Job") {
                    TextField("e.g. Empty the dishwasher", text: $title)
                        .textInputAutocapitalization(.sentences)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                        .foregroundStyle(.secondary)
                }

                Section("Category") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(store.categories) { cat in
                                categoryChip(cat)
                            }
                            Button {
                                showingCategoryManager = true
                            } label: {
                                Label("Manage", systemImage: "slider.horizontal.3")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.glass)
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }

                Section("Effort") {
                    EffortStepper(effort: $effort)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }

                Section("Repeats") {
                    Picker("Schedule", selection: $recurrenceMode) {
                        ForEach(RecurrenceMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if recurrenceMode == .weekly {
                        WeekdayPicker(selection: $selectedWeekdays)
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    }

                    DatePicker(
                        recurrenceMode == .none ? "On date" : "Reminder time",
                        selection: $reminderTime,
                        displayedComponents: recurrenceMode == .none ? [.date, .hourAndMinute] : [.hourAndMinute]
                    )
                }

                Section("Assign to") {
                    Picker("Assignee", selection: Binding(
                        get: { assigneeID?.uuidString ?? "pool" },
                        set: { new in
                            assigneeID = new == "pool" ? nil : UUID(uuidString: new)
                        }
                    )) {
                        Text("Open pool").tag("pool")
                        ForEach(store.members) { m in
                            Label(m.name, systemImage: "circle.fill")
                                .foregroundStyle(m.tint)
                                .tag(m.id.uuidString)
                        }
                    }
                }

                if existing != nil {
                    Section {
                        Button("Archive job", systemImage: "archivebox", role: .destructive) {
                            guard let existing else { return }
                            withAnimation { store.archiveJob(existing.id) }
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "New job" : "Edit job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .buttonStyle(.glassProminent)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if existing == nil, let first = store.categories.first?.id {
                    categoryID = first
                }
            }
            .sheet(isPresented: $showingCategoryManager) {
                CategoryManagerView()
            }
        }
    }

    private func categoryChip(_ cat: Category) -> some View {
        let selected = cat.id == categoryID
        return Button {
            Haptics.selection()
            withAnimation(Motion.responsive) { categoryID = cat.id }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: cat.symbolName)
                Text(cat.name)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 8)
            .foregroundStyle(selected ? .white : cat.tint)
            .background {
                if selected {
                    Capsule().fill(cat.tint.gradient)
                        .shadow(color: cat.tint.opacity(0.5), radius: 6, y: 2)
                }
            }
            .glassEffect(selected ? .clear : .regular, in: Capsule())
        }
        .buttonStyle(.plain)
        .scaleEffect(selected ? 1.04 : 1)
        .animation(Motion.playful, value: selected)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        (recurrenceMode != .weekly || !selectedWeekdays.isEmpty)
    }

    private func save() {
        Haptics.success()

        let recurrence: RecurrenceKind = {
            switch recurrenceMode {
            case .none: return .none
            case .daily: return .daily
            case .weekly: return .weekly(selectedWeekdays)
            }
        }()

        let startDate: Date = {
            let cal = Calendar.current
            var comps = cal.dateComponents([.year, .month, .day], from: .now)
            let timeComps = cal.dateComponents([.hour, .minute], from: reminderTime)
            comps.hour = timeComps.hour
            comps.minute = timeComps.minute
            if recurrenceMode == .none {
                let dateComps = cal.dateComponents([.year, .month, .day], from: reminderTime)
                comps.year = dateComps.year
                comps.month = dateComps.month
                comps.day = dateComps.day
            }
            return cal.date(from: comps) ?? .now
        }()

        let job = Job(
            id: existing?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            notes: notes,
            categoryID: categoryID,
            effort: effort,
            recurrence: recurrence,
            startDate: startDate,
            defaultAssigneeID: assigneeID,
            archived: existing?.archived ?? false
        )
        store.upsertJob(job)
        dismiss()
    }
}

// MARK: - Effort stepper

struct EffortStepper: View {
    @Binding var effort: EffortLevel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Image(systemName: effort.symbolName)
                    .foregroundStyle(effort.tint)
                    .symbolEffect(.bounce, value: effort)
                Text(effort.label)
                    .font(.headline)
                Spacer()
                Text("\(effort.points) pt\(effort.points == 1 ? "" : "s")")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .contentTransition(.numericText(value: Double(effort.points)))
                    .foregroundStyle(effort.tint)
            }
            HStack(spacing: Spacing.sm) {
                ForEach(EffortLevel.allCases) { level in
                    Button {
                        Haptics.selection()
                        withAnimation(Motion.playful) { effort = level }
                    } label: {
                        Capsule()
                            .fill(level.rawValue <= effort.rawValue ? level.tint.gradient : Color.gray.opacity(0.2).gradient)
                            .frame(height: 28)
                            .overlay(
                                Text("\(level.points)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(level.rawValue <= effort.rawValue ? .white : .secondary)
                            )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(level == effort ? 1.08 : 1)
                    .animation(Motion.playful, value: effort)
                }
            }
        }
    }
}

// MARK: - Weekday picker

struct WeekdayPicker: View {
    @Binding var selection: Set<Int>
    private let weekdays = Array(1...7)

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekdays, id: \.self) { day in
                let active = selection.contains(day)
                Button {
                    Haptics.selection()
                    withAnimation(Motion.responsive) {
                        if active { selection.remove(day) } else { selection.insert(day) }
                    }
                } label: {
                    Text(RecurrenceKind.dayShortName(day).prefix(1))
                        .font(.subheadline.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .foregroundStyle(active ? .white : .primary)
                        .background(
                            Capsule().fill(active ? Color.accentColor.gradient : Color.gray.opacity(0.15).gradient)
                        )
                        .scaleEffect(active ? 1.06 : 1)
                }
                .buttonStyle(.plain)
                .animation(Motion.playful, value: active)
            }
        }
    }
}
