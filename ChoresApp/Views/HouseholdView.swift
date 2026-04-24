import SwiftUI

struct HouseholdView: View {
    @Environment(AppStore.self) private var store

    @State private var window: BalanceWindow = .sevenDays
    @State private var showMemberEditor = false
    @State private var editingMember: Member?

    enum BalanceWindow: String, CaseIterable, Identifiable {
        case sevenDays = "7 days"
        case thirtyDays = "30 days"
        case allTime = "All time"
        var id: String { rawValue }
    }

    private var dateInterval: DateInterval {
        let now = Date.now
        switch window {
        case .sevenDays:
            return DateInterval(start: Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now, end: now)
        case .thirtyDays:
            return DateInterval(start: Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now, end: now)
        case .allTime:
            return DateInterval(start: .distantPast, end: now)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    balanceCard
                    membersCard
                    settingsCard
                }
                .padding(Spacing.lg)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(store.household.name.isEmpty ? "Household" : store.household.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showMemberEditor = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .buttonStyle(.glass)
                }
            }
            .sheet(isPresented: $showMemberEditor) {
                MemberEditorView()
            }
            .sheet(item: $editingMember) { m in
                MemberEditorView(existing: m)
            }
        }
    }

    // MARK: - Balance card

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Label("Effort balance", systemImage: "scalemass")
                    .font(.headline)
                Spacer()
                Picker("Window", selection: $window.animation(Motion.standard)) {
                    ForEach(BalanceWindow.allCases) { w in
                        Text(w.rawValue).tag(w)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }

            BalanceChart(data: store.householdPoints(in: dateInterval))
                .frame(height: 160)
                .animation(Motion.hero, value: window)
                .animation(Motion.hero, value: store.occurrences.count)
        }
        .padding(Spacing.lg)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
    }

    // MARK: - Members card

    private var membersCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("Members", systemImage: "person.3.fill")
                    .font(.headline)
                Spacer()
                Text("\(store.members.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: Spacing.sm) {
                ForEach(store.members) { member in
                    Button {
                        editingMember = member
                    } label: {
                        memberRow(member)
                    }
                    .buttonStyle(.plain)
                    .pressable()
                }
            }

            Button {
                showMemberEditor = true
            } label: {
                Label("Add member", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
        .padding(Spacing.lg)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
    }

    private func memberRow(_ member: Member) -> some View {
        HStack(spacing: Spacing.md) {
            AvatarView(emoji: member.emoji, tint: member.tint, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(member.name).font(.body.weight(.semibold))
                    if member.isAdmin {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                    if member.id == store.currentMemberID {
                        Text("you")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .foregroundStyle(.white)
                            .background(Color.accentColor.gradient, in: Capsule())
                    }
                }
                Text("\(store.points(for: member.id, in: dateInterval)) pts · \(window.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    // MARK: - Settings card

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Categories", systemImage: "tag")
                .font(.headline)

            NavigationLink {
                CategoryManagerView()
            } label: {
                HStack {
                    Text("Manage categories")
                    Spacer()
                    Text("\(store.categories.count)")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                }
                .padding(Spacing.md)
                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
    }
}

// MARK: - Balance chart (custom, avoids Charts dependency while staying animated)

struct BalanceChart: View {
    let data: [(member: Member, points: Int)]
    @State private var appeared = false

    private var maxPoints: Int {
        max(data.map(\.points).max() ?? 0, 1)
    }

    private var totalPoints: Int { data.reduce(0) { $0 + $1.points } }
    private var fairShare: Int { max(totalPoints / max(data.count, 1), 1) }

    var body: some View {
        GeometryReader { geo in
            let barWidth = min((geo.size.width - CGFloat(data.count - 1) * Spacing.md) / CGFloat(max(data.count, 1)), 70)
            HStack(alignment: .bottom, spacing: Spacing.md) {
                ForEach(Array(data.enumerated()), id: \.element.member.id) { index, item in
                    VStack(spacing: Spacing.sm) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white.opacity(0.06))
                            RoundedRectangle(cornerRadius: 10)
                                .fill(item.member.tint.gradient)
                                .frame(height: appeared ? barHeight(for: item.points, available: geo.size.height - 60) : 0)
                                .shadow(color: item.member.tint.opacity(0.5), radius: 8, y: 3)
                                .animation(
                                    .spring(response: 0.55, dampingFraction: 0.8).delay(Double(index) * 0.06),
                                    value: appeared
                                )
                                .animation(Motion.hero, value: item.points)

                            VStack(spacing: 2) {
                                Text("\(item.points)")
                                    .font(.caption.weight(.bold).monospacedDigit())
                                    .contentTransition(.numericText(value: Double(item.points)))
                                    .foregroundStyle(.white)
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .padding(.bottom, 6)
                            .opacity(item.points > 0 && appeared ? 1 : 0)
                        }
                        .frame(width: barWidth)

                        AvatarView(emoji: item.member.emoji, tint: item.member.tint, size: 28)
                        Text(item.member.name)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear { appeared = true }
    }

    private func barHeight(for points: Int, available: CGFloat) -> CGFloat {
        guard maxPoints > 0 else { return 0 }
        let ratio = CGFloat(points) / CGFloat(maxPoints)
        return max(available * ratio, points > 0 ? 8 : 0)
    }
}
