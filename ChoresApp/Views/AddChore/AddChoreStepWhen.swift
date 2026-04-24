import SwiftUI

/// Step 2 — "When should it happen?"
/// 4 giant recurrence tiles; "Some days" reveals a weekday strip.
/// Time picker framed warmly: "We'll buzz at 9:00 AM".
struct AddChoreStepWhen: View {
    @Binding var recurrenceMode: AddChoreWizardView.RecurrenceMode
    @Binding var weekdays: Set<Int>
    @Binding var reminderTime: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Text(Copy.Wizard.whenTitle)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .padding(.top, Spacing.lg)

                // Recurrence tiles
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: Spacing.md), GridItem(.flexible(), spacing: Spacing.md)],
                    spacing: Spacing.md
                ) {
                    ForEach(AddChoreWizardView.RecurrenceMode.allCases) { mode in
                        recurrenceTile(mode)
                    }
                }

                if recurrenceMode == .someDays {
                    weekdayStrip
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Time picker
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(Copy.Wizard.whenTimeHeading)
                        .font(.headline)
                        .foregroundStyle(Color.ink)

                    HStack {
                        DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        Spacer()
                    }
                    .padding(.vertical, Spacing.sm)

                    Text(Copy.Wizard.whenTimePreview(Self.preview(reminderTime)))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.inkSoft)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, 6)
                        .background(Color.ink.opacity(0.08), in: Capsule())
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.huge)
            .animation(Motion.standard, value: recurrenceMode)
        }
    }

    private func recurrenceTile(_ mode: AddChoreWizardView.RecurrenceMode) -> some View {
        let selected = mode == recurrenceMode
        return Button {
            Haptics.selection()
            withAnimation(Motion.playful) { recurrenceMode = mode }
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Image(systemName: mode.symbol)
                    .font(.title)
                    .foregroundStyle(selected ? .white : Color.ink)
                    .symbolEffect(.bounce, value: selected)
                Text(mode.label)
                    .font(.headline)
                    .foregroundStyle(selected ? .white : Color.ink)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .padding(Spacing.lg)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .fill(Color.ink.gradient)
                        .shadow(color: Color.ink.opacity(0.3), radius: 10, y: 5)
                } else {
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .fill(Color.ink.opacity(0.07))
                }
            }
            .scaleEffect(selected ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.97)
        .animation(Motion.playful, value: selected)
    }

    private var weekdayStrip: some View {
        HStack(spacing: 6) {
            ForEach(1...7, id: \.self) { day in
                let active = weekdays.contains(day)
                Button {
                    Haptics.selection()
                    withAnimation(Motion.responsive) {
                        if active { weekdays.remove(day) } else { weekdays.insert(day) }
                    }
                } label: {
                    Text(RecurrenceKind.dayShortName(day).prefix(1))
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(active ? .white : Color.ink)
                        .background(
                            Capsule().fill(active ? Color.ink.gradient : Color.ink.opacity(0.07).gradient)
                        )
                        .scaleEffect(active ? 1.05 : 1)
                }
                .buttonStyle(.plain)
                .animation(Motion.playful, value: active)
            }
        }
    }

    private static func preview(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}
