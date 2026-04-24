import SwiftUI

/// Color-drenched, one-question-per-screen onboarding in Beem's voice.
/// Full-bleed scene per step, a generous hero, a single decision zone, and
/// one obvious CTA. Steps: welcome → name the home → who are you → invite
/// (optional) → starter kit (optional) → done.
struct OnboardingView: View {
    @Environment(AppStore.self) private var store

    @State private var step: Step = .welcome

    // Draft state
    @State private var householdName: String = ""
    @State private var memberName: String = ""
    @State private var memberEmoji: String = "🦊"
    @State private var memberTint: String = Palette.swatches[4]
    @State private var inviteChoice: InviteChoice? = nil
    @State private var useStarters: Bool = true

    // Animation state
    @State private var animateHero = false
    @State private var placeholderIndex = 0

    private enum Step: Int, CaseIterable {
        case welcome, home, you, invite, starters, done
    }

    private let palette: CardPalette = .petal

    private enum InviteChoice { case share, skip }

    private let emojis = ["🦊", "🐻", "🐼", "🦁", "🐨", "🐸", "🐙", "🐯", "🦉", "🐶", "🐱", "🐰"]
    private let homePlaceholders = ["The Burrow", "Apt 3B", "Flat 2", "Number 12", "Chez nous"]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                background
                    .ignoresSafeArea()

                sceneBody
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            }
        }
        .onAppear { animateHero = true }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            palette.surfaceGradient
            // Soft color bleed blob for the hero.
            Circle()
                .fill(palette.glow.opacity(0.35))
                .frame(width: 520, height: 520)
                .blur(radius: 80)
                .offset(x: -120, y: -260)
                .opacity(animateHero ? 1 : 0)
                .animation(.smooth(duration: 1.2), value: animateHero)
        }
    }

    // MARK: - Scene body

    @ViewBuilder
    private var sceneBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            progressDots
                .padding(.top, Spacing.lg)

            Spacer(minLength: Spacing.lg)

            content

            Spacer(minLength: Spacing.lg)

            footerCTA
                .padding(.bottom, Spacing.xl)
        }
        .padding(.horizontal, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome: welcomeScene
        case .home: homeScene
        case .you: youScene
        case .invite: inviteScene
        case .starters: startersScene
        case .done: doneScene
        }
    }

    // MARK: - Scenes

    private var welcomeScene: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(Copy.Onboarding.welcomeKicker.uppercased())
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(palette.ink.opacity(0.6))

            Text(Copy.Onboarding.welcomeTitle)
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.7)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                welcomeBullet(Copy.Onboarding.welcomeBullet1, icon: "scalemass.fill")
                welcomeBullet(Copy.Onboarding.welcomeBullet2, icon: "bell.fill")
                welcomeBullet(Copy.Onboarding.welcomeBullet3, icon: "wand.and.stars")
            }
            .padding(.top, Spacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func welcomeBullet(_ text: String, icon: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(palette.primary)
                .frame(width: 32)
            Text(text)
                .font(.title3.weight(.semibold))
                .foregroundStyle(palette.ink)
            Spacer(minLength: 0)
        }
    }

    private var homeScene: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sceneHeader(
                title: Copy.Onboarding.homeTitle,
                subtitle: Copy.Onboarding.homeSubtitle
            )

            bigTextField(
                text: $householdName,
                placeholder: homePlaceholders[placeholderIndex],
                autocapitalize: .words
            )
            .onAppear { cyclePlaceholders() }

            Text(Copy.Onboarding.homeHint)
                .font(.footnote)
                .foregroundStyle(palette.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var youScene: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sceneHeader(
                title: Copy.Onboarding.youTitle,
                subtitle: Copy.Onboarding.youSubtitle
            )

            HStack(alignment: .center, spacing: Spacing.md) {
                AvatarView(emoji: memberEmoji, tint: Color(hex: memberTint), size: 64)
                    .shadow(color: palette.glow.opacity(0.45), radius: 14)

                bigTextField(
                    text: $memberName,
                    placeholder: Copy.Onboarding.youPlaceholder,
                    autocapitalize: .words
                )
            }

            Text("Avatar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.inkSoft)
                .textCase(.uppercase)
                .tracking(1.2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(emojis, id: \.self) { e in
                        Button {
                            Haptics.selection()
                            withAnimation(Motion.responsive) { memberEmoji = e }
                        } label: {
                            Text(e)
                                .font(.system(size: 28))
                                .frame(width: 52, height: 52)
                                .background(
                                    Circle()
                                        .fill(memberEmoji == e ? palette.primary.opacity(0.28) : palette.tintedNeutral)
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(memberEmoji == e ? palette.primary : Color.clear, lineWidth: 2.5)
                                )
                                .scaleEffect(memberEmoji == e ? 1.05 : 1)
                        }
                        .buttonStyle(.plain)
                        .animation(Motion.playful, value: memberEmoji)
                    }
                }
                .padding(.horizontal, 2)
            }

            Text("Color")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.inkSoft)
                .textCase(.uppercase)
                .tracking(1.2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(Palette.swatches, id: \.self) { hex in
                        Button {
                            Haptics.selection()
                            withAnimation(Motion.responsive) { memberTint = hex }
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: memberTint == hex ? 3 : 0)
                                )
                                .shadow(color: Color(hex: hex).opacity(0.6), radius: memberTint == hex ? 10 : 0)
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
            sceneHeader(
                title: Copy.Onboarding.inviteTitle,
                subtitle: Copy.Onboarding.inviteSubtitle
            )

            VStack(spacing: Spacing.md) {
                inviteChoiceTile(
                    .share,
                    title: Copy.Onboarding.inviteShareCode,
                    subtitle: "We'll make a 6-digit code.",
                    icon: "paperplane.fill"
                )
                inviteChoiceTile(
                    .skip,
                    title: Copy.Onboarding.inviteSkip,
                    subtitle: "You can always add people later.",
                    icon: "person.fill"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func inviteChoiceTile(_ choice: InviteChoice, title: String, subtitle: String, icon: String) -> some View {
        let selected = inviteChoice == choice
        return Button {
            Haptics.selection()
            withAnimation(Motion.responsive) { inviteChoice = choice }
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(selected ? .white : palette.primary)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(selected ? palette.primary : palette.tintedNeutral)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(palette.ink)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.inkSoft)
                }
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(palette.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(selected ? palette.primary : palette.ink.opacity(0.08),
                                  lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var startersScene: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            sceneHeader(
                title: Copy.Onboarding.startersTitle,
                subtitle: Copy.Onboarding.startersSubtitle
            )

            VStack(spacing: Spacing.md) {
                starterChoiceTile(
                    isSelected: useStarters,
                    title: Copy.Onboarding.startersContinue,
                    subtitle: "Dishwasher, bin night, a weekly tidy.",
                    icon: "sparkles"
                ) {
                    Haptics.selection()
                    withAnimation(Motion.responsive) { useStarters = true }
                }
                starterChoiceTile(
                    isSelected: !useStarters,
                    title: Copy.Onboarding.startersSkip,
                    subtitle: "Start with nothing, add your own.",
                    icon: "tray"
                ) {
                    Haptics.selection()
                    withAnimation(Motion.responsive) { useStarters = false }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func starterChoiceTile(isSelected: Bool, title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : palette.primary)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(isSelected ? palette.primary : palette.tintedNeutral)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(palette.ink)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.inkSoft)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(palette.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(isSelected ? palette.primary : palette.ink.opacity(0.08),
                                  lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var doneScene: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Image(systemName: "house.lodge.fill")
                .font(.system(size: 88, weight: .bold))
                .foregroundStyle(palette.primary)
                .symbolEffect(.bounce, value: animateHero)
                .shadow(color: palette.glow.opacity(0.5), radius: 24)

            Text(Copy.Onboarding.doneTitle)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(palette.ink)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(Copy.Onboarding.doneSubtitle)
                .font(.title3.weight(.medium))
                .foregroundStyle(palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Shared building blocks

    private func sceneHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(palette.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.title3)
                .foregroundStyle(palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bigTextField(
        text: Binding<String>,
        placeholder: String,
        autocapitalize: TextInputAutocapitalization
    ) -> some View {
        TextField(placeholder, text: text)
            .font(.title2.weight(.semibold))
            .textInputAutocapitalization(autocapitalize)
            .textFieldStyle(.plain)
            .padding(.vertical, Spacing.md)
            .padding(.horizontal, Spacing.md)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .strokeBorder(palette.ink.opacity(0.1), lineWidth: 1)
            )
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
                        .background(
                            Circle().fill(palette.surface)
                        )
                        .overlay(
                            Circle().strokeBorder(palette.ink.opacity(0.1), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            Button {
                advance()
            } label: {
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
                .shadow(color: palette.glow.opacity(0.5), radius: 14, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.5)
            .sensoryFeedback(.success, trigger: step == .done)
        }
    }

    private var ctaTitle: String {
        switch step {
        case .welcome: return Copy.Onboarding.welcomeStart
        case .home: return Copy.Onboarding.homeContinue
        case .you: return Copy.Onboarding.youContinue
        case .invite: return Copy.Common.done
        case .starters: return "Let's go"
        case .done: return Copy.Onboarding.doneCTA
        }
    }

    private var ctaIcon: String {
        switch step {
        case .done: return "sparkles"
        default: return "arrow.right"
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .welcome: return true
        case .home: return !householdName.trimmed.isEmpty
        case .you: return !memberName.trimmed.isEmpty
        case .invite: return inviteChoice != nil
        case .starters: return true
        case .done: return true
        }
    }

    // MARK: - Flow

    private func advance() {
        Haptics.tap(.medium)
        switch step {
        case .welcome:
            withAnimation(Motion.standard) { step = .home }
        case .home:
            withAnimation(Motion.standard) { step = .you }
        case .you:
            withAnimation(Motion.standard) { step = .invite }
        case .invite:
            withAnimation(Motion.standard) { step = .starters }
        case .starters:
            withAnimation(Motion.standard) { step = .done }
        case .done:
            commitOnboarding()
        }
    }

    /// Commit everything in one go so `RootView` only flips after the user
    /// has seen every step of the flow.
    private func commitOnboarding() {
        let me = Member(
            name: memberName.trimmed,
            emoji: memberEmoji,
            tintHex: memberTint,
            isAdmin: true
        )
        store.bootstrap(householdName: householdName.trimmed, firstMember: me)
        if useStarters {
            store.seedStarterJobs()
        }
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
