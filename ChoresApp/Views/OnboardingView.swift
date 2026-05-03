import SwiftUI

/// One question per screen. Prose and input share a single large font so the
/// whole screen reads as one continuous thought the user is completing.
struct OnboardingView: View {
    @Environment(AppStore.self) private var store

    @State private var step: Step = .welcome
    @State private var householdName: String = ""
    @State private var memberName: String = ""
    @State private var memberEmoji: String = "🦊"
    @State private var memberTint: String = Palette.swatches[4]
    @State private var inviteChoice: InviteChoice? = nil
    @State private var useStarters: Bool = true
    @State private var placeholderIndex = 0

    private enum Step: Int, CaseIterable {
        case welcome, home, you, invite, starters, done
    }

    private enum InviteChoice { case share, skip }

    private let palette: CardPalette = .petal
    private let emojis = ["🦊", "🐻", "🐼", "🦁", "🐨", "🐸", "🐙", "🐯", "🦉", "🐶", "🐱", "🐰"]
    private let homePlaceholders = ["The Burrow", "Apt 3B", "Flat 2", "Number 12", "Chez nous"]

    /// Single font shared by all prose AND the input field.
    private let f: Font = .system(size: 34, weight: .semibold, design: .rounded)

    var body: some View {
        ZStack(alignment: .topLeading) {
            palette.surfaceGradient.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                progressDots
                    .padding(.top, Spacing.lg)

                Spacer(minLength: Spacing.xl)

                content
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(step)

                Spacer(minLength: Spacing.xl)

                footerCTA
                    .padding(.bottom, Spacing.xl)
            }
            .padding(.horizontal, Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    // MARK: - Content routing

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome: welcomeScene
        case .home:    homeScene
        case .you:     youScene
        case .invite:  inviteScene
        case .starters: startersScene
        case .done:    doneScene
        }
    }

    // MARK: - Scenes

    private var welcomeScene: some View {
        Text(Copy.Onboarding.welcomeTitle)
            .font(f)
            .foregroundStyle(palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var homeScene: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(Copy.Onboarding.homePrompt)
                .font(f)
                .foregroundStyle(palette.ink)

            BareTextField(
                text: $householdName,
                placeholder: homePlaceholders[placeholderIndex],
                font: f,
                autocapitalize: .words
            )
            .onAppear { cyclePlaceholders() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var youScene: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(Copy.Onboarding.youPrompt)
                    .font(f)
                    .foregroundStyle(palette.ink)

                HStack(alignment: .center, spacing: Spacing.md) {
                    AvatarView(emoji: memberEmoji, tint: Color(hex: memberTint), size: 52)

                    BareTextField(
                        text: $memberName,
                        placeholder: Copy.Onboarding.youPlaceholder,
                        font: f,
                        autocapitalize: .words
                    )
                }
            }

            pickerLabel("Avatar")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(emojis, id: \.self) { e in
                        Button {
                            Haptics.selection()
                            withAnimation(Motion.responsive) { memberEmoji = e }
                        } label: {
                            Text(e)
                                .font(.system(size: 26))
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(
                                    memberEmoji == e ? palette.primary.opacity(0.22) : palette.tintedNeutral
                                ))
                                .overlay(Circle().strokeBorder(
                                    memberEmoji == e ? palette.primary : Color.clear, lineWidth: 2
                                ))
                                .scaleEffect(memberEmoji == e ? 1.05 : 1)
                        }
                        .buttonStyle(.plain)
                        .animation(Motion.playful, value: memberEmoji)
                    }
                }
                .padding(.horizontal, 2)
            }

            pickerLabel("Color")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(Palette.swatches, id: \.self) { hex in
                        Button {
                            Haptics.selection()
                            withAnimation(Motion.responsive) { memberTint = hex }
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)
                                .overlay(Circle().strokeBorder(
                                    Color.white, lineWidth: memberTint == hex ? 3 : 0
                                ))
                                .shadow(color: Color(hex: hex).opacity(0.25),
                                        radius: memberTint == hex ? 6 : 0)
                                .scaleEffect(memberTint == hex ? 1.18 : 1)
                        }
                        .buttonStyle(.plain)
                        .animation(Motion.playful, value: memberTint)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inviteScene: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(Copy.Onboarding.invitePrompt)
                .font(f)
                .foregroundStyle(palette.ink)

            VStack(spacing: Spacing.md) {
                choiceTile(
                    isSelected: inviteChoice == .share,
                    title: Copy.Onboarding.inviteShareCode,
                    icon: "paperplane.fill"
                ) {
                    Haptics.selection()
                    withAnimation(Motion.responsive) { inviteChoice = .share }
                }
                choiceTile(
                    isSelected: inviteChoice == .skip,
                    title: Copy.Onboarding.inviteSkip,
                    icon: "person.fill"
                ) {
                    Haptics.selection()
                    withAnimation(Motion.responsive) { inviteChoice = .skip }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var startersScene: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(Copy.Onboarding.startersPrompt)
                .font(f)
                .foregroundStyle(palette.ink)

            VStack(spacing: Spacing.md) {
                choiceTile(
                    isSelected: useStarters,
                    title: Copy.Onboarding.startersContinue,
                    icon: "sparkles"
                ) {
                    Haptics.selection()
                    withAnimation(Motion.responsive) { useStarters = true }
                }
                choiceTile(
                    isSelected: !useStarters,
                    title: Copy.Onboarding.startersSkip,
                    icon: "tray"
                ) {
                    Haptics.selection()
                    withAnimation(Motion.responsive) { useStarters = false }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var doneScene: some View {
        Text(Copy.Onboarding.doneTitle)
            .font(f)
            .foregroundStyle(palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Shared components

    private func pickerLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(palette.inkSoft)
            .tracking(1.2)
    }

    private func choiceTile(isSelected: Bool, title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : palette.primary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(isSelected ? palette.primary : palette.tintedNeutral))
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(palette.ink)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(palette.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous).fill(palette.surface))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(isSelected ? palette.primary : palette.ink.opacity(0.08),
                                  lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? palette.primary : palette.ink.opacity(0.18))
                    .frame(width: s == step ? 24 : 8, height: 8)
                    .animation(Motion.standard, value: step)
            }
            Spacer(minLength: 0)
        }
    }

    private var footerCTA: some View {
        HStack(spacing: Spacing.md) {
            if step != .welcome && step != .done {
                Button {
                    Haptics.tap()
                    withAnimation(Motion.standard) {
                        step = Step(rawValue: step.rawValue - 1) ?? .welcome
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(palette.ink)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(palette.surface))
                        .overlay(Circle().strokeBorder(palette.ink.opacity(0.1), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            Button { advance() } label: {
                HStack(spacing: Spacing.sm) {
                    Text(ctaTitle)
                        .font(.headline.weight(.bold))
                    Image(systemName: ctaIcon)
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                        .fill(palette.primary)
                )
                .shadow(color: palette.glow.opacity(0.25), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.5)
            .sensoryFeedback(.success, trigger: step == .done)
        }
    }

    private var ctaTitle: String {
        switch step {
        case .welcome:  return Copy.Onboarding.welcomeStart
        case .home:     return Copy.Onboarding.homeContinue
        case .you:      return Copy.Onboarding.youContinue
        case .invite:   return Copy.Common.done
        case .starters: return "Let's go"
        case .done:     return Copy.Onboarding.doneCTA
        }
    }

    private var ctaIcon: String {
        step == .done ? "sparkles" : "arrow.right"
    }

    private var canAdvance: Bool {
        switch step {
        case .welcome:  return true
        case .home:     return !householdName.trimmed.isEmpty
        case .you:      return !memberName.trimmed.isEmpty
        case .invite:   return inviteChoice != nil
        case .starters: return true
        case .done:     return true
        }
    }

    // MARK: - Flow

    private func advance() {
        Haptics.tap(.medium)
        switch step {
        case .welcome:  withAnimation(Motion.standard) { step = .home }
        case .home:     withAnimation(Motion.standard) { step = .you }
        case .you:      withAnimation(Motion.standard) { step = .invite }
        case .invite:   withAnimation(Motion.standard) { step = .starters }
        case .starters: withAnimation(Motion.standard) { step = .done }
        case .done:     commitOnboarding()
        }
    }

    private func commitOnboarding() {
        let me = Member(
            name: memberName.trimmed,
            emoji: memberEmoji,
            tintHex: memberTint,
            isAdmin: true
        )
        store.bootstrap(householdName: householdName.trimmed, firstMember: me)
        if useStarters { store.seedStarterJobs() }
        Haptics.success()
    }

    private func cyclePlaceholders() {
        Task {
            while step == .home {
                try? await Task.sleep(for: .seconds(1.8))
                guard step == .home else { break }
                withAnimation(.smooth(duration: 0.5)) {
                    placeholderIndex = (placeholderIndex + 1) % homePlaceholders.count
                }
            }
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
