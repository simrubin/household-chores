import SwiftUI

struct OccurrenceRow: View {
    let occurrence: Occurrence
    let category: Category?
    let assignee: Member?
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var isCompleting = false
    @State private var dragOffset: CGFloat = 0

    private var overdue: Bool {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        return occurrence.dueDate < startOfToday
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            checkmarkButton
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 6) {
                Text(occurrence.title)
                    .font(.headline)
                    .strikethrough(isCompleting || occurrence.isCompleted, color: .secondary)
                    .foregroundStyle(isCompleting ? .secondary : .primary)
                    .lineLimit(2)

                HStack(spacing: Spacing.sm) {
                    if let category {
                        categoryPill(category)
                    }
                    EffortBadge(effort: occurrence.effort, compact: true)
                    if overdue {
                        Label(Copy.Activity.wasYesterday, systemImage: "clock.badge.exclamationmark")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer(minLength: 0)

            if let assignee {
                AvatarView(emoji: assignee.emoji, tint: assignee.tint, size: 32)
            } else {
                Image(systemName: "person.2.badge.plus")
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(.white.opacity(0.08), in: Circle())
                    .accessibilityLabel(Copy.Wizard.whoOpen)
            }
        }
        .padding(Spacing.lg)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                .strokeBorder(.white.opacity(0.06), lineWidth: 0.5)
        )
        .offset(x: dragOffset)
        .scaleEffect(isCompleting ? 0.97 : 1)
        .opacity(isCompleting ? 0.7 : 1)
        .gesture(swipeGesture)
        .animation(Motion.responsive, value: dragOffset)
        .animation(Motion.standard, value: isCompleting)
        .contextMenu {
            Button(Copy.Hub.doItNowPrimary, systemImage: "checkmark.circle.fill", action: triggerComplete)
            Button(Copy.Common.skipToday, systemImage: "forward.end", action: onSkip)
        }
        .sensoryFeedback(.success, trigger: isCompleting)
    }

    private var checkmarkButton: some View {
        Button(action: triggerComplete) {
            ZStack {
                Circle()
                    .strokeBorder(.secondary, lineWidth: 1.5)
                    .frame(width: 28, height: 28)

                if isCompleting {
                    Circle()
                        .fill(occurrence.effort.tint.gradient)
                        .frame(width: 28, height: 28)
                        .transition(.scale.combined(with: .opacity))

                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                        .symbolEffect(.bounce, value: isCompleting)
                }
            }
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Copy.Hub.doItNowPrimary) \(occurrence.title)")
    }

    private func categoryPill(_ cat: Category) -> some View {
        HStack(spacing: 4) {
            Image(systemName: cat.symbolName)
                .imageScale(.small)
            Text(cat.name)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(cat.tint)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 3)
        .background(cat.tint.opacity(0.14), in: Capsule())
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged { value in
                // Rubber-band when dragging right, resistive both ways.
                let raw = value.translation.width
                dragOffset = raw.magnitude > 120 ? raw.clamped(to: -120...120) : raw
            }
            .onEnded { value in
                let threshold: CGFloat = 80
                if value.translation.width > threshold {
                    triggerComplete()
                } else if value.translation.width < -threshold {
                    onSkip()
                }
                dragOffset = 0
            }
    }

    private func triggerComplete() {
        guard !isCompleting else { return }
        withAnimation(Motion.playful) { isCompleting = true }
        // Small delay so the user sees the satisfying tick before the row leaves.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onComplete()
        }
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
