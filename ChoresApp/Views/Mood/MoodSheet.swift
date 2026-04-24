import SwiftUI

/// Full-bleed mood picker. Drenched in the palette for the selected mood;
/// the card that launched it seeds the entry transition via `namespace`.
struct MoodSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let namespace: Namespace.ID

    @State private var hoveredRow: Int? = nil
    @State private var showAvoidPicker = false
    @State private var pendingConfirm: MoodPreset? = nil

    private var memberID: UUID? { store.currentMember?.id }
    private var currentMood: MoodPreset {
        guard let id = memberID else { return .none }
        return store.mood(for: id)
    }
    private var palette: CardPalette {
        CardPalette.palette(for: pendingConfirm ?? currentMood)
    }

    private struct Option: Identifiable {
        let id: Int
        let preset: MoodPreset
        let title: String
        let subtitle: String
        let symbol: String
        let palette: CardPalette
    }

    private var options: [Option] {
        [
            Option(id: 0, preset: .lowEnergy, title: Copy.Mood.tiredTitle, subtitle: Copy.Mood.tiredSubtitle, symbol: "moon.zzz.fill", palette: .indigo),
            Option(id: 1, preset: .quickOnly, title: Copy.Mood.rushingTitle, subtitle: Copy.Mood.rushingSubtitle, symbol: "bolt.fill", palette: .amber),
            // Avoid is a tile that opens a category picker.
            Option(id: 2, preset: .avoid(UUID()), title: Copy.Mood.skipTitle, subtitle: Copy.Mood.skipSubtitle, symbol: "nosign", palette: .coral),
            Option(id: 3, preset: .none, title: Copy.Mood.bringItTitle, subtitle: Copy.Mood.bringItSubtitle, symbol: "sparkles", palette: .teal),
        ]
    }

    var body: some View {
        ZStack {
            palette.surface
                .opacity(0.35)
                .ignoresSafeArea()
                .matchedGeometryEffect(id: "mood-card-surface", in: namespace, isSource: false)
                .animation(Motion.hero, value: palette)

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        ForEach(options) { opt in
                            moodRow(opt)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xl)
                    .padding(.bottom, Spacing.huge)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .sheet(isPresented: $showAvoidPicker) {
            AvoidCategoryPicker(categories: store.categories) { cat in
                showAvoidPicker = false
                commit(.avoid(cat.id))
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(Copy.Mood.sheetTitle)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.ink)
                Text(Copy.Hub.moodSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.inkSoft)
            }
            Spacer()
            Button {
                Haptics.tap(.soft)
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(palette.ink)
                    .frame(width: 40, height: 40)
                    .background(palette.tintedNeutral, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Copy.Mood.dismiss)
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func moodRow(_ opt: Option) -> some View {
        let isCurrent: Bool = {
            switch (opt.preset, currentMood) {
            case (.lowEnergy, .lowEnergy), (.quickOnly, .quickOnly), (.none, .none): return true
            case (.avoid, .avoid): return true
            default: return false
            }
        }()

        Button {
            select(opt)
        } label: {
            HStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(opt.palette.primary.gradient)
                        .frame(width: 58, height: 58)
                        .shadow(color: opt.palette.glow, radius: 10, y: 4)
                    Image(systemName: opt.symbol)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: hoveredRow == opt.id)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(opt.title)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(opt.palette.ink)
                    Text(opt.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(opt.palette.inkSoft)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: isCurrent ? "checkmark.circle.fill" : "chevron.right")
                    .font(.headline)
                    .foregroundStyle(isCurrent ? opt.palette.primary : opt.palette.ink.opacity(0.35))
            }
            .padding(Spacing.lg)
            .frame(minHeight: 96)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(opt.palette.surface.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
            )
            .shadow(color: opt.palette.glow.opacity(0.5), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .pressable(scale: 0.98)
        .accessibilityLabel("\(opt.title). \(opt.subtitle)")
        .accessibilityAddTraits(isCurrent ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Actions

    private func select(_ opt: Option) {
        Haptics.tap(.medium)
        if case .avoid = opt.preset {
            showAvoidPicker = true
            return
        }
        commit(opt.preset)
    }

    private func commit(_ preset: MoodPreset) {
        guard let id = memberID else { return }
        Haptics.success()
        withAnimation(Motion.hero) {
            pendingConfirm = preset
            store.setMood(preset, for: id)
        }
        // Auto-dismiss after the scene change breathes.
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.15 : 0.55)) {
            dismiss()
        }
    }
}

// MARK: - Avoid category picker

/// Secondary sheet shown when the user picks "Skip something" in the mood sheet.
struct AvoidCategoryPicker: View {
    let categories: [Category]
    let onPick: (Category) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section(Copy.Mood.avoidSheetTitle) {
                    ForEach(categories) { cat in
                        Button {
                            Haptics.selection()
                            onPick(cat)
                        } label: {
                            HStack(spacing: Spacing.md) {
                                Image(systemName: cat.symbolName)
                                    .foregroundStyle(cat.tint)
                                    .frame(width: 28, height: 28)
                                    .background(cat.tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                                Text(cat.name)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Skip a category")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
