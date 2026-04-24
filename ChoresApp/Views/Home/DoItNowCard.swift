import SwiftUI

/// Amber "Do it now" card — the hub's primary call to action.
/// Shows the top unblocked task, a 56pt Done button that triggers the
/// Completion moment, and drills into the full day list on content tap.
struct DoItNowCard: View {
    let nextTask: Occurrence?
    let category: Category?
    let remainingCount: Int
    let onDone: () -> Void
    let onDrill: () -> Void
    let onAdd: () -> Void

    private let palette: CardPalette = .amber

    var body: some View {
        HubCard(palette: palette, minHeight: 200) {
            if let task = nextTask {
                taskContent(task)
            } else {
                emptyContent
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(voLabel)
    }

    // MARK: - States

    @ViewBuilder
    private func taskContent(_ task: Occurrence) -> some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HubTapArea(action: onDrill) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HubKicker(text: Copy.Hub.doItNowTitle, palette: palette, symbol: "bolt.fill")

                    Text(task.title)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(palette.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .contentTransition(.interpolate)

                    HStack(spacing: Spacing.sm) {
                        if let category {
                            HStack(spacing: 4) {
                                Image(systemName: category.symbolName)
                                    .imageScale(.small)
                                Text(category.name)
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(palette.ink.opacity(0.75))
                        }
                        effortChip(task.effort)
                    }

                    Text(Copy.Hub.doItNowMore(remainingCount))
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(palette.inkSoft)
                        .contentTransition(.numericText(value: Double(remainingCount)))
                }
            }

            HubPrimaryButton(
                title: Copy.Hub.doItNowPrimary,
                systemImage: "checkmark",
                palette: palette,
                action: onDone
            )
        }
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HubKicker(text: Copy.Hub.doItNowEmptyTitle, palette: palette, symbol: "sparkles")
                Text("Nothing's on")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.ink)
                HubSubtitle(text: Copy.Hub.doItNowEmptySubtitle, palette: palette)
            }
            HubPrimaryButton(
                title: Copy.Hub.addChoreTitle,
                systemImage: "plus",
                palette: palette,
                action: onAdd
            )
        }
    }

    private func effortChip(_ effort: EffortLevel) -> some View {
        HStack(spacing: 4) {
            Image(systemName: effort.symbolName)
                .imageScale(.small)
            Text("\(effort.estimatedMinutes) min")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(palette.ink)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 4)
        .background(palette.tintedNeutral, in: Capsule())
    }

    private var voLabel: String {
        if let task = nextTask {
            return "\(Copy.Hub.doItNowTitle). Next: \(task.title). \(Copy.Hub.doItNowMore(remainingCount))."
        }
        return Copy.Hub.doItNowEmptySubtitle
    }
}
