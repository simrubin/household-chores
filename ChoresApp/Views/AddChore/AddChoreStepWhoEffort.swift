import SwiftUI

/// Step 3 — "How heavy, and who's on it?"
/// Effort as 5 full-width horizontal cards; assignee as a carousel.
struct AddChoreStepWhoEffort: View {
    @Binding var effort: EffortLevel
    @Binding var assigneeID: UUID?
    let members: [Member]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Text(Copy.Wizard.whoEffortTitle)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .padding(.top, Spacing.lg)

                // Effort
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(Copy.Wizard.effortHeading)
                        .font(.headline)
                        .foregroundStyle(Color.ink)

                    VStack(spacing: Spacing.sm) {
                        ForEach(EffortLevel.allCases) { level in
                            effortRow(level)
                        }
                    }
                }

                // Who
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(Copy.Wizard.whoHeading)
                        .font(.headline)
                        .foregroundStyle(Color.ink)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.md) {
                            openPoolTile
                            ForEach(members) { m in
                                assigneeTile(m)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.huge)
        }
    }

    private func effortRow(_ level: EffortLevel) -> some View {
        let selected = level == effort
        return Button {
            Haptics.selection()
            withAnimation(Motion.playful) { effort = level }
        } label: {
            HStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(selected ? level.tint.gradient : Color.ink.opacity(0.07).gradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: level.symbolName)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(selected ? .white : level.tint)
                        .symbolEffect(.bounce, value: selected)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.label)
                        .font(.headline)
                        .foregroundStyle(selected ? .white : Color.ink)
                    Text("~\(level.estimatedMinutes) min")
                        .font(.caption)
                        .foregroundStyle(selected ? Color.white.opacity(0.85) : Color.inkSoft)
                }
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .imageScale(.small)
                    Text("\(level.points)")
                        .font(.headline.monospacedDigit())
                }
                .foregroundStyle(selected ? .white : Color.ink)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .fill(level.tint.gradient)
                        .shadow(color: level.tint.opacity(0.4), radius: 10, y: 5)
                } else {
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .fill(Color.ink.opacity(0.05))
                }
            }
            .scaleEffect(selected ? 1.01 : 1)
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.98)
        .animation(Motion.playful, value: selected)
        .accessibilityLabel("\(level.label), \(level.points) karma")
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }

    private var openPoolTile: some View {
        let selected = assigneeID == nil
        return Button {
            Haptics.selection()
            withAnimation(Motion.responsive) { assigneeID = nil }
        } label: {
            VStack(spacing: Spacing.sm) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.ink.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        .background(Circle().fill(selected ? Color.ink.opacity(0.08) : .clear))
                        .frame(width: 64, height: 64)
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundStyle(Color.ink.opacity(0.6))
                }
                Text(Copy.Wizard.whoOpen)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(selected ? Color.ink.opacity(0.08) : .clear)
            )
            .scaleEffect(selected ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .animation(Motion.playful, value: selected)
    }

    private func assigneeTile(_ member: Member) -> some View {
        let selected = member.id == assigneeID
        return Button {
            Haptics.selection()
            withAnimation(Motion.playful) { assigneeID = member.id }
        } label: {
            VStack(spacing: Spacing.sm) {
                AvatarView(emoji: member.emoji, tint: member.tint, size: 64)
                    .overlay(
                        Circle().strokeBorder(selected ? Color.ink : .clear, lineWidth: 3)
                    )
                Text(member.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)
                    .frame(width: 80)
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(selected ? member.tint.opacity(0.18) : .clear)
            )
            .scaleEffect(selected ? 1.05 : 1)
        }
        .buttonStyle(.plain)
        .animation(Motion.playful, value: selected)
        .accessibilityLabel(member.name)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}
