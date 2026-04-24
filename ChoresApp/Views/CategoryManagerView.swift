import SwiftUI

struct CategoryManagerView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var editing: Category?
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.categories) { cat in
                        Button {
                            editing = cat
                        } label: {
                            categoryRow(cat)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editing = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                CategoryEditorSheet(existing: nil)
            }
            .sheet(item: $editing) { cat in
                CategoryEditorSheet(existing: cat)
            }
        }
    }

    private func categoryRow(_ cat: Category) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: cat.symbolName)
                .foregroundStyle(cat.tint)
                .frame(width: 36, height: 36)
                .background(cat.tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                .symbolEffect(.bounce, value: cat.id)
            Text(cat.name)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Editor sheet

struct CategoryEditorSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let existing: Category?

    @State private var name: String
    @State private var symbolName: String
    @State private var tintHex: String

    private let symbols: [String] = [
        "sparkles", "fork.knife", "tshirt", "bag", "pawprint", "tray.full",
        "cart", "leaf", "drop", "wrench.and.screwdriver", "trash", "bed.double",
        "cup.and.saucer", "car", "book", "hammer", "bubbles.and.sparkles", "basket"
    ]

    init(existing: Category?) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _symbolName = State(initialValue: existing?.symbolName ?? "sparkles")
        _tintHex = State(initialValue: existing?.tintHex ?? Palette.swatches.randomElement() ?? "#4ECDC4")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Garden", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], spacing: 10) {
                        ForEach(symbols, id: \.self) { s in
                            Button {
                                Haptics.selection()
                                withAnimation(Motion.responsive) { symbolName = s }
                            } label: {
                                Image(systemName: s)
                                    .font(.title3)
                                    .foregroundStyle(symbolName == s ? Color(hex: tintHex) : .secondary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(symbolName == s ? Color(hex: tintHex).opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(symbolName == s ? Color(hex: tintHex) : .clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(symbolName == s ? 1.08 : 1)
                            .animation(Motion.playful, value: symbolName)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Colour") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 12) {
                        ForEach(Palette.swatches, id: \.self) { hex in
                            Button {
                                Haptics.selection()
                                withAnimation(Motion.playful) { tintHex = hex }
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().strokeBorder(.white, lineWidth: tintHex == hex ? 3 : 0))
                                    .scaleEffect(tintHex == hex ? 1.15 : 1)
                            }
                            .buttonStyle(.plain)
                            .animation(Motion.playful, value: tintHex)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let existing, store.categories.count > 1 {
                    Section {
                        Button(role: .destructive) {
                            store.deleteCategory(existing.id, reassignTo: nil)
                            dismiss()
                        } label: {
                            Label("Delete category", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "New category" : "Edit category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .buttonStyle(.glassProminent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        Haptics.success()
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let existing {
            var updated = existing
            updated.name = trimmed
            updated.symbolName = symbolName
            updated.tintHex = tintHex
            store.updateCategory(updated)
        } else {
            store.addCategory(name: trimmed, symbolName: symbolName, tintHex: tintHex)
        }
        dismiss()
    }
}
