import SwiftUI

/// Sky blue "Invite the crew" card — only visible when `members.count == 1`.
/// Primary button opens a simple "here's your code" sheet.
struct InviteCrewCard: View {
    let onTap: () -> Void

    private let palette: CardPalette = .sky

    var body: some View {
        HubCard(palette: palette, minHeight: 160) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HubTapArea(action: onTap) {
                    HStack(alignment: .top, spacing: Spacing.lg) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HubKicker(text: "ADD PEOPLE", palette: palette, symbol: "person.2.wave.2.fill")
                            HubTitle(text: Copy.Hub.inviteTitle, palette: palette)
                            HubSubtitle(text: Copy.Hub.inviteSubtitle, palette: palette)
                        }
                        Spacer(minLength: 0)
                        avatarStack
                    }
                }

                HubPrimaryButton(
                    title: Copy.Hub.invitePrimary,
                    systemImage: "qrcode",
                    palette: palette,
                    action: onTap
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Copy.Hub.inviteTitle). \(Copy.Hub.inviteSubtitle)")
    }

    private var avatarStack: some View {
        ZStack {
            Circle()
                .fill(palette.tintedNeutral)
                .frame(width: 46, height: 46)
                .overlay(Circle().strokeBorder(palette.primary.opacity(0.3), lineWidth: 1))
                .offset(x: -14, y: 6)
            Circle()
                .fill(palette.tintedNeutral)
                .frame(width: 52, height: 52)
                .overlay(Circle().strokeBorder(palette.primary.opacity(0.5), lineWidth: 1))
                .offset(x: 14, y: -6)
            Image(systemName: "plus")
                .font(.headline.weight(.heavy))
                .foregroundStyle(palette.primary)
        }
        .frame(width: 80, height: 70)
    }
}

// MARK: - Invite code sheet

/// Simple "here's your code" sheet — placeholder for real invite flow.
struct InviteCodeSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let palette: CardPalette = .sky

    private var code: String {
        // MVP: deterministic code derived from household id, 6 chars, base32-ish.
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let bytes = withUnsafeBytes(of: store.household.id.uuid) { Data($0) }
        var out: [Character] = []
        for i in 0..<6 {
            let b = Int(bytes[i % bytes.count])
            out.append(alphabet[b % alphabet.count])
        }
        return String(out)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                Spacer()
                VStack(spacing: Spacing.md) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 72))
                        .foregroundStyle(palette.primary)
                    Text(code)
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .tracking(6)
                        .foregroundStyle(palette.ink)
                }
                Text("Share this with a housemate. They tap \"\(Copy.Onboarding.welcomeJoin)\" on their device.")
                    .font(.subheadline)
                    .foregroundStyle(palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                Spacer()
                HubPrimaryButton(title: Copy.Common.done, palette: palette) { dismiss() }
                    .padding(.horizontal, Spacing.lg)
            }
            .padding(.vertical, Spacing.huge)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.surface.opacity(0.35).ignoresSafeArea())
            .navigationTitle(Copy.Hub.inviteTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Copy.Common.done) { dismiss() }
                }
            }
        }
    }
}
