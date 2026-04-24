import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if store.isOnboarded {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                OnboardingView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(Motion.hero, value: store.isOnboarded)
    }
}
