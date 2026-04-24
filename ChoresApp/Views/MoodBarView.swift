import SwiftUI

/// Floating pill-row of mood presets. Uses `GlassEffectContainer` so chips
/// morph into each other fluidly when selection changes (Liquid Glass).
struct MoodBarView: View {
    let mood: MoodPreset
    let categories: [Category]
    let namespace: Namespace.ID
    let onSelect: (MoodPreset) -> Void

    @State private var showAvoidPicker = false

    private var presets: [MoodPreset] {
        var all: [MoodPreset] = [.none, .lowEnergy, .quickOnly]
        if case .avoid = mood {
            all.append(mood) // keep chosen avoid chip visible
        }
        return all
    }

    var body: some View {
        GlassEffectContainer(spacing: Spacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(presets, id: \.id) { preset in
                        MoodChip(
                            preset: preset,
                            isActive: preset.id == mood.id,
                            categoryName: avoidCategoryName(for: preset),
                            namespace: namespace
                        ) {
                            onSelect(preset.id == mood.id ? .none : preset)
                        }
                    }

                    // "Avoid …" pill always present as entry point to category picker.
                    if !hasAvoidSelected {
                        Button {
                            Haptics.selection()
                            showAvoidPicker = true
                        } label: {
                            Label("Avoid…", systemImage: "nosign")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.glass)
                        .glassEffectID("avoid-opener", in: namespace)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, 4)
            }
        }
        .sheet(isPresented: $showAvoidPicker) {
            AvoidCategoryPicker(categories: categories) { cat in
                showAvoidPicker = false
                onSelect(.avoid(cat.id))
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var hasAvoidSelected: Bool {
        if case .avoid = mood { return true }
        return false
    }

    private func avoidCategoryName(for preset: MoodPreset) -> String? {
        if case .avoid(let id) = preset {
            return categories.first(where: { $0.id == id })?.name
        }
        return nil
    }
}

// MARK: - Mood chip

struct MoodChip: View {
    let preset: MoodPreset
    let isActive: Bool
    let categoryName: String?
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap(.soft)
            action()
        }) {
            HStack(spacing: 6) {
                Image(systemName: preset.symbolName)
                    .symbolEffect(.bounce, value: isActive)
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 10)
            .foregroundStyle(isActive ? .white : .primary)
        }
        .buttonStyle(.plain)
        .background {
            if isActive {
                Capsule().fill(tint.gradient)
                    .shadow(color: tint.opacity(0.45), radius: 10, y: 4)
            }
        }
        .glassEffect(isActive ? .clear : .regular, in: Capsule())
        .glassEffectID("mood-\(preset.id)", in: namespace)
        .overlay(
            Capsule().strokeBorder(isActive ? .white.opacity(0.25) : .white.opacity(0.06), lineWidth: 0.5)
        )
        .scaleEffect(isActive ? 1.03 : 1.0)
        .animation(Motion.playful, value: isActive)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private var label: String {
        if case .avoid = preset, let n = categoryName { return "No \(n)" }
        return preset.title
    }

    private var tint: Color {
        switch preset {
        case .none: return .accentColor
        case .lowEnergy: return .indigo
        case .quickOnly: return .orange
        case .avoid: return .pink
        }
    }
}

// MARK: - Avoid picker

struct AvoidCategoryPicker: View {
    let categories: [Category]
    let onPick: (Category) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Skip tasks from…") {
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
            .navigationTitle("Avoid category")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
