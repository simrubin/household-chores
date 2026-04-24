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
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .padding(.top, Spacing.lg)

                // Giant text field
                ZStack(alignment: .leading) {
                    if title.isEmpty {
                        Text(Copy.Wizard.whatFieldPlaceholders[placeholderIndex])
                            .font(.system(.title, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.inkSoft.opacity(0.6))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .id(placeholderIndex)
                    }
                    TextField("", text: $title, axis: .vertical)
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.ink)
                        .textInputAutocapitalization(.sentences)
                        .tint(Color.ink)
                        .focused($isTitleFocused)
                        .lineLimit(1...3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.lg)
                .background(Color.surface, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                        .strokeBorder(Color.ink.opacity(isTitleFocused ? 0.25 : 0.08), lineWidth: isTitleFocused ? 2 : 1)
                )
                .animation(Motion.responsive, value: isTitleFocused)

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
                        .fill(cat.tint.gradient)
                        .shadow(color: cat.tint.opacity(0.4), radius: 12, y: 6)
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
