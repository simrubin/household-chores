import SwiftUI

struct OnboardingView: View {
    @Environment(AppStore.self) private var store

    @State private var step: Step = .welcome
    @State private var householdName: String = ""
    @State private var memberName: String = ""
    @State private var memberEmoji: String = "🦊"
    @State private var memberTint: String = Palette.swatches[4]
    @State private var animateHero = false

    private enum Step: Int, CaseIterable { case welcome, household, you }

    private let emojis = ["🦊", "🐻", "🐼", "🦁", "🐨", "🐸", "🐙", "🐯", "🦉", "🐶", "🐱", "🦊"]

    var body: some View {
        ZStack {
            gradient
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                header
                    .padding(.top, Spacing.huge)

                Spacer(minLength: 0)

                card
                    .padding(.horizontal, Spacing.lg)

                Spacer(minLength: 0)

                footerCTA
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
            }
        }
        .onAppear { animateHero = true }
    }

    private var gradient: some View {
        LinearGradient(
            colors: [
                Color(hex: "#4D96FF").opacity(0.35),
                Color(hex: "#A06CD5").opacity(0.25),
                Color(hex: "#F58FBA").opacity(0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "house.lodge.fill")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(.white)
                .symbolEffect(.bounce, value: animateHero)
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)

            Text("Chores, together.")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)

            Text("Fair effort · gentle reminders · better days")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Spacing.lg)
    }

    @ViewBuilder
    private var card: some View {
        switch step {
        case .welcome: welcomeCard
        case .household: householdCard
        case .you: memberCard
        }
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            featureRow(icon: "scalemass", tint: .blue, title: "Balanced effort", detail: "Points reward real work, not just checkmarks.")
            featureRow(icon: "bell.badge", tint: .orange, title: "Timely reminders", detail: "Recurring notifications you actually want.")
            featureRow(icon: "wand.and.stars", tint: .purple, title: "Mood-friendly", detail: "Reshuffle tasks when you're low-energy or busy.")
        }
        .padding(Spacing.xl)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .transition(.asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
    }

    private func featureRow(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint.gradient)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var householdCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Label("Name your household", systemImage: "house.fill")
                .font(.headline)

            TextField("e.g. The Burrow", text: $householdName)
                .textInputAutocapitalization(.words)
                .textFieldStyle(.plain)
                .padding(Spacing.md)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))

            Text("You can add more members later.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(Spacing.xl)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .transition(.asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
    }

    private var memberCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Label("Who are you?", systemImage: "person.crop.circle")
                .font(.headline)

            HStack(alignment: .center, spacing: Spacing.md) {
                AvatarView(emoji: memberEmoji, tint: Color(hex: memberTint), size: 56)
                TextField("Your name", text: $memberName)
                    .textInputAutocapitalization(.words)
                    .textFieldStyle(.plain)
                    .lineLimit(1)
                    // Without `minWidth: 0`, the field’s intrinsic width can push past the screen edge in an HStack.
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Avatar").font(.caption).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(emojis.indices, id: \.self) { i in
                            let e = emojis[i]
                            Button {
                                Haptics.selection()
                                withAnimation(Motion.responsive) { memberEmoji = e }
                            } label: {
                                Text(e).font(.title2).frame(width: 40, height: 40)
                                    .background(
                                        Circle().fill(memberEmoji == e ? Color.accentColor.opacity(0.25) : .clear)
                                    )
                                    .overlay(
                                        Circle().strokeBorder(memberEmoji == e ? Color.accentColor : .clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Color").font(.caption).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(Palette.swatches, id: \.self) { hex in
                            Button {
                                Haptics.selection()
                                withAnimation(Motion.responsive) { memberTint = hex }
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle().strokeBorder(.white, lineWidth: memberTint == hex ? 3 : 0)
                                    )
                                    .shadow(color: Color(hex: hex).opacity(0.5), radius: memberTint == hex ? 6 : 0)
                                    .scaleEffect(memberTint == hex ? 1.12 : 1)
                                    .animation(Motion.playful, value: memberTint)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .transition(.asymmetric(insertion: .push(from: .trailing), removal: .push(from: .leading)))
    }

    private var footerCTA: some View {
        HStack(spacing: Spacing.md) {
            if step != .welcome {
                Button {
                    Haptics.tap()
                    withAnimation(Motion.standard) {
                        step = Step(rawValue: step.rawValue - 1) ?? .welcome
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .labelStyle(.titleOnly)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
            }

            Button {
                advance()
            } label: {
                Label(ctaTitle, systemImage: ctaIcon)
                    .frame(maxWidth: .infinity)
                    .font(.headline)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(!canAdvance)
            .sensoryFeedback(.success, trigger: step == .you && canAdvance)
        }
    }

    private var ctaTitle: String {
        switch step {
        case .welcome: "Get started"
        case .household: "Continue"
        case .you: "Create household"
        }
    }

    private var ctaIcon: String {
        step == .you ? "sparkles" : "arrow.right"
    }

    private var canAdvance: Bool {
        switch step {
        case .welcome: true
        case .household: !householdName.trimmed.isEmpty
        case .you: !memberName.trimmed.isEmpty
        }
    }

    private func advance() {
        Haptics.tap(.medium)
        switch step {
        case .welcome:
            withAnimation(Motion.standard) { step = .household }
        case .household:
            withAnimation(Motion.standard) { step = .you }
        case .you:
            let me = Member(name: memberName.trimmed, emoji: memberEmoji, tintHex: memberTint, isAdmin: true)
            withAnimation(Motion.hero) {
                store.bootstrap(householdName: householdName.trimmed, firstMember: me)
            }
            Haptics.success()
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
