import SwiftUI

/// Three slim tabs: Home (hub), Activity (feed + upcoming), Me (profile, library, settings).
/// The "Jobs" concept has been renamed to "Chore library" and demoted under Me.
/// The old "Upcoming" moved into Activity.
struct MainTabView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedTab: AppTab = .home

    enum AppTab: Hashable { case home, activity, me }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(Copy.Tab.home, systemImage: "house.fill", value: AppTab.home) {
                HomeHubView()
            }

            Tab(Copy.Tab.activity, systemImage: "waveform.path.ecg", value: AppTab.activity) {
                ActivityView()
            }

            Tab(Copy.Tab.me, systemImage: "person.crop.circle.fill", value: AppTab.me) {
                MeView()
            }
        }
        .tint(Color.ink)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}
