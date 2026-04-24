import SwiftUI

/// Middle tab. Unified feed of what the household just did + what's coming.
/// Replaces the old `FutureView` tab.
struct ActivityView: View {
    @Environment(AppStore.self) private var store

    private struct Upcoming: Identifiable {
        var id: Date { day }
        let day: Date
        let items: [Occurrence]
    }

    private var recentCompletions: [Occurrence] {
        store.occurrences
            .filter { $0.completedAt != nil }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
            .prefix(30)
            .map { $0 }
    }

    private var upcomingGroups: [Upcoming] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: store.futureOccurrences()) {
            cal.startOfDay(for: $0.dueDate)
        }
        return grouped
            .map { Upcoming(day: $0.key, items: $0.value.sorted(by: { $0.dueDate < $1.dueDate })) }
            .sorted { $0.day < $1.day }
            .prefix(14)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.xl, pinnedViews: [.sectionHeaders]) {
                    if !upcomingGroups.isEmpty {
                        Section {
                            VStack(spacing: Spacing.md) {
                                ForEach(upcomingGroups) { group in
                                    VStack(alignment: .leading, spacing: Spacing.sm) {
                                        dayHeader(group.day)
                                        ForEach(group.items) { occ in
                                            upcomingRow(occ)
                                        }
                                    }
                                    .padding(.horizontal, Spacing.lg)
                                }
                            }
                            .padding(.vertical, Spacing.md)
                        } header: {
                            sectionHeader(Copy.Activity.upcomingHeader, systemImage: "calendar")
                        }
                    }

                    Section {
                        if recentCompletions.isEmpty {
                            EmptyStateView(
                                title: Copy.Activity.emptyTitle,
                                message: Copy.Activity.emptySubtitle,
                                systemImage: "sparkle.magnifyingglass",
                                tint: CardPalette.teal.primary
                            )
                            .frame(minHeight: 240)
                            .padding(.horizontal, Spacing.lg)
                        } else {
                            VStack(spacing: Spacing.sm) {
                                ForEach(recentCompletions) { occ in
                                    feedRow(occ)
                                        .padding(.horizontal, Spacing.lg)
                                }
                            }
                        }
                    } header: {
                        sectionHeader(Copy.Activity.recentHeader, systemImage: "flame.fill")
                    }
                }
                .padding(.bottom, Spacing.huge)
            }
            .scrollContentBackground(.hidden)
            .background(backdrop.ignoresSafeArea())
            .navigationTitle(Copy.Activity.navTitle)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: DayScene.current().backgroundStops(),
            startPoint: .top, endPoint: .bottom
        )
    }

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.ink)
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.ink)
            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
    }

    private func dayHeader(_ day: Date) -> some View {
        HStack {
            Text(Self.relativeLabel(for: day))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.ink)
            Spacer()
            Text(Self.dateFmt.string(from: day))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.inkSoft)
        }
    }

    private func upcomingRow(_ occ: Occurrence) -> some View {
        let cat = store.category(occ.categoryID)
        let member = store.member(occ.assigneeID)
        return HStack(spacing: Spacing.md) {
            timeCapsule(occ.dueDate)
            VStack(alignment: .leading, spacing: 2) {
                Text(occ.title).font(.body.weight(.semibold)).foregroundStyle(Color.ink)
                HStack(spacing: Spacing.sm) {
                    if let cat {
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
            if let member {
                AvatarView(emoji: member.emoji, tint: member.tint, size: 28)
            }
        }
        .padding(Spacing.md)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(Color.ink.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func feedRow(_ occ: Occurrence) -> some View {
        let member = store.member(occ.completedByID)
        let cat = store.category(occ.categoryID)
        let name = member?.name.components(separatedBy: " ").first ?? "Someone"
        return HStack(alignment: .center, spacing: Spacing.md) {
            if let member {
                AvatarView(emoji: member.emoji, tint: member.tint, size: 36)
            } else {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                    .frame(width: 36, height: 36)
                    .background(.green.opacity(0.15), in: Circle())
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(Copy.Activity.completedBy(name, occ.title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.ink)
                HStack(spacing: 6) {
                    if let cat {
                        Text(cat.name)
                            .font(.caption)
                            .foregroundStyle(cat.tint)
                    }
                    if let at = occ.completedAt {
                        Text(Self.relativeAgo(at))
                            .font(.caption)
                            .foregroundStyle(Color.inkSoft)
                    }
                }
            }
            Spacer(minLength: 0)
            Text(Copy.Completion.karmaDelta(occ.effort.points))
                .font(.footnote.weight(.bold).monospacedDigit())
                .foregroundStyle(.yellow)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(.yellow.opacity(0.15), in: Capsule())
        }
        .padding(Spacing.md)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(Color.ink.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func timeCapsule(_ date: Date) -> some View {
        Text(Self.timeFmt.string(from: date))
            .font(.caption.weight(.bold).monospacedDigit())
            .foregroundStyle(Color.ink)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 6)
            .background(Color.ink.opacity(0.08), in: Capsule())
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

    private static func relativeAgo(_ date: Date) -> String {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .short
        return fmt.localizedString(for: date, relativeTo: .now)
    }

    private static let dateFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "d MMM"; return f }()
    private static let timeFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm"; return f }()
}
