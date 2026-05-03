import SwiftUI

/// Step 1 — "What's the chore?"
/// Giant text field with rotating placeholder + big category tile grid.
struct AddChoreStepWhat: View {
    @Binding var title: String
    @Binding var categoryID: UUID?
    let categories: [Category]
    let placeholderIndex: Int

    @FocusState private var isTitleFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Text(Copy.Wizard.whatTitle)
                    .font(.system(.largeTitle, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .padding(.top, Spacing.lg)

                // Giant text field
                BareTextField(
                    text: $title,
                    placeholder: Copy.Wizard.whatFieldPlaceholders[placeholderIndex],
                    font: .system(.title, weight: .semibold),
                    autocapitalize: .sentences,
                    axis: .vertical
                )
                .focused($isTitleFocused)
                .padding(Spacing.lg)

                // Category heading + grid
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text(Copy.Wizard.whatCategoryHeading)
                        .font(.headline)
                        .foregroundStyle(Color.ink)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: Spacing.md), GridItem(.flexible(), spacing: Spacing.md)],
                        spacing: Spacing.md
                    ) {
                        ForEach(categories) { cat in
                            categoryTile(cat)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.huge)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func categoryTile(_ cat: Category) -> some View {
        let selected = cat.id == categoryID
        return Button {
            Haptics.selection()
            withAnimation(Motion.playful) { categoryID = cat.id }
        } label: {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Image(systemName: cat.symbolName)
                    .font(.title)
                    .foregroundStyle(selected ? .white : cat.tint)
                    .symbolEffect(.bounce, value: selected)
                Text(cat.name)
                    .font(.headline)
                    .foregroundStyle(selected ? .white : Color.ink)
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .padding(Spacing.lg)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .fill(cat.tint)
                        .shadow(color: cat.tint.opacity(0.18), radius: 6, y: 3)
                } else {
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .fill(cat.tint.opacity(0.12))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                    .strokeBorder(selected ? Color.white.opacity(0.25) : cat.tint.opacity(0.25), lineWidth: 1)
            )
            .scaleEffect(selected ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.97)
        .animation(Motion.playful, value: selected)
        .accessibilityLabel(cat.name)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}
