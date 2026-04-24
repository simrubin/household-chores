import SwiftUI

// MARK: - Avatar

struct AvatarView: View {
    let emoji: String
    let tint: Color
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.gradient.opacity(0.92))
            Text(emoji)
                .font(.system(size: size * 0.55))
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().strokeBorder(.white.opacity(0.35), lineWidth: 0.75)
        )
        .shadow(color: tint.opacity(0.35), radius: 4, y: 2)
        .accessibilityHidden(true)
    }
}

// MARK: - Effort badge

struct EffortBadge: View {
    let effort: EffortLevel
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: effort.symbolName)
                .imageScale(.small)
            if !compact {
                Text(effort.label)
                    .font(.caption.weight(.semibold))
            }
            Text("\(effort.points)")
                .font(.caption2.weight(.bold).monospacedDigit())
                .padding(.horizontal, 5)
                .padding(.vertical, 1.5)
                .background(effort.tint.opacity(0.22), in: Capsule())
        }
        .foregroundStyle(effort.tint)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs + 1)
        .background(effort.tint.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(effort.tint.opacity(0.22), lineWidth: 0.5))
        .accessibilityLabel("\(effort.label), \(effort.points) points")
    }
}

// MARK: - Animated numeric pill

struct PointsPill: View {
    let points: Int
    var tint: Color = .accentColor

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .imageScale(.small)
            Text("\(points)")
                .contentTransition(.numericText(value: Double(points)))
                .font(.subheadline.weight(.bold).monospacedDigit())
        }
        .foregroundStyle(tint)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 6)
        .glassEffect(.regular.tint(tint.opacity(0.18)), in: Capsule())
        .animation(Motion.standard, value: points)
        .accessibilityLabel("\(points) points")
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.title3.weight(.bold))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }
}

// MARK: - Press effect (micro-interaction)

/// Scales content down slightly while pressed — the classic tactile feedback rule.
struct PressableScale: ViewModifier {
    @State private var isPressed = false
    var scale: CGFloat = 0.97

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(Motion.responsive, value: isPressed)
            .onLongPressGesture(minimumDuration: 0.01, maximumDistance: 40, perform: {}, onPressingChanged: { pressing in
                isPressed = pressing
            })
    }
}

extension View {
    func pressable(scale: CGFloat = 0.97) -> some View {
        modifier(PressableScale(scale: scale))
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var tint: Color = .accentColor
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @State private var breathe = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(tint.gradient)
                .symbolEffect(.pulse.wholeSymbol, options: .repeat(.continuous))
                .scaleEffect(breathe ? 1.06 : 1.0)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: breathe)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.xl)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xl)
        .onAppear { breathe = true }
    }
}
