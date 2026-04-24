import SwiftUI

/// Payload passed to the overlay on completion.
struct CompletionPayload: Equatable {
    let title: String
    let karmaDelta: Int
    let verdict: String
    let tint: Color
}

/// Full-screen celebratory overlay. Three phases:
/// 0.0–0.2s rise + chore title scale, tick morphs into a seal.
/// 0.2–0.8s +N karma count-up with numericText, confetti.
/// 0.6–1.0s one-line social verdict card slides in.
/// 1.2s auto-dismiss with downward fade.
/// Respects `accessibilityReduceMotion` with a crossfade-only fallback.
struct CompletionMoment: View {
    let payload: CompletionPayload
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Phase = .start
    @State private var dismissed = false

    enum Phase: Int, CaseIterable { case start, rise, count, settle, gone }

    var body: some View {
        ZStack {
            Color.black.opacity(backdropOpacity)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture { finish() }

            VStack(spacing: Spacing.xl) {
                sealIcon
                title
                karma
                verdictCard
            }
            .opacity(dismissed ? 0 : 1)
            .offset(y: dismissed ? 40 : 0)
            .animation(.easeIn(duration: 0.25), value: dismissed)
        }
        .onAppear { run() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(payload.title) done. \(Copy.Completion.karmaDelta(payload.karmaDelta)). \(payload.verdict)")
    }

    // MARK: - Phase-driven views

    private var sealIcon: some View {
        ZStack {
            Circle()
                .fill(payload.tint.gradient)
                .frame(width: 148, height: 148)
                .shadow(color: payload.tint.opacity(0.5), radius: 30, y: 10)
                .scaleEffect(phase.rawValue >= Phase.rise.rawValue ? 1 : 0.4)
                .opacity(phase.rawValue >= Phase.rise.rawValue ? 1 : 0)

            Image(systemName: phase.rawValue >= Phase.count.rawValue ? "checkmark.seal.fill" : "checkmark")
                .font(.system(size: 64, weight: .heavy))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: phase)
        }
    }

    private var title: some View {
        Text(payload.title)
            .font(.system(.title, design: .rounded, weight: .bold))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .opacity(phase.rawValue >= Phase.rise.rawValue ? 1 : 0)
            .offset(y: phase.rawValue >= Phase.rise.rawValue ? 0 : 20)
            .padding(.horizontal, Spacing.xl)
    }

    private var karma: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
            Text(Copy.Completion.karmaDelta(phase.rawValue >= Phase.count.rawValue ? payload.karmaDelta : 0))
                .contentTransition(.numericText(value: Double(payload.karmaDelta)))
        }
        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
        .foregroundStyle(.yellow)
        .shadow(color: .yellow.opacity(0.6), radius: 14, y: 2)
        .scaleEffect(phase.rawValue >= Phase.count.rawValue ? 1 : 0.5)
        .opacity(phase.rawValue >= Phase.count.rawValue ? 1 : 0)
    }

    private var verdictCard: some View {
        Text(payload.verdict)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(.white.opacity(0.15), in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
            .opacity(phase.rawValue >= Phase.settle.rawValue ? 1 : 0)
            .offset(y: phase.rawValue >= Phase.settle.rawValue ? 0 : 20)
            .padding(.horizontal, Spacing.xl)
    }

    private var backdropOpacity: Double {
        switch phase {
        case .start: return 0
        case .rise, .count, .settle: return 0.55
        case .gone: return 0
        }
    }

    // MARK: - Sequencer

    private func run() {
        if reduceMotion {
            // Simple crossfade: show everything for a moment then dismiss.
            withAnimation(.easeInOut(duration: 0.25)) { phase = .settle }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { finish() }
            return
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
            phase = .rise
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.70)) {
                phase = .count
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            withAnimation(.spring(response: 0.50, dampingFraction: 0.82)) {
                phase = .settle
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.20) {
            finish()
        }
    }

    private func finish() {
        guard !dismissed else { return }
        withAnimation(.easeIn(duration: 0.25)) { dismissed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onDone()
        }
    }
}
