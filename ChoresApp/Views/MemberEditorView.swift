import SwiftUI

struct MemberEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let existing: Member?

    @State private var name: String
    @State private var emoji: String
    @State private var tintHex: String

    private let emojis = ["🦊", "🐻", "🐼", "🦁", "🐨", "🐸", "🐙", "🐯", "🦉", "🐶", "🐱", "🐰", "🦄", "🐵", "🐢", "🦒"]

    init(existing: Member? = nil) {
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _emoji = State(initialValue: existing?.emoji ?? "🦊")
        _tintHex = State(initialValue: existing?.tintHex ?? Palette.swatches.randomElement() ?? "#4ECDC4")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Alex", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Avatar") {
                    HStack {
                        AvatarView(emoji: emoji, tint: Color(hex: tintHex), size: 60)
                        Spacer()
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(emojis, id: \.self) { e in
                            Button {
                                Haptics.selection()
                                withAnimation(Motion.responsive) { emoji = e }
                            } label: {
                                Text(e)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle().fill(emoji == e ? Color.accentColor.opacity(0.25) : .clear)
                                    )
                                    .overlay(Circle().strokeBorder(emoji == e ? Color.accentColor : .clear, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(emoji == e ? 1.08 : 1)
                            .animation(Motion.playful, value: emoji)
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
                                    .shadow(color: Color(hex: hex).opacity(0.55), radius: tintHex == hex ? 8 : 0)
                                    .scaleEffect(tintHex == hex ? 1.15 : 1)
                            }
                            .buttonStyle(.plain)
                            .animation(Motion.playful, value: tintHex)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let existing, existing.id != store.currentMemberID {
                    Section {
                        Button(role: .destructive) {
                            withAnimation(Motion.standard) {
                                store.deleteMember(existing.id)
                            }
                            dismiss()
                        } label: {
                            Label("Remove member", systemImage: "person.fill.xmark")
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add member" : "Edit member")
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
        if let existing {
            var updated = existing
            updated.name = name.trimmingCharacters(in: .whitespaces)
            updated.emoji = emoji
            updated.tintHex = tintHex
            store.updateMember(updated)
        } else {
            store.addMember(
                name: name.trimmingCharacters(in: .whitespaces),
                emoji: emoji,
                tintHex: tintHex
            )
        }
        dismiss()
    }
}
