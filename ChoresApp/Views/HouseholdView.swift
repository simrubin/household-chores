import SwiftUI

/// Reached via `Me → The crew`. Members, categories, and household meta.
/// The balance chart moved to `BalanceDetailView` (hub drill-in) — this view
/// keeps the people + settings surfaces.
struct HouseholdView: View {
    @Environment(AppStore.self) private var store

    @State private var showMemberEditor = false
    @State private var editingMember: Member?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                membersCard
                settingsCard
            }
            .padding(Spacing.lg)
        }
        .scrollContentBackground(.hidden)
        .background(backdrop.ignoresSafeArea())
        .navigationTitle(Copy.Me.household)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showMemberEditor = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
                .buttonStyle(.glass)
                .accessibilityLabel("Add to the crew")
            }
        }
        .sheet(isPresented: $showMemberEditor) {
            MemberEditorView()
        }
        .sheet(item: $editingMember) { m in
            MemberEditorView(existing: m)
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: DayScene.current().backgroundStops(),
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: - Members

    private var membersCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Label("The crew", systemImage: "person.3.fill")
                    .font(.headline)
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("\(store.members.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.inkSoft)
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
                Label("Add someone", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
        .padding(Spacing.lg)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .strokeBorder(Color.ink.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func memberRow(_ member: Member) -> some View {
        let weekPoints: Int = {
            let now = Date.now
            let start = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            return store.points(for: member.id, in: DateInterval(start: start, end: now))
        }()

        return HStack(spacing: Spacing.md) {
            AvatarView(emoji: member.emoji, tint: member.tint, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(member.name).font(.body.weight(.semibold)).foregroundStyle(Color.ink)
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
                            .background(Color.ink, in: Capsule())
                    }
                }
                Text("\(weekPoints) karma this week")
                    .font(.caption)
                    .foregroundStyle(Color.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.ink.opacity(0.35))
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(Color.ink.opacity(0.04), in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    // MARK: - Settings

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Categories", systemImage: "tag")
                .font(.headline)
                .foregroundStyle(Color.ink)

            NavigationLink {
                CategoryManagerView()
            } label: {
                HStack {
                    Text("Manage categories")
                        .foregroundStyle(Color.ink)
                    Spacer()
                    Text("\(store.categories.count)")
                        .foregroundStyle(Color.inkSoft)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.ink.opacity(0.35))
                }
                .padding(Spacing.md)
                .background(Color.ink.opacity(0.04), in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .strokeBorder(Color.ink.opacity(0.06), lineWidth: 0.5)
        )
    }
}

// MARK: - Balance chart

/// Reusable bar-style chart. Used by `BalanceDetailView`.
struct BalanceChart: View {
    let data: [(member: Member, points: Int)]
    @State private var appeared = false

    private var maxPoints: Int {
        max(data.map(\.points).max() ?? 0, 1)
    }

    var body: some View {
        GeometryReader { geo in
            let count = max(data.count, 1)
            let barWidth = min((geo.size.width - CGFloat(count - 1) * Spacing.md) / CGFloat(count), 70)
            HStack(alignment: .bottom, spacing: Spacing.md) {
                ForEach(Array(data.enumerated()), id: \.element.member.id) { index, item in
                    VStack(spacing: Spacing.sm) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.ink.opacity(0.06))
                            RoundedRectangle(cornerRadius: 10)
                                .fill(item.member.tint.gradient)
                                .frame(height: appeared ? barHeight(for: item.points, available: geo.size.height - 60) : 0)
                                .shadow(color: item.member.tint.opacity(0.5), radius: 8, y: 3)
                                .animation(
                                    .spring(response: 0.55, dampingFraction: 0.82).delay(Double(index) * 0.04),
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
                            .foregroundStyle(Color.ink)
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
