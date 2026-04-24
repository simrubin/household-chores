import SwiftUI

struct FutureView: View {
    @Environment(AppStore.self) private var store

    private struct DayGroup: Identifiable {
        var id: Date { day }
        let day: Date
        let occurrences: [Occurrence]
    }

    private var groups: [DayGroup] {
        let occurrences = store.futureOccurrences()
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: occurrences) { calendar.startOfDay(for: $0.dueDate) }
        return grouped
            .map { DayGroup(day: $0.key, occurrences: $0.value.sorted(by: { $0.dueDate < $1.dueDate })) }
            .sorted { $0.day < $1.day }
    }

    var body: some View {
        NavigationStack {
            Group {
                if groups.isEmpty {
                    EmptyStateView(
                        title: "Clear schedule",
                        message: "Create recurring jobs to see them appear here.",
                        systemImage: "calendar",
                        tint: .accentColor
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.xl, pinnedViews: [.sectionHeaders]) {
                            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                                Section {
                                    VStack(spacing: Spacing.md) {
                                        ForEach(group.occurrences) { occ in
                                            futureRow(occ)
                                                .transition(.asymmetric(
                                                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                                                    removal: .opacity
                                                ))
                                        }
                                    }
                                    .padding(.horizontal, Spacing.lg)
                                } header: {
                                    sectionHeader(for: group.day)
                                        .padding(.horizontal, Spacing.lg)
                                        .padding(.vertical, Spacing.sm)
                                }
                                .transition(.opacity)
                                .animation(.smooth.delay(Double(index) * 0.04), value: groups.count)
                            }
                        }
                        .padding(.vertical, Spacing.md)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Upcoming")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func sectionHeader(for day: Date) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "calendar")
                .foregroundStyle(Color.accentColor)
            Text(Self.relativeLabel(for: day))
                .font(.headline)
            Spacer()
            Text(Self.dateFormatter.string(from: day))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: Capsule())
    }

    private func futureRow(_ occ: Occurrence) -> some View {
        HStack(spacing: Spacing.md) {
            timeCapsule(for: occ.dueDate)
            VStack(alignment: .leading, spacing: 4) {
                Text(occ.title).font(.body.weight(.semibold))
                HStack(spacing: Spacing.sm) {
                    if let cat = store.category(occ.categoryID) {
                        HStack(spacing: 4) {
                            Image(systemName: cat.symbolName).imageScale(.small)
                            Text(cat.name).font(.caption.weight(.medium))
                        }
                        .foregroundStyle(cat.tint)
                    }
                    EffortBadge(effort: occ.effort, compact: true)
                }
            }
            Spacer(minLength: 0)
            if let member = store.member(occ.assigneeID) {
                AvatarView(emoji: member.emoji, tint: member.tint, size: 28)
            } else {
                Image(systemName: "person.2")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    private func timeCapsule(for date: Date) -> some View {
        VStack(spacing: 0) {
            Text(Self.timeFormatter.string(from: date))
                .font(.caption.weight(.bold).monospacedDigit())
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.15), in: Capsule())
        .foregroundStyle(Color.accentColor)
    }

    private static func relativeLabel(for day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInTomorrow(day) { return "Tomorrow" }
        if cal.isDate(day, equalTo: .now, toGranularity: .weekOfYear) {
            let fmt = DateFormatter(); fmt.dateFormat = "EEEE"
            return fmt.string(from: day)
        }
        let fmt = DateFormatter(); fmt.dateFormat = "EEEE"
        return fmt.string(from: day)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()
}
